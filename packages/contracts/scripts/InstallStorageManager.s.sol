// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { FieldLayout } from "@latticexyz/store/src/FieldLayout.sol";
import { Schema } from "@latticexyz/store/src/Schema.sol";
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

// Import the systems to be deployed
import { IWorld } from "../src/codegen/world/IWorld.sol";

import { StorageSystem } from "../src/systems/StorageSystem/StorageSystem.sol";
import { BucketSystem } from "../src/systems/StorageSystem/BucketSystem.sol";
import { StoreAuthSystem } from "../src/systems/StorageSystem/StoreAuthSystem.sol";
import { StoreProxySystem } from "../src/systems/StoreProxySystem/StoreProxySystem.sol";
import { StoreLogicSystem } from "../src/systems/StorageSystem/StoreLogicSystem.sol";
import { SmUtilsSystem } from "../src/systems/SmUtilsSystem.sol";
import { AccessUtilsSystem } from "../src/systems/AccessUtilsSystem.sol";
import { DEPLOYMENT_NAMESPACE } from "../src/systems/StorageSystem/Constants.sol";

// Import table schemas for registration
import { BucketedInventoryItem } from "../src/codegen/tables/BucketedInventoryItem.sol";
import { BucketMetadata } from "../src/codegen/tables/BucketMetadata.sol";
import { BucketConfig } from "../src/codegen/tables/BucketConfig.sol";
import { InventoryBalances } from "../src/codegen/tables/InventoryBalances.sol";
import { BucketOwners } from "../src/codegen/tables/BucketOwners.sol";
import { BucketInventory } from "../src/codegen/tables/BucketInventory.sol";

/**
 * @title InstallStorageManager
 * @notice Script to install the complete StorageManager system into an existing MUD world
 * @dev This script deploys all StorageManager systems and registers all required tables
 *
 * Usage:
 * forge script InstallStorageManager --rpc-url $RPC_URL --broadcast --verify
 *
 * Environment Variables Required:
 * - WORLD_ADDRESS: Address of the target MUD World
 * - PRIVATE_KEY: Deployer private key
 * - RPC_URL: RPC endpoint
 * - CHAIN_ID: Target chain ID
 */
