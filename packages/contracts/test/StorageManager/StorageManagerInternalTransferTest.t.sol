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

contract StoragStorageManagerEphemeralTesteManagerTest is SetupTestWithBucketsTest {
  using Bytes32StringPacker for string;
  using Bytes32StringPacker for bytes32;

  function setUp() public override {
    super.setUp();
    vm.resumeGasMetering();
  }

  function testTransferBetweenBucketsOwnedBySamePlayers() public {
    vm.pauseGasMetering();
    /** Internal Transfer */
    string memory bucketNameTwo = "testbuckettwo";
    // Create second bucket
    vm.startPrank(admin);
    bytes32[] memory bucketIdsTwo = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketNameTwo);
    vm.stopPrank();
    assertEq(bucketIdsTwo.length, 1, "Expected one bucket to be created");
    // Verify buckets were created
    assertEq(BucketMetadata.getExists(ssuId, bucketIdsTwo[0]), true);
    assertNotEq(bucketId, bucketIdsTwo[0], "Expected bucket ids to be different for the two buckets created");
    // set up invalid transfer items arr
    uint256 invalidQtyToTransfer = 500000;
    InventoryItemParams[] memory invalidTransferItems = new InventoryItemParams[](1);
    invalidTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(invalidQtyToTransfer) });
    // Test unauthorized player transfer items between buckets - should fail
    vm.startPrank(unauthorizedPlayer);
    vm.expectRevert(UnauthorizedWithdraw.selector);
    world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[0], invalidTransferItems);
    vm.stopPrank();
    // Authorization not needed for transfer, because it is an internal transfer with no actual movement of goods out of primary inventory
    // Authorized Transfer items between buckets - but should fail due to insufficient quantity
    // assertEq(
    //   BucketedInventoryItem.getQuantity(bucketId, itemId) < invalidTransferItems[0].quantity,
    //   true,
    //   "Expected primary inventory balance to be greater than or equal to invalid transfer amount"
    // );
    vm.startPrank(player);
    vm.expectRevert(InsufficientQuantityInSourceBucket.selector);

    world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[0], invalidTransferItems);
    vm.stopPrank();
    // authorized Transfer items between buckets with bucket having valid amount
    uint64 beforeTransferBucketTwoBalance = uint64(BucketedInventoryItem.getQuantity(bucketIdsTwo[0], itemId));
    // create valid items to transfer
    uint256 validQtyToTransfer = 5;
    InventoryItemParams[] memory validTransferItems = new InventoryItemParams[](1);
    validTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(validQtyToTransfer) });
    uint64 before = uint64(InventoryItem.getQuantity(ssuId, itemId));

    vm.startPrank(player);
    vm.resumeGasMetering();
    world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[0], validTransferItems);
    vm.pauseGasMetering();
    vm.stopPrank();
    // Verify the transfer was successful and no change occurred in the primary inventory balance
    uint64 afterTransferPrimaryInventoryBalance = uint64(InventoryItem.getQuantity(ssuId, itemId));
    assertEq(
      before,
      afterTransferPrimaryInventoryBalance,
      "Expected primary inventory balance to be the same after transfer"
    );
    // expect bucket balance to be 5 less in the first bucket and 5 more in the second bucket
    uint64 afterTransferBucketOneBalance = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    uint64 afterTransferBucketTwoBalance = uint64(BucketedInventoryItem.getQuantity(bucketIdsTwo[0], itemId));
    assertEq(
      afterTransferBucketOneBalance,
      uint64(afterDepositBucketBalance) - uint64(validQtyToTransfer),
      "Expected bucket balance to be 5 less in the first bucket after transfer"
    );
    assertEq(
      afterTransferBucketTwoBalance,
      validQtyToTransfer,
      "Expected recipient bucket balance to be validQtyToTransfer after transfer because it starts empty"
    );
    vm.resumeGasMetering();
  }

  function testTransferBetweenBucketsOwnedByDifferentPlayers() public {
    vm.pauseGasMetering();
    // expect bucket balance to be totalDepositAmount
    uint64 beforeTransferBucketOneBalance = BucketedInventoryItem.getQuantity(bucketId, itemId);
    assertEq(beforeTransferBucketOneBalance, totalDepositAmount, "Expected bucket balance to be 30 after deposit");
    // expect the primary inventory balance to have increased by the total deposit amount
    uint64 afterDepositPrimaryInventoryBalance = uint64(InventoryItem.getQuantity(ssuId, itemId));
    assertEq(
      afterDepositPrimaryInventoryBalance - STARTING_INV_ITEM_QUANTITY,
      totalDepositAmount,
      "Expected primary inventory balance to be 30 after deposit"
    );

    /** Internal Transfer */
    string memory bucketNameTwo = "testbuckettwo";
    // Create second bucket
    vm.startPrank(player);
    bytes32[] memory bucketIdsTwo = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketNameTwo);
    vm.stopPrank();
    assertEq(bucketIdsTwo.length, 1, "Expected one bucket to be created");
    // Verify buckets were created
    assertEq(BucketMetadata.getExists(ssuId, bucketIdsTwo[0]), true);
    assertNotEq(bucketId, bucketIdsTwo[0], "Expected bucket ids to be different for the two buckets created");
    // set up invalid transfer items arr
    {
      uint256 invalidQtyToTransfer = 500000;

      InventoryItemParams[] memory invalidTransferItems = new InventoryItemParams[](1);
      invalidTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(invalidQtyToTransfer) });
      // Test unauthorized player transfer items between buckets - should fail
      vm.startPrank(unauthorizedPlayer);
      vm.expectRevert(UnauthorizedWithdraw.selector);
      world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[0], invalidTransferItems);
      vm.stopPrank();

      // Authorization not needed for transfer, because it is an internal transfer with no actual movement of goods out of primary inventory
      // Authorized Transfer items between buckets - but should fail due to insufficient quantity
      vm.startPrank(player);
      vm.expectRevert(InsufficientQuantityInSourceBucket.selector);
      world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[0], invalidTransferItems);
      vm.stopPrank();
    }
    // authorized Transfer items between buckets with bucket having valid amount
    uint64 beforeTransferBucketTwoBalance = uint64(BucketedInventoryItem.getQuantity(bucketIdsTwo[0], itemId));
    // create valid items to transfer
    uint256 validQtyToTransfer = 5;
    InventoryItemParams[] memory validTransferItems = new InventoryItemParams[](1);
    validTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(validQtyToTransfer) });
    vm.startPrank(player);
    vm.resumeGasMetering();
    world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[0], validTransferItems);
    vm.pauseGasMetering();
    vm.stopPrank();

    // Verify the transfer was successful and no change occurred in the primary inventory balance
    uint64 afterTransferPrimaryInventoryBalance = uint64(InventoryItem.getQuantity(ssuId, itemId));
    assertEq(
      afterDepositPrimaryInventoryBalance,
      afterTransferPrimaryInventoryBalance,
      "Expected primary inventory balance to the same after transfer"
    );
    // expect bucket balance to be `validQtyToTransfer` less in the first bucket and `validQtyToTransfer` more in the second bucket
    uint64 afterTransferBucketOneBalance = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    uint64 afterTransferBucketTwoBalance = uint64(BucketedInventoryItem.getQuantity(bucketIdsTwo[0], itemId));
    assertEq(
      afterTransferBucketOneBalance,
      uint64(beforeTransferBucketOneBalance) - uint64(validQtyToTransfer),
      "Expected bucket balance to be `validQtyToTransfer` less in the first bucket after transfer"
    );
    assertEq(
      afterTransferBucketTwoBalance,
      beforeTransferBucketTwoBalance + validQtyToTransfer,
      "Expected recipient bucket balance to be `validQtyToTransfer` after transfer because it starts empty"
    );
    vm.resumeGasMetering();
  }

  function testTransferBetweenBucketsOwnedByDifferentPlayersHalfDeep() public {
    vm.pauseGasMetering();
    // expect bucket balance to be totalDepositAmount
    uint64 beforeTransferBucketOneBalance = BucketedInventoryItem.getQuantity(bucketId, itemId);
    assertEq(beforeTransferBucketOneBalance, totalDepositAmount, "Expected bucket balance to be 30 after deposit");
    // expect the primary inventory balance to have increased by the total deposit amount
    uint64 afterDepositPrimaryInventoryBalance = uint64(InventoryItem.getQuantity(ssuId, itemId));
    assertEq(
      afterDepositPrimaryInventoryBalance - STARTING_INV_ITEM_QUANTITY,
      totalDepositAmount,
      "Expected primary inventory balance to be 30 after deposit"
    );

    /** Internal Transfer */
    string memory bucketNameTwo = "testtt/test0/test1/test2/test3";
    // Create second bucket
    vm.startPrank(player);
    bytes32[] memory bucketIdsTwo = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketNameTwo);
    vm.stopPrank();
    assertEq(bucketIdsTwo.length, 5, "Expected 5 buckets to be created");
    // Verify buckets were created
    assertEq(BucketMetadata.getExists(ssuId, bucketIdsTwo[0]), true);
    assertNotEq(bucketId, bucketIdsTwo[4], "Expected bucket ids to be different for the two buckets created");
    // set up invalid transfer items arr
    {
      uint256 invalidQtyToTransfer = 500000;

      InventoryItemParams[] memory invalidTransferItems = new InventoryItemParams[](1);
      invalidTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(invalidQtyToTransfer) });
      // Test unauthorized player transfer items between buckets - should fail
      vm.startPrank(unauthorizedPlayer);
      vm.expectRevert(UnauthorizedWithdraw.selector);
      world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[4], invalidTransferItems);
      vm.stopPrank();

      // Authorization not needed for transfer, because it is an internal transfer with no actual movement of goods out of primary inventory
      // Authorized Transfer items between buckets - but should fail due to insufficient quantity
      vm.startPrank(player);
      vm.expectRevert(InsufficientQuantityInSourceBucket.selector);
      world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[4], invalidTransferItems);
      vm.stopPrank();
    }
    // authorized Transfer items between buckets with bucket having valid amount
    uint64 beforeTransferBucketTwoBalance = uint64(BucketedInventoryItem.getQuantity(bucketIdsTwo[4], itemId));
    // create valid items to transfer
    uint256 validQtyToTransfer = 5;
    InventoryItemParams[] memory validTransferItems = new InventoryItemParams[](1);
    validTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(validQtyToTransfer) });
    vm.startPrank(player);
    vm.resumeGasMetering();
    world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[4], validTransferItems);
    vm.pauseGasMetering();
    vm.stopPrank();

    // Verify the transfer was successful and no change occurred in the primary inventory balance
    uint64 afterTransferPrimaryInventoryBalance = uint64(InventoryItem.getQuantity(ssuId, itemId));
    assertEq(
      afterDepositPrimaryInventoryBalance,
      afterTransferPrimaryInventoryBalance,
      "Expected primary inventory balance to the same after transfer"
    );
    // expect bucket balance to be `validQtyToTransfer` less in the first bucket and `validQtyToTransfer` more in the second bucket
    uint64 afterTransferBucketOneBalance = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    uint64 afterTransferBucketTwoBalance = uint64(BucketedInventoryItem.getQuantity(bucketIdsTwo[4], itemId));
    assertEq(
      afterTransferBucketOneBalance,
      uint64(beforeTransferBucketOneBalance) - uint64(validQtyToTransfer),
      "Expected bucket balance to be `validQtyToTransfer` less in the first bucket after transfer"
    );
    assertEq(
      afterTransferBucketTwoBalance,
      beforeTransferBucketTwoBalance + validQtyToTransfer,
      "Expected recipient bucket balance to be `validQtyToTransfer` after transfer because it starts empty"
    );
    uint64 transferAllQtyToTransfer = afterTransferBucketOneBalance;
    InventoryItemParams[] memory transferAllItems = new InventoryItemParams[](1);
    transferAllItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(transferAllQtyToTransfer) });
    // transfer all remaining items to the other bucket
    vm.startPrank(player);
    world.sm_v0_2_0__internalTransfer(ssuId, bucketId, bucketIdsTwo[4], transferAllItems);
    vm.stopPrank();
    // expect first bucket to be empty and second bucket to have all items
    bool exists = BucketedInventoryItem.getExists(bucketId, itemId);
    assertEq(exists, false, "Expected first bucket to be empty");
    vm.resumeGasMetering();
  }
}
