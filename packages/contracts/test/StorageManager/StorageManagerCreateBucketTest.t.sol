// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { console } from "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { Script } from "forge-std/Script.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { UNLIMITED_DELEGATION } from "@latticexyz/world/src/constants.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_NAMESPACE, RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { AccessSystemLib, accessSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/AccessSystemLib.sol";
import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { IBaseWorld } from "@eveworld/world-v2/src/codegen/world/IWorld.sol";
import { SmartCharacterSystem, smartCharacterSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/SmartCharacterSystemLib.sol";
import { Location, LocationData } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/Location.sol";
import { DeployableState } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/DeployableState.sol";
import { FuelSystem, fuelSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/FuelSystemLib.sol";
import { FuelParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/fuel/types.sol";
import { SmartAssemblySystem, smartAssemblySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/SmartAssemblySystemLib.sol";
import { EntityRecordParams, EntityMetadataParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/entity-record/types.sol";
import { Tenant, Characters, CharactersByAccount, EntityRecord } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/index.sol";
import { SmartStorageUnitSystem, smartStorageUnitSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/SmartStorageUnitSystemLib.sol";
import { CreateAndAnchorParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/types.sol";
import { DeployableSystem, deployableSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/DeployableSystemLib.sol";
import { ObjectIdLib } from "@eveworld/world-v2/src/namespaces/evefrontier/libraries/ObjectIdLib.sol";
import { State } from "@eveworld/world-v2/src/codegen/common.sol";
import { InventorySystem, inventorySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/InventorySystemLib.sol";
import { EphemeralInventorySystem, ephemeralInventorySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/EphemeralInventorySystemLib.sol";
import { EphemeralInteractSystemLib, ephemeralInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/EphemeralInteractSystemLib.sol";
import { CreateInventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { InventoryItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/InventoryItem.sol";
import { EphemeralInvItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/EphemeralInvItem.sol";

import { BucketMetadata } from "../../src/codegen/tables/BucketMetadata.sol";
import { BucketConfig } from "../../src/codegen/tables/BucketConfig.sol";
import { InventoryBalancesData, InventoryBalances } from "../../src/codegen/tables/InventoryBalances.sol";
import { BucketedInventoryItemData, BucketedInventoryItem } from "../../src/codegen/tables/BucketedInventoryItem.sol";
import { StoreProxySystemLib, storeProxySystem } from "../../src/codegen/systems/StoreProxySystemLib.sol";

/** DELETE */
import { Entity } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/tables/Entity.sol";
import { OwnershipByObject } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/OwnershipByObject.sol";
/** DELETE */

import { IWorld } from "@world/IWorld.sol";
import { SetupTestWithBucketsTest } from "../SetupTestWithBucketsTest.t.sol";
import "@systems/StorageSystem/Errors.sol";
import { BucketMetadata } from "../../src/codegen/tables/BucketMetadata.sol";
import { Bytes32StringPacker } from "../../src/systems/StringPacker/StringPackerBytes.sol";

contract StorageManagerCreateBucketTest is SetupTestWithBucketsTest {
  using Bytes32StringPacker for string;
  using Bytes32StringPacker for bytes32;

  function setUp() public override {
    super.setUp();
    vm.resumeGasMetering();
  }

  function testComposeBucketIdsCreatesUniqueIds() public {
    vm.pauseGasMetering();
    string memory bucketName = "testt";
    vm.resumeGasMetering();
    bytes32[] memory bucketIds = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketName);
    vm.pauseGasMetering();
    assertEq(bucketIds.length, 1, "Expected 1 bucket to be created");
    string memory bucketNameTwo = "tester";
    bytes32[] memory bucketIdsTwo = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketNameTwo);
    assertEq(bucketIdsTwo.length, 1, "Expected 1 bucket to be created");

    assertNotEq(bucketId, bucketIdsTwo[0], "Expected all bucket IDs to be unique");
    vm.resumeGasMetering();
  }

  function testStorageManagerCreateNestedBuckets() public {
    vm.pauseGasMetering();
    string memory bucketName = "testt/test1/test2";

    // Create buckets
    vm.startPrank(player);
    vm.resumeGasMetering();
    bytes32[] memory bucketIds = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketName);
    vm.pauseGasMetering();
    vm.stopPrank();
    console.log("Bucket IDs:");
    assertEq(bucketIds.length, 3, "Expected three buckets to be created");

    // Verify buckets were created
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[0]), true, "Expected bucket 0 to exist");
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[1]), true, "Expected bucket 1 to exist");
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[2]), true, "Expected bucket 2 to exist");

    assertEq(
      BucketMetadata.getParentBucketId(ssuId, bucketIds[1]),
      bucketIds[0],
      "Expected parent bucket of bucket 1 to be bucket 0"
    );
    assertEq(
      BucketMetadata.getParentBucketId(ssuId, bucketIds[2]),
      bucketIds[1],
      "Expected parent bucket of bucket 2 to be bucket 1"
    );

    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[0]), address(1), "Expected owner of bucket 0 to be player");
    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[1]), address(1), "Expected owner of bucket 1 to be player");
    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[2]), address(1), "Expected owner of bucket 2 to be player");
    vm.resumeGasMetering();
  }

  function testStorageManageerCreateNestedBucketsWithPrependedDirectory() public {
    vm.pauseGasMetering();
    string memory bucketName = "/testt/test1/test2";

    // Create buckets
    vm.startPrank(player);
    vm.resumeGasMetering();
    bytes32[] memory bucketIds = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketName);
    vm.pauseGasMetering();
    vm.stopPrank();
    console.log("Bucket IDs:");

    console.logBytes32(bucketIds[0]);
    console.logBytes32(bucketIds[1]);
    console.logBytes32(bucketIds[2]);
    assertEq(bucketIds.length, 3, "Expected three buckets to be created");

    // Verify buckets were created
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[0]), true, "Expected bucket 0 to exist");
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[1]), true, "Expected bucket 1 to exist");
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[2]), true, "Expected bucket 2 to exist");

    assertEq(
      BucketMetadata.getParentBucketId(ssuId, bucketIds[1]),
      bucketIds[0],
      "Expected parent bucket of bucket 1 to be bucket 0"
    );
    assertEq(
      BucketMetadata.getParentBucketId(ssuId, bucketIds[2]),
      bucketIds[1],
      "Expected parent bucket of bucket 2 to be bucket 1"
    );

    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[0]), address(1), "Expected owner of bucket 0 to be player");
    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[1]), address(1), "Expected owner of bucket 1 to be player");
    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[2]), address(1), "Expected owner of bucket 2 to be player");
    vm.resumeGasMetering();
  }

  function testStorageManagerCreateNestedBucketsThrowOnGteMax() public {
    vm.pauseGasMetering();
    string memory failingBucketName = "test0/test1/test2/test3/test4/test5";
    string memory successfulBucketName = "test0/test1/test2/test3/test4";

    // Fail to create bucket of depth 6
    vm.startPrank(player);
    vm.expectRevert(abi.encodeWithSelector(InvalidBucketName.selector));
    bytes32[] memory failedBucketIds = world.sm_v0_2_0__createNestedBuckets(ssuId, failingBucketName);
    vm.stopPrank();

    // Create bucket of depth 5 successfully
    vm.resumeGasMetering();
    vm.startPrank(player);
    bytes32[] memory bucketIds = world.sm_v0_2_0__createNestedBuckets(ssuId, successfulBucketName);
    vm.stopPrank();
    vm.pauseGasMetering();
    assertEq(bucketIds.length, 5, "Expected three buckets to be created");

    // Verify buckets were created
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[0]), true, "Expected bucket 0 to exist");
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[1]), true, "Expected bucket 1 to exist");
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[2]), true, "Expected bucket 2 to exist");

    assertEq(
      BucketMetadata.getParentBucketId(ssuId, bucketIds[1]),
      bucketIds[0],
      "Expected parent bucket of bucket 1 to be bucket 0"
    );
    assertEq(
      BucketMetadata.getParentBucketId(ssuId, bucketIds[2]),
      bucketIds[1],
      "Expected parent bucket of bucket 2 to be bucket 1"
    );

    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[0]), address(1), "Expected owner of bucket 0 to be player");
    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[1]), address(1), "Expected owner of bucket 1 to be player");
    assertEq(BucketMetadata.getOwner(ssuId, bucketIds[2]), address(1), "Expected owner of bucket 2 to be player");
  }

  function testNonStorageManagerSystemCannotCall() public {
    vm.pauseGasMetering();
    InventoryItemParams[] memory depositTransferItems = new InventoryItemParams[](2);
    depositTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(10) });
    depositTransferItems[1] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(20) });

    // Authorized Deposit items into bucket
    vm.startPrank(player);
    vm.expectRevert("Only StorageSystem can call this function");
    vm.resumeGasMetering();
    storeProxySystem.proxyTransferFromEphemeral(ssuId, player, depositTransferItems);
    vm.stopPrank();
  }

}
