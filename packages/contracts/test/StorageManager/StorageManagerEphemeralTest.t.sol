// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { AccessSystemLib, accessSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/AccessSystemLib.sol";
import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
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

contract StorageManagerEphemeralTesteManagerTest is SetupTestWithBucketsTest {
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
  

  function testWithdrawFromBucketToEphemeral() public {
    /** Withdraw */
    vm.pauseGasMetering();

    uint64 totalWithdrawAmount = 10;
    InventoryItemParams[] memory withdrawTransferItems = new InventoryItemParams[](1);
    withdrawTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(totalWithdrawAmount) });
    uint256 startBucketBal = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    assertEq(
      startBucketBal,
      afterDepositBucketBalance,
      "Expected bucket balance to be the same as the total deposit amount before withdraw"
    );
    // Test unauthorized Deposit items into bucket
    vm.startPrank(unauthorizedPlayer);
    vm.expectRevert(UnauthorizedWithdraw.selector);
    world.sm_v0_2_0__withdraw(ssuId, bucketId, withdrawTransferItems);
    vm.stopPrank();

    // Test authorized account, but unauthorized sender - Deposit items into bucket
    vm.startPrank(player);
    vm.expectRevert(
      abi.encodeWithSelector(
        AccessSystemLib.Access_NotEphemeralOwnerOrCallAccessWithEphemeralOwner.selector,
        storeProxySystem.getAddress(),
        ssuId
      )
    );
    vm.resumeGasMetering();
    world.sm_v0_2_0__withdraw(ssuId, bucketId, withdrawTransferItems);
    vm.pauseGasMetering();
    vm.stopPrank();

    // Set authorization to system
    vm.startPrank(admin);
    ephemeralInteractSystem.setCrossTransferToEphemeralAccess(ssuId, storeProxySystemAddress, true);
    ephemeralInteractSystem.setTransferFromEphemeralAccess(ssuId, storeProxySystemAddress, true);
    ephemeralInteractSystem.setTransferToEphemeralAccess(ssuId, storeProxySystemAddress, true);
    vm.stopPrank();
    // Authorized withdraw items from bucket
    vm.startPrank(player);
    world.sm_v0_2_0__withdraw(ssuId, bucketId, withdrawTransferItems);
    vm.stopPrank();
    // Verify the deposit was successful
    uint64 ephBalanceAfterWithdraw = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    uint64 custodyBalanceAfterWithdraw = uint64(EphemeralInvItem.getQuantity(ssuId, custodyAddress, itemId));
    assertEq(
      custodyBalanceAfterWithdraw,
      custodyQtyAfterDeposit - totalWithdrawAmount,
      "Expected smart object's custody address balances to be smaller after withdraw by `totalWithdrawAmount` amount"
    );
    assertEq(
      ephBalanceAfterWithdraw,
      ephBalanceAfterDeposit + totalWithdrawAmount,
      "Expected ephemeral inventory balance to be back to full after withdraw"
    );
    // // // expect bucket balance to be 0
    // BucketedInventoryItemData memory bucketBalance = BucketedInventoryItem.get(bucketId, itemId);
    // assertEq(
    //   uint64(bucketBalance.quantity),
    //   0,
    //   "Expected bucket balance to be 0 after withdraw"
    // );
    // assertEq(
    //   bucketBalance.exists,
    //   false,
    //   "Expected bucket balance to be cleared after zeroing out"
    // );
    // transfer items from buckets to ephemeral to zero out inventory balances
    // uint64 inventoryBalanceBefore = InventoryItemBalance.getQuantity(ssuId, itemId);
    // InventoryItemParams[] memory itemTransferAll = new InventoryItemParams[](1);
    // itemTransferAll[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(inventoryBalanceBefore) });
    // vm.startPrank(admin);
    // world.sm_v0_2_0__withdraw(ssuId, bucketId, false, itemTransferAll);
    // vm.stopPrank();

    // clear out inventorybalances
    // bool inventoryBalance = InventoryBalances.getExists(ssuId, itemId);
    // assertEq(
    //   inventoryBalance,
    //   false,
    //   "Expected smart object's inventory balances to be deleted if it zeroes out"
    // );
  }

  function testWithdrawFullFromBucketToEphemeral() public {
    /** Withdraw */
    vm.pauseGasMetering();
    uint64 totalWithdrawAmount = uint64(afterDepositBucketBalance);
    InventoryItemParams[] memory withdrawTransferItems = new InventoryItemParams[](1);
    withdrawTransferItems[0] = InventoryItemParams({
      smartObjectId: itemId,
      quantity: uint64(totalWithdrawAmount)
    });
    uint256 startBucketBal = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    assertEq(
      startBucketBal,
      afterDepositBucketBalance,
      "Expected bucket balance to be the same as the total deposit amount before withdraw"
    );
    // Test unauthorized Deposit items into bucket
    vm.startPrank(unauthorizedPlayer);
    vm.expectRevert(UnauthorizedWithdraw.selector);
    world.sm_v0_2_0__withdraw(ssuId, bucketId, withdrawTransferItems);
    vm.stopPrank();

    // Test authorized account, but unauthorized sender - Deposit items into bucket
    vm.startPrank(player);
    vm.expectRevert(
      abi.encodeWithSelector(
        AccessSystemLib.Access_NotEphemeralOwnerOrCallAccessWithEphemeralOwner.selector,
        custodyAddress,
        ssuId
      )
    );
    vm.resumeGasMetering();
    world.sm_v0_2_0__withdraw(ssuId, bucketId, withdrawTransferItems);
    vm.pauseGasMetering();
    vm.stopPrank();

    // Set authorization to system
    vm.startPrank(admin);
    ephemeralInteractSystem.setCrossTransferToEphemeralAccess(ssuId, storeProxySystemAddress, true);
    vm.stopPrank();
    // Authorized Withdraw items from bucket
    vm.startPrank(player);
    world.sm_v0_2_0__withdraw(ssuId, bucketId, withdrawTransferItems);
    vm.stopPrank();
    // Verify the deposit was successful
    uint64 ephBalanceAfterWithdraw = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    uint64 metadataQtyAfterWithdraw = InventoryBalances.getQuantity(ssuId, itemId);
    assertEq(
      metadataQtyAfterWithdraw,
      metadataQtyAfterDeposit - totalWithdrawAmount,
      "Expected smart object's inventory balances to be smaller after withdraw by `totalWithdrawAmount` amount"
    );
    assertEq(
      ephBalanceAfterWithdraw,
      ephBalanceAfterDeposit + totalWithdrawAmount,
      "Expected ephemeral inventory balance to be back to full after withdraw"
    );
    // // // expect bucket balance to be 0
    BucketedInventoryItemData memory bucketBalance = BucketedInventoryItem.get(bucketId, itemId);
    assertEq(uint64(bucketBalance.quantity), 0, "Expected bucket balance to be 0 after withdraw");
    assertEq(
      bucketBalance.exists,
      false,
      "Expected bucket balance to be cleared after zeroing out"
    );
    // transfer items from buckets to ephemeral to zero out inventory balances

    // clear out inventorybalances
    bool inventoryBalance = InventoryBalances.getExists(ssuId, itemId);
    assertEq(
      inventoryBalance,
      false,
      "Expected smart object's inventory balances to be deleted if it zeroes out"
    );
  }

    function testWithdrawFullFromBucketToPlayer() public {
    /** Withdraw */
    vm.pauseGasMetering();
    uint64 totalWithdrawAmount = uint64(afterDepositBucketBalance);
    InventoryItemParams[] memory withdrawTransferItems = new InventoryItemParams[](1);
    withdrawTransferItems[0] = InventoryItemParams({
      smartObjectId: itemId,
      quantity: uint64(totalWithdrawAmount)
    });
    uint256 startBucketBal = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    assertEq(
      startBucketBal,
      afterDepositBucketBalance,
      "Expected bucket balance to be the same as the total deposit amount before withdraw"
    );
    // Test unauthorized Deposit items into bucket
    vm.startPrank(unauthorizedPlayer);
    vm.expectRevert(UnauthorizedWithdraw.selector);
    world.sm_v0_2_0__transferToPlayer(ssuId, bucketId, player, withdrawTransferItems);
    vm.stopPrank();

    // Test authorized account, but unauthorized sender - Deposit items into bucket
    vm.startPrank(player);
    vm.expectRevert(
      abi.encodeWithSelector(
        AccessSystemLib.Access_NotEphemeralOwnerOrCallAccessWithEphemeralOwner.selector,
        custodyAddress,
        ssuId
      )
    );
    vm.resumeGasMetering();
    world.sm_v0_2_0__transferToPlayer(ssuId, bucketId, player, withdrawTransferItems);
    vm.pauseGasMetering();
    vm.stopPrank();

    // Set authorization to system
    vm.startPrank(admin);
    ephemeralInteractSystem.setCrossTransferToEphemeralAccess(ssuId, storeProxySystemAddress, true);
    vm.stopPrank();
    // Authorized Deposit items into bucket
    vm.startPrank(player);
    world.sm_v0_2_0__transferToPlayer(ssuId, bucketId, player, withdrawTransferItems);
    vm.stopPrank();
    // Verify the deposit was successful
    uint64 ephBalanceAfterWithdraw = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    uint64 metadataQtyAfterWithdraw = InventoryBalances.getQuantity(ssuId, itemId);
    assertEq(
      metadataQtyAfterWithdraw,
      metadataQtyAfterDeposit - totalWithdrawAmount,
      "Expected smart object's inventory balances to be smaller after withdraw by `totalWithdrawAmount` amount"
    );
    assertEq(
      ephBalanceAfterWithdraw,
      ephBalanceAfterDeposit + totalWithdrawAmount,
      "Expected ephemeral inventory balance to be back to full after withdraw"
    );
    // // // expect bucket balance to be 0
    BucketedInventoryItemData memory bucketBalance = BucketedInventoryItem.get(bucketId, itemId);
    assertEq(uint64(bucketBalance.quantity), 0, "Expected bucket balance to be 0 after withdraw");
    assertEq(
      bucketBalance.exists,
      false,
      "Expected bucket balance to be cleared after zeroing out"
    );
    // transfer items from buckets to ephemeral to zero out inventory balances

    // clear out inventorybalances
    bool inventoryBalance = InventoryBalances.getExists(ssuId, itemId);
    assertEq(
      inventoryBalance,
      false,
      "Expected smart object's inventory balances to be deleted if it zeroes out"
    );
  }
}
