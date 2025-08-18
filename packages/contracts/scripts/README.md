# StorageManager Install Script

This directory contains an installation script for deploying the complete StorageManager system to any existing MUD world for local testing and development.

## Overview

The `InstallStorageManager.s.sol` script provides a one-command installation of the entire StorageManager system, including:

- **7 Systems**: StorageSystem, BucketSystem, StoreAuthSystem, StoreProxySystem, StoreLogicSystem, SmUtilsSystem, AccessUtilsSystem
- **6 Tables**: BucketedInventoryItem, BucketMetadata, BucketConfig, InventoryBalances, BucketOwners, BucketInventory
- Proper namespace isolation (`sm_v0_2_0`)
- Verification and next-steps guidance

## Prerequisites

- Foundry installed
- Access to a running MUD world (local or testnet)
- Required environment variables configured

## Installation

### 1. Environment Setup

Create a `.env` file in your target MUD project with:

```bash
# Target MUD World Configuration
WORLD_ADDRESS=0x... # Address of the MUD World to install into
PRIVATE_KEY=0x...   # Deployer private key (must have deployment permissions)
RPC_URL=http://127.0.0.1:8545  # RPC endpoint for the target chain
CHAIN_ID=31337      # Chain ID (31337 for local anvil)

# Optional: Smart Storage Unit configuration
SSU_ID=123456       # ID of SSU to configure (for post-install setup)
```

### 2. Copy Required Files

Copy the following files from this StorageManager package to your target MUD project:

```bash
# Copy the install script
cp scripts/InstallStorageManager.s.sol /path/to/your/mud/project/script/

# Copy the complete src directory (systems + tables)
cp -r src/ /path/to/your/mud/project/src/storage-manager/

# Copy configuration script for post-install setup
cp scripts/ConfigureSSU.s.sol /path/to/your/mud/project/script/
```

### 3. Update Dependencies

Add the required dependencies to your target project's `package.json`:

```json
{
  "dependencies": {
    "@eveworld/common-constants": "latest",
    "@eveworld/smart-object-framework-v2": "latest",
    "@eveworld/world-v2": "latest",
    "@latticexyz/cli": "2.2.15-main-ba5191c3d6f74b3c4982afd465cf449d23d70bb7",
    "@latticexyz/store": "2.2.15-main-ba5191c3d6f74b3c4982afd465cf449d23d70bb7",
    "@latticexyz/world": "2.2.15-main-ba5191c3d6f74b3c4982afd465cf449d23d70bb7"
  }
}
```

### 4. Run Installation

Execute the installation script:

```bash
# Navigate to your target MUD project
cd /path/to/your/mud/project

# Run the installation
forge script script/InstallStorageManager.s.sol:InstallStorageManager \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

## Post-Installation Setup

### 1. Configure SSU Permissions (Required)

After installation, you must configure permissions for the StoreProxySystem to interact with Smart Storage Units:

```bash
forge script script/ConfigureSSU.s.sol:ConfigureSSU \
  --rpc-url $RPC_URL \
  --broadcast \
  --sig "run()" \
  -vvvv
```

This grants the necessary roles:
- `TRANSFER_FROM_EPHEMERAL_ROLE`
- `TRANSFER_TO_EPHEMERAL_ROLE` 
- `CROSS_TRANSFER_TO_EPHEMERAL_ROLE`
- `TRANSFER_TO_INVENTORY_ROLE`

### 2. Integration in Your Code

Import and use the StorageManager in your systems:

```solidity
// In your system contracts
import { storageSystem } from "./storage-manager/codegen/systems/StorageSystemLib.sol";

contract YourSystem is System {
  function createBucket(uint256 ssuId, string memory bucketName) public {
    bytes32[] memory bucketIds = storageSystem.createNestedBuckets(ssuId, bucketName);
    // Use the created bucket...
  }
  
  function depositItems(uint256 ssuId, bytes32 bucketId, InventoryItemParams[] memory items) public {
    storageSystem.deposit(ssuId, bucketId, true, items);
  }
}
```

### 3. Client-Side Integration

If using the MUD client, you can call the systems directly:

```typescript
// Get the world contract
const worldContract = getContract({
  address: worldAddress,
  abi: IWorld.abi,
  client: publicClient,
});