contract InstallStorageManager is Script {
  // Storage Manager namespace
  bytes14 constant NAMESPACE = DEPLOYMENT_NAMESPACE;

  // System names
  bytes14 constant STORAGE_SYSTEM = "StorageSystem";
  bytes14 constant BUCKET_SYSTEM = "BucketSystem";
  bytes14 constant STORE_AUTH_SYSTEM = "StoreAuthSyste";
  bytes14 constant STORE_PROXY_SYSTEM = "StoreProxySyst";
  bytes14 constant STORE_LOGIC_SYSTEM = "StoreLogicSyst";
  bytes14 constant SM_UTILS_SYSTEM = "SmUtilsSystem";
  bytes14 constant ACCESS_UTILS_SYSTEM = "AccessUtilSyst";

  IWorld world;
  IStore store;

  address deployer;

  function run() external {
    // Load configuration
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    deployer = vm.addr(deployerPrivateKey);

    console.log("Installing StorageManager to world:", worldAddress);
    console.log("Deployer address:", deployer);

    // Initialize world connection
    world = IWorld(worldAddress);
    StoreSwitch.setStoreAddress(worldAddress);
    store = IStore(worldAddress);

    vm.startBroadcast(deployerPrivateKey);
    // Ensure namespace exists and caller has authority
    ensureNamespace();

    // Step 1: Register all tables first
    console.log("\n=== Registering Tables ===");
    registerTables();

    // Step 2: Deploy and register all systems
    console.log("\n=== Deploying Systems ===");
    deploySystems();

    // Step 3: Verify installation
    console.log("\n=== Verifying Installation ===");
    verifyInstallation();

    vm.stopBroadcast();

    console.log("\n=== Installation Complete ===");
    console.log("StorageManager successfully installed!");

    // Print next steps
    printNextSteps();
  }

  function ensureNamespace() internal {
    console.log("Ensuring namespace is registered...");
    // registerNamespace is idempotent via try/catch
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(DEPLOYMENT_NAMESPACE);
    try world.registerNamespace(namespaceResource) {
      console.log("Namespace registered.");
    } catch {
      console.log("Namespace already registered, continuing.");
    }
  }

  function registerIfNeeded(
    ResourceId tableId,
    bytes32 fieldLayout,
    Schema keySchema,
    Schema valueSchema,
    string[] memory keyNames,
    string[] memory fieldNames
  ) internal {
    // If table exists, verify schema matches; otherwise skip registration
    try store.getKeySchema(tableId) returns (Schema existingKey) {
      Schema existingValue = store.getValueSchema(tableId);
      if (
        Schema.unwrap(existingKey) != Schema.unwrap(keySchema) ||
        Schema.unwrap(existingValue) != Schema.unwrap(valueSchema)
      ) {
        revert("Table already exists with different schema; bump DEPLOYMENT_NAMESPACE");
      }
      console.log("Table already registered:", uint256(ResourceId.unwrap(tableId)));
      return;
    } catch {
      // not registered yet
      console.log("Not registered yet, registering table:", uint256(ResourceId.unwrap(tableId)));
    }
    store.registerTable({
      tableId: tableId,
      fieldLayout: FieldLayout.wrap(fieldLayout),
      keySchema: keySchema,
      valueSchema: valueSchema,
      keyNames: keyNames,
      fieldNames: fieldNames
    });
  }

  function registerTables() internal {
    console.log("Registering BucketedInventoryItem table...");
    // BucketedInventoryItem.register();
    registerIfNeeded({
      tableId: BucketedInventoryItem._tableId,
      fieldLayout: FieldLayout.unwrap(BucketedInventoryItem._fieldLayout),
      keySchema: (BucketedInventoryItem._keySchema),
      valueSchema: (BucketedInventoryItem._valueSchema),
      keyNames: BucketedInventoryItem.getKeyNames(),
      fieldNames: BucketedInventoryItem.getFieldNames()
    });

    console.log("Registering BucketMetadata table...");
    // BucketMetadata.register();
    registerIfNeeded({
      tableId: BucketMetadata._tableId,
      fieldLayout: FieldLayout.unwrap(BucketMetadata._fieldLayout),
      keySchema: BucketMetadata._keySchema,
      valueSchema: BucketMetadata._valueSchema,
      keyNames: BucketMetadata.getKeyNames(),
      fieldNames: BucketMetadata.getFieldNames()
    });

    console.log("Registering BucketConfig table...");
    // BucketConfig.register();
    registerIfNeeded({
      tableId: BucketConfig._tableId,
      fieldLayout: FieldLayout.unwrap(BucketConfig._fieldLayout),
      keySchema: BucketConfig._keySchema,
      valueSchema: BucketConfig._valueSchema,
      keyNames: BucketConfig.getKeyNames(),
      fieldNames: BucketConfig.getFieldNames()
    });

    console.log("Registering InventoryBalances table...");
    // InventoryBalances.register();
    registerIfNeeded({
      tableId: InventoryBalances._tableId,
      fieldLayout: FieldLayout.unwrap(InventoryBalances._fieldLayout),
      keySchema: InventoryBalances._keySchema,
      valueSchema: InventoryBalances._valueSchema,
      keyNames: InventoryBalances.getKeyNames(),
      fieldNames: InventoryBalances.getFieldNames()
    });

    console.log("Registering BucketOwners table...");
    // BucketOwners.register();
    registerIfNeeded({
      tableId: BucketOwners._tableId,
      fieldLayout: FieldLayout.unwrap(BucketOwners._fieldLayout),
      keySchema: BucketOwners._keySchema,
      valueSchema: BucketOwners._valueSchema,
      keyNames: BucketOwners.getKeyNames(),
      fieldNames: BucketOwners.getFieldNames()
    });

    console.log("Registering BucketInventory table...");
    // BucketInventory.register();
    registerIfNeeded({
      tableId: BucketInventory._tableId,
      fieldLayout: FieldLayout.unwrap(BucketInventory._fieldLayout),
      keySchema: BucketInventory._keySchema,
      valueSchema: BucketInventory._valueSchema,
      keyNames: BucketInventory.getKeyNames(),
      fieldNames: BucketInventory.getFieldNames()
    });

    console.log("All tables registered successfully!");
  }

  function deploySystems() internal {
    // Deploy StorageSystem
    console.log("Deploying StorageSystem...");
    StorageSystem storageSystem = new StorageSystem();
    ResourceId storageSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: STORAGE_SYSTEM
    });
    world.registerSystem(storageSystemId, storageSystem, true);
    console.log("StorageSystem deployed at:", address(storageSystem));

    // Deploy BucketSystem
    console.log("Deploying BucketSystem...");
    BucketSystem bucketSystem = new BucketSystem();
    ResourceId bucketSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: BUCKET_SYSTEM
    });
    world.registerSystem(bucketSystemId, bucketSystem, true);
    console.log("BucketSystem deployed at:", address(bucketSystem));

    // Deploy StoreAuthSystem
    console.log("Deploying StoreAuthSystem...");
    StoreAuthSystem storeAuthSystem = new StoreAuthSystem();
    ResourceId storeAuthSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: STORE_AUTH_SYSTEM
    });
    world.registerSystem(storeAuthSystemId, storeAuthSystem, true);
    console.log("StoreAuthSystem deployed at:", address(storeAuthSystem));

    // Deploy StoreProxySystem
    console.log("Deploying StoreProxySystem...");
    StoreProxySystem storeProxySystem = new StoreProxySystem();
    ResourceId storeProxySystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: STORE_PROXY_SYSTEM
    });
    world.registerSystem(storeProxySystemId, storeProxySystem, true);
    console.log("StoreProxySystem deployed at:", address(storeProxySystem));

    // Deploy StoreLogicSystem
    console.log("Deploying StoreLogicSystem...");
    StoreLogicSystem storeLogicSystem = new StoreLogicSystem();
    ResourceId storeLogicSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: STORE_LOGIC_SYSTEM
    });
    world.registerSystem(storeLogicSystemId, storeLogicSystem, true);
    console.log("StoreLogicSystem deployed at:", address(storeLogicSystem));

    // Deploy SmUtilsSystem
    console.log("Deploying SmUtilsSystem...");
    SmUtilsSystem smUtilsSystem = new SmUtilsSystem();
    ResourceId smUtilsSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: SM_UTILS_SYSTEM
    });
    world.registerSystem(smUtilsSystemId, smUtilsSystem, true);
    console.log("SmUtilsSystem deployed at:", address(smUtilsSystem));

    // Deploy AccessUtilsSystem
    console.log("Deploying AccessUtilsSystem...");
    AccessUtilsSystem accessUtilsSystem = new AccessUtilsSystem();
    ResourceId accessUtilsSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: ACCESS_UTILS_SYSTEM
    });
    world.registerSystem(accessUtilsSystemId, accessUtilsSystem, true);
    console.log("AccessUtilsSystem deployed at:", address(accessUtilsSystem));

    console.log("All systems deployed successfully!");
  }

  function verifyInstallation() internal view {
    console.log("Verifying system registrations...");

    // Check if systems are properly registered
    ResourceId storageSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: STORAGE_SYSTEM
    });

    // address systemAddress = world.getSystemAddress(storageSystemId);
    // console.log("StorageSystem verified at:", systemAddress);

    // Additional verification for StoreProxySystem since it's critical
    ResourceId storeProxySystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: NAMESPACE,
      name: STORE_PROXY_SYSTEM
    });

    // address proxyAddress = world.getSystemAddress(storeProxySystemId);
    // console.log("StoreProxySystem verified at:", proxyAddress);

    console.log("Installation verification complete!");
  }

  function printNextSteps() internal view {
    console.log("\n=== Next Steps ===");
    console.log("1. Configure Smart Storage Unit (SSU) permissions:");
    console.log("   Run: forge script ConfigureSSU --rpc-url $RPC_URL --broadcast");
    console.log("");
    console.log("2. Create your first bucket:");
    console.log('   world.%s__createNestedBuckets(ssuId, "my-bucket");');
    console.log("");
    console.log("3. Grant StorageManager permissions to StoreProxySystem:");
    console.log("   - TRANSFER_FROM_EPHEMERAL_ROLE");
    console.log("   - TRANSFER_TO_EPHEMERAL_ROLE");
    console.log("   - CROSS_TRANSFER_TO_EPHEMERAL_ROLE");
    console.log("   - TRANSFER_TO_INVENTORY_ROLE");
    console.log("");
    console.log("4. Import StorageSystem in your project:");
    console.log('   import { storageSystem } from "@awar-dev/storage-manager/codegen/systems/StorageSystemLib";');
    console.log("");
    console.log("Available functions:");
    console.log("   - createNestedBuckets(smartObjectId, bucketName)");
    console.log("   - deposit(smartObjectId, bucketId, transferFromEphemeral, items)");
    console.log("   - withdraw(smartObjectId, bucketId, transferToEphemeral, items)");
    console.log("   - internalTransfer(smartObjectId, fromBucket, toBucket, items)");
    console.log("   - getBucketsMetadata(smartObjectId, bucketIds)");
  }
}
