# StorageManager

A storage management framework for EVE Frontier that enables fine-grained inventory allocation within Smart Storage Units (SSUs). The system provides bucketed storage functionality, allowing multiple systems to safely share and manage inventory within the same storage unit without conflicts.

## What It Does

This comes with the added benefit of lower gas fees when transferring items between buckets, since they don't need to route through the heavier world-chain-contracts inventory contracts stack (usage capacity, access control, inventory ownership checks, item entity record checks, etc) - since they're just internal allocation to the primary inventory (think of this like moving an item from one slot on a rack in a warehouse to a different slot).

### Core Functionality

Read more about the design in [INTERACTION_PATTERNS.md](https://github.com/Algorithmic-Warfare/storage-manager/blob/main/INTERACTION_PATTERNS.md)

- **Bucketed Storage**: Subdivides primary inventory into named "buckets" that can be allocated to different systems or purposes
- **Inventory Allocation Tracking**: Maintains separate accounting of how primary inventory is allocated across different buckets
- **Multi-System Safety**: Allows multiple systems to safely interact with the same SSU without asset conflicts
- **Flexible Transfer Operations**: Supports transfers between buckets, primary inventory, and ephemeral inventory
- **Permission Management**: Granular access control for deposit/withdraw operations on individual buckets

### Key Systems

#### StorageSystem
The core system that wraps EVE Frontier's native inventory functions with bucket-aware operations:
- `deposit()` - Move items from ephemeral or primary inventory into buckets
- `withdraw()` - Move items from buckets to ephemeral or primary inventory  
- `internalTransfer()` - Move items between buckets (gas-efficient, no actual item movement)
- `transferToPlayer()` - Move items from buckets to a player.

#### BucketSystem
Manages the creation and organization of storage buckets:
- `createNestedBuckets()` - Create hierarchical bucket structures using `/` separator (e.g., "marketplace/orders/pending")
- `transferBucketToParent()` - Reorganize bucket hierarchies
- Supports nested bucket structures with parent-child relationships

#### StoreAuthSystem
Handles permission management and access control:
- `canDeposit()` - Check if an address can deposit to a bucket
- `canWithdraw()` - Check if an address can withdraw from a bucket
- `setAccessSystemId()` - Configure custom authorization systems for buckets
- Tribal access control (same tribe members can access each other's buckets by default)

#### StoreProxySystem
Immutable proxy that wraps world-chain inventory operations:
- `proxyTransferFromEphemeral()` - Safe ephemeral to primary transfers
- `proxyTransferToEphemeral()` - Safe primary to ephemeral transfers
- Enables system upgrades without breaking existing permissions

#### StoreLogicSystem
Internal logic for bucket operations:
- `_processDeposit()` - Handle item additions to buckets
- `_processWithdraw()` - Handle item removals from buckets
- `_processAggBucketsBalance()` - Update aggregate balance tracking

#### SmUtilsSystem
Utility functions for bucket and inventory management:
- `deriveBucketId()` - Generate unique bucket identifiers
- `getBucketInventoryItems()` - Retrieve items in a specific bucket
- `getBucketsMetadata()` - Get metadata for multiple buckets
- `getBatchCanDeposit()` / `getBatchCanWithdraw()` - Batch permission checks
- `getOwnerBalance()` - Calculate unallocated owner inventory

#### AccessUtilsSystem
Additional access control utilities:
- `hasRoles()` - Check if accounts have specific roles
- `getOwnersOf()` - Get owners of smart objects
- Integration with EVE Frontier's role-based access system

### Constraints
but it suffers from a problem in that the owner always has access to the items managed by the third party System. This can inadvertently break the accounting of any services built on top of the SSU that requires management of items - like tribe warehousing, item marketplaces, etc - since the owner can just "take" the item away from the system without it's code updating the accounting.

If:
- We could transfer the ownership of the SSU (to the System or to a burn address like 0x0000...0000). Or,
- The owner of the SSU functioned exactly the same as non-owner players (where their owner's default inventory is the ephemeral inventory). Or,
- There was a specific inventory space intended to be "owned" by 3rd party MUD systems.
Then this problem would be alleviated.

## Technology Stack

- **Smart Contracts**: Solidity + Foundry + MUD v2
- **Blockchain**: EVE Frontier (EVM-compatible)
- **Tooling**: pnpm workspaces, mprocs, ESLint, Prettier
- **Testing**: Forge + MUD testing framework

## Project Structure

```
packages/
├── contracts/           # Smart contract system
│   ├── src/
│   │   ├── systems/
│   │   │   ├── StorageSystem/      # Main bucket storage logic
│   │   │   │   ├── StorageSystem.sol       # Core deposit/withdraw/transfer
│   │   │   │   ├── BucketSystem.sol        # Bucket creation and management
│   │   │   │   ├── StoreAuthSystem.sol     # Permission management
│   │   │   │   └── StoreLogicSystem.sol    # Internal bucket operations
│   │   │   ├── StoreProxySystem/   # Immutable proxy wrapper
│   │   │   ├── SmUtilsSystem.sol   # Storage utilities and helpers
│   │   │   └── AccessUtilsSystem.sol # Additional access controls
│   │   ├── codegen/               # MUD-generated code
│   │   └── tables/                # Storage schema definitions
│   ├── test/                      # Contract tests
│   └── script/                    # Deployment scripts
└── eveworld/                      # Local development environment
    └── docker-compose.yaml        # EVE Frontier world node
```

### Key Tables

| Table | Purpose |
|-------|---------|
| `BucketedInventoryItem` | Tracks item quantities within specific buckets |
| `BucketMetadata` | Stores bucket names, owners, and parent relationships |
| `BucketConfig` | Maps buckets to their authorization systems |
| `BucketInventory` | Maps buckets to their contained items |
| `BucketOwners` | Tracks which buckets belong to each owner |
| `InventoryBalances` | Tracks total allocated quantities per item across all buckets |

## Getting Started

### Prerequisites
- Linux or WSL (recommended)
- Node.js v18+
- pnpm >= 9.15.0
- Foundry
- Docker

### Environment Setup (Manual)

Follow the official EVE Frontier documentation:
- [Setting up tools](https://docs.evefrontier.com/Tools)
- [Setting up the world](https://docs.evefrontier.com/LocalWorldSetup)

### Installation

```bash
pnpm install
```

### Development Workflow

#### Quick Start Commands (run within project root)
```bash
# Start EVE Frontier world node @ http://localhost:8586
pnpm world:up 

# Start integrated development environment with:
# - Forked world node @ http://localhost:8584
# - Contract deployment in watch mode
# - Automated contract testing (press "R" to rerun after deployment)
pnpm dev
```

#### Individual Commands
```bash
# Build all packages
pnpm build

# Run contract tests
pnpm --filter contracts test

# Deploy contracts to local world
pnpm --filter contracts deploy:local

# Clean all build artifacts
pnpm clean
```

## Usage Examples

### Basic Bucket Operations

```solidity
// Create a bucket for a marketplace system
bytes32 marketplaceBucket = storageSystem.createBucket(ssuId, "marketplace");

// Deposit items from ephemeral inventory to bucket
InventoryItemParams[] memory items = new InventoryItemParams[](1);
items[0] = InventoryItemParams({smartObjectId: itemId, quantity: 100});
storageSystem.deposit(ssuId, marketplaceBucket, false, items); // false = from ephemeral

// Transfer between buckets (gas efficient)
bytes32 tradingBucket = storageSystem.createBucket(ssuId, "trading");
storageSystem.internalTransfer(ssuId, marketplaceBucket, tradingBucket, items);

// Withdraw to ephemeral inventory
storageSystem.withdraw(ssuId, tradingBucket, false, items); // false = to ephemeral
```

### Permission Management

```solidity
// Set deposit permissions for a bucket
storeAuthSystem.setAccessSystemId(ssuId, bucketId, yourSystemAddress);

// Your system must implement canDeposit/canWithdraw functions
function canDeposit(uint256 smartObjectId, bytes32 bucketId, address depositor) 
    external view returns (bool) {
    // Custom authorization logic
    return authorized[depositor];
}
```

## Interaction Patterns

The system supports three types of inventory interactions:

1. **Primary Inventory ↔ Bucket**: Allocation changes within primary inventory (gas efficient)
2. **Ephemeral ↔ Bucket**: Actual item transfers with world-chain permission checks
3. **Bucket ↔ Bucket**: Internal reallocation (gas efficient, no actual movement)

See [INTERACTION_PATTERNS.md](./INTERACTION_PATTERNS.md) for detailed interaction flows and permission requirements.

## Testing

```bash
# Run all contract tests
pnpm --filter contracts test

# Run specific test file
forge test --match-contract StorageManagerTest

# Run with gas reporting
forge test --gas-report
```

## Architecture Benefits

- **Gas Efficiency**: Bucket-to-bucket transfers don't move items, just update allocation
- **System Isolation**: Multiple systems can safely use the same SSU without conflicts
- **Upgradeability**: Core logic can be upgraded through the proxy pattern
- **Permission Granularity**: Fine-grained control over who can deposit/withdraw from specific buckets
- **Inventory Transparency**: Clear separation between allocated and available inventory

## License

[MIT](./LICENSE)