// Create a bucket
const bucketIds = await worldContract.write.sm_v0_2_0__createNestedBuckets([
  ssuId,
  "my-test-bucket"
]);

// Deposit items
await worldContract.write.sm_v0_2_0__deposit([
  ssuId,
  bucketIds[0],
  true, // transferFromEphemeral
  items
]);
```

## Available Functions

Once installed, the following functions are available in the `sm_v0_2_0` namespace:

### Core Storage Operations
- `createNestedBuckets(smartObjectId, bucketName)` - Create hierarchical buckets
- `deposit(smartObjectId, bucketId, transferFromEphemeral, items)` - Deposit items into bucket
- `withdraw(smartObjectId, bucketId, transferToEphemeral, items)` - Withdraw items from bucket
- `internalTransfer(smartObjectId, fromBucket, toBucket, items)` - Transfer between buckets

### Utility Functions
- `getBucketsMetadata(smartObjectId, bucketIds)` - Get bucket information
- `getSystemAddress()` - Get StorageSystem address
- `getStoreProxyAddress()` - Get StoreProxySystem address
- `deriveBucketId(smartObjectId, bucketName)` - Calculate bucket ID

### Access Control
- `setAccessSystemId(smartObjectId, bucketId, systemId)` - Set custom access control
- `hasRoles(roleIds, account)` - Check permissions

## Testing

### Local Testing Setup

1. **Start local anvil node**:
```bash
anvil --base-fee 0 --block-time 2
```

2. **Deploy a test MUD world** (if you don't have one):
```bash
# In a basic MUD project
pnpm mud deploy --profile=local
```

3. **Install StorageManager**:
```bash
# Set environment variables
export WORLD_ADDRESS=$(cat worlds.json | jq -r '.31337.address')
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export RPC_URL=http://127.0.0.1:8545
export CHAIN_ID=31337

# Run installation
forge script script/InstallStorageManager.s.sol:InstallStorageManager --broadcast -vvvv
```

### Test Script Example

Create a test script to verify the installation:

```solidity
// script/TestStorageManager.s.sol
contract TestStorageManager is Script {
  function run() external {
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    IWorld world = IWorld(worldAddress);
    
    vm.startBroadcast();
    
    // Test bucket creation
    bytes32[] memory bucketIds = world.sm_v0_2_0__createNestedBuckets(
      12345, // test SSU ID
      "test-bucket"
    );
    
    console.log("Created bucket:", vm.toString(bucketIds[0]));
    
    vm.stopBroadcast();
  }
}
```

## Troubleshooting

### Common Issues

1. **"StorageSystem not registered" error**
   - Ensure the installation script completed successfully
   - Check that WORLD_ADDRESS is correct
   - Verify deployer has permissions on the target world

2. **Permission denied when calling functions**
   - Run the ConfigureSSU script to set up permissions
   - Ensure the SSU exists and you have ownership rights

3. **Table registration failures**
   - Check for namespace conflicts in the target world
   - Ensure the world has sufficient space for new tables

4. **Import path errors**
   - Verify the src files were copied to the correct location
   - Update import paths in the copied files if needed

### Debug Commands

```bash
# Check if systems are registered
cast call $WORLD_ADDRESS "getSystemAddress(bytes32)" $SYSTEM_RESOURCE_ID --rpc-url $RPC_URL

# Verify table exists
cast call $WORLD_ADDRESS "getTable(bytes32)" $TABLE_RESOURCE_ID --rpc-url $RPC_URL

# Check StoreProxy address
cast call $WORLD_ADDRESS "sm_v0_2_0__getStoreProxyAddress()" --rpc-url $RPC_URL
```

## Uninstallation

To remove the StorageManager system:

1. Remove the imported source files
2. The deployed systems will remain in the world but can be ignored
3. Tables will retain their data but can be safely unused

> **Note**: MUD doesn't provide built-in uninstallation. Systems and tables remain permanently registered in the world.

## Next Steps

After successful installation:

1. Read the [StorageManager Documentation](../README.md) for detailed usage patterns
2. Review the [Interaction Patterns](../INTERACTION_PATTERNS.md) for advanced use cases  
3. Check out the test files for comprehensive examples
4. Join the EVE Frontier developer community for support

## Contributing

Found an issue with the install script? Please report it or submit a PR to improve the installation experience for other developers.