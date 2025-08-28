// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Module } from "@latticexyz/world/src/Module.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { IWorld } from "./codegen/world/IWorld.sol";

// Systems
import { StorageSystem } from "./systems/StorageSystem/StorageSystem.sol";
import { BucketSystem } from "./systems/StorageSystem/BucketSystem.sol";
import { StoreAuthSystem } from "./systems/StorageSystem/StoreAuthSystem.sol";
import { StoreProxySystem } from "./systems/StoreProxySystem/StoreProxySystem.sol";
import { StoreLogicSystem } from "./systems/StorageSystem/StoreLogicSystem.sol";
import { SmUtilsSystem } from "./systems/SmUtilsSystem.sol";
import { AccessUtilsSystem } from "./systems/AccessUtilsSystem.sol";

// Tables (import the generated index to access all table libs)
import { BucketedInventoryItem, BucketMetadata, BucketConfig, InventoryBalances, BucketOwners, BucketInventory } from "./codegen/index.sol";

// Namespace constant
import { DEPLOYMENT_NAMESPACE } from "./systems/StorageSystem/Constants.sol";

contract StorageManagerModule is Module {
  using WorldResourceIdInstance for ResourceId;

  // Pre-deploy systems once at module deployment time
  StorageSystem private immutable storageSystem = new StorageSystem();
  BucketSystem private immutable bucketSystem = new BucketSystem();
  StoreAuthSystem private immutable storeAuthSystem = new StoreAuthSystem();
  StoreProxySystem private immutable storeProxySystem = new StoreProxySystem();
  StoreLogicSystem private immutable storeLogicSystem = new StoreLogicSystem();
  SmUtilsSystem private immutable smUtilsSystem = new SmUtilsSystem();
  AccessUtilsSystem private immutable accessUtilsSystem = new AccessUtilsSystem();

  // Encoded namespace resource id
  ResourceId private immutable namespaceResource = WorldResourceIdLib.encodeNamespace(DEPLOYMENT_NAMESPACE);

  function install(bytes memory) public override {
    IWorld world = IWorld(_world());

    // 1) Register namespace (reverts if already registered)
    world.registerNamespace(namespaceResource);

    // 2) Register tables
    BucketedInventoryItem.register();
    BucketMetadata.register();
    BucketConfig.register();
    InventoryBalances.register();
    BucketOwners.register();
    BucketInventory.register();

    // Pre-compute system resource ids
    ResourceId storageSystemResource = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: DEPLOYMENT_NAMESPACE,
      name: bytes16("StorageSystem")
    });
    ResourceId bucketSystemResource = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: DEPLOYMENT_NAMESPACE,
      name: bytes16("BucketSystem")
    });
    ResourceId storeAuthSystemResource = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: DEPLOYMENT_NAMESPACE,
      name: bytes16("StoreAuthSystem")
    });
    ResourceId storeProxySystemResource = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: DEPLOYMENT_NAMESPACE,
      name: bytes16("StoreProxySystem")
    });
    ResourceId storeLogicSystemResource = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: DEPLOYMENT_NAMESPACE,
      name: bytes16("StoreLogicSystem")
    });
    ResourceId smUtilsSystemResource = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: DEPLOYMENT_NAMESPACE,
      name: bytes16("SmUtilsSystem")
    });
    // Note: name must match mud.config.ts generated system lib name
    ResourceId accessUtilsSystemResource = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: DEPLOYMENT_NAMESPACE,
      name: bytes16("AccessUtilSystem")
    });

    // 3) Register systems (public access)
    world.registerSystem(storageSystemResource, storageSystem, true);
    world.registerSystem(bucketSystemResource, bucketSystem, true);
    world.registerSystem(storeAuthSystemResource, storeAuthSystem, true);
    world.registerSystem(storeProxySystemResource, storeProxySystem, true);
    world.registerSystem(storeLogicSystemResource, storeLogicSystem, true);
    world.registerSystem(smUtilsSystemResource, smUtilsSystem, true);
    world.registerSystem(accessUtilsSystemResource, accessUtilsSystem, true);

    // 3.1) Register function selectors for all callable system functions
    // StorageSystem
    world.registerFunctionSelector(storageSystemResource, "deposit(uint256,bytes32,bool,(uint256,uint256)[])");
    world.registerFunctionSelector(storageSystemResource, "withdraw(uint256,bytes32,bool,(uint256,uint256)[])");
    world.registerFunctionSelector(storageSystemResource, "internalTransfer(uint256,bytes32,bytes32,(uint256,uint256)[])");
    world.registerFunctionSelector(storageSystemResource, "getSystemAddress()");

    // BucketSystem
    world.registerFunctionSelector(bucketSystemResource, "createNestedBuckets(uint256,string)");
    world.registerFunctionSelector(bucketSystemResource, "transferBucketToParent(uint256,bytes32,bytes32)");
    world.registerFunctionSelector(bucketSystemResource, "getCreateSystemAddress()");

    // StoreAuthSystem (authorization helpers and config)
    world.registerFunctionSelector(storeAuthSystemResource, "setAccessSystemId(uint256,bytes32,bytes32)");
    world.registerFunctionSelector(storeAuthSystemResource, "getCharacterTribeByAddress(address)");
    world.registerFunctionSelector(storeAuthSystemResource, "fetchAuthorizationSystemId(uint256,bytes32)");
    // Expected can* methods used by other systems via system libs
    world.registerFunctionSelector(storeAuthSystemResource, "canDeposit(uint256,bytes32,address)");
    world.registerFunctionSelector(storeAuthSystemResource, "canWithdraw(uint256,bytes32,address)");
    world.registerFunctionSelector(storeAuthSystemResource, "canTransferBucket(uint256,bytes32,address)");

    // StoreProxySystem (forwarders to EveWorld systems)
    world.registerFunctionSelector(storeProxySystemResource, "getStoreProxyAddress()");
    world.registerFunctionSelector(storeProxySystemResource, "proxyTransferToEphemeral(uint256,address,(uint256,uint256)[])");
    world.registerFunctionSelector(storeProxySystemResource, "proxyTransferFromEphemeral(uint256,address,(uint256,uint256)[])");
    world.registerFunctionSelector(storeProxySystemResource, "proxyCrossTransferToEphemeral(uint256,address,address,(uint256,uint256)[])");
    world.registerFunctionSelector(storeProxySystemResource, "proxyTransferToInventory(uint256,uint256,(uint256,uint256)[])");

    // StoreLogicSystem (internal ops invoked via world call)
    world.registerFunctionSelector(storeLogicSystemResource, "_processDeposit(uint256,bytes32,(uint256,uint256))");
    world.registerFunctionSelector(storeLogicSystemResource, "_processWithdraw(uint256,bytes32,(uint256,uint256))");
    world.registerFunctionSelector(storeLogicSystemResource, "_processAggBucketsBalance(uint256,bytes32,bool,(uint256,uint256))");

    // SmUtilsSystem (read helpers + batch checks)
    world.registerFunctionSelector(smUtilsSystemResource, "deriveBucketId(uint256,string)");
    world.registerFunctionSelector(smUtilsSystemResource, "getPrimaryInventoryOwnerItems(uint256,address)");
    world.registerFunctionSelector(smUtilsSystemResource, "getEphemeralInventoryItems(uint256,address)");
    world.registerFunctionSelector(smUtilsSystemResource, "getBucketInventoryItems(uint256,bytes32)");
    world.registerFunctionSelector(smUtilsSystemResource, "getBucketsMetadata(uint256,bytes32[])");
    world.registerFunctionSelector(smUtilsSystemResource, "getBatchCanDeposit(uint256,bytes32[],address)");
    world.registerFunctionSelector(smUtilsSystemResource, "getBatchCanWithdraw(uint256,bytes32[],address)");
    world.registerFunctionSelector(smUtilsSystemResource, "getOwnerBalance(uint256,uint256)");
    world.registerFunctionSelector(smUtilsSystemResource, "getBucketsByOwnerAtSSU(uint256,address)");
    world.registerFunctionSelector(smUtilsSystemResource, "getBucketMetadata(uint256,bytes32)");
    world.registerFunctionSelector(smUtilsSystemResource, "getBucketMetadataChain(uint256,bytes32)");
    world.registerFunctionSelector(smUtilsSystemResource, "getBucketMetadataChainByName(uint256,string)");
    world.registerFunctionSelector(smUtilsSystemResource, "getItemTypeIds(uint256[])");

    // AccessUtilsSystem
    world.registerFunctionSelector(accessUtilsSystemResource, "hasRoles(bytes32[],address)");
    world.registerFunctionSelector(accessUtilsSystemResource, "getOwnersOf(uint256[])");

    // 4) Transfer namespace ownership to the installer
    world.transferOwnership(namespaceResource, _msgSender());
  }

  function installRoot(bytes memory encodedArgs) public override {
    // Root install behaves the same; it has root permissions
    install(encodedArgs);
  }
}
