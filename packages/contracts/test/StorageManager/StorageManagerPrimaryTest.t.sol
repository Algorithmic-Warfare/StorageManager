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
import { inventoryInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/InventoryInteractSystemLib.sol";
import { ephemeralInventorySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/EphemeralInventorySystemLib.sol";
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

contract StorageManagerPrimaryTest is SetupTestWithBucketsTest {
  using Bytes32StringPacker for string;
  using Bytes32StringPacker for bytes32;

  function setUp() public override {
    super.setUp();
    // transfer the item from ephemeral to primary inventory
    vm.pauseGasMetering();
    // vm.startPrank(player);
    // ephemeralInteractSystem.setTransferFromEphemeralAccess(ssuId, player, true);
    // vm.stopPrank();
    // vm.startPrank(admin);
    // ephemeralInteractSystem.setTransferFromEphemeralAccess(ssuId, storeProxySystemAddress, true);
    // vm.stopPrank();
    // InventoryItemParams[] memory transferItems = new InventoryItemParams[](2);
    // transferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(10) });
    // transferItems[1] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(20) });
    console.log("store proxy address:");
    console.logAddress(storeProxySystemAddress);

    // vm.prank(player);
    // vm.expectRevert(
    //   abi.encodeWithSelector(
    //     AccessSystemLib.Access_CannotTransferFromEphemeral.selector,
    //     storeProxySystemAddress,
    //     ssuId
    //   )
    // );
    // ephemeralInteractSystem.transferFromEphemeral(ssuId, player, transferItems);
    // vm.stopPrank();
    vm.resumeGasMetering();
  }

  function testDepositFromPrimaryToBucket() public {
    /** Deposit */
    vm.pauseGasMetering();

    uint64 totalDepositAmount = 10;
    InventoryItemParams[] memory depositTransferItems = new InventoryItemParams[](1);
    depositTransferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(totalDepositAmount) });
    uint256 startInventoryBal = uint64(InventoryItem.getQuantity(ssuId, itemId));
    assertEq(
      startInventoryBal,
      primaryQtyAfterDeposit,
      "Expected smart object's inventory balances to be the same as the total transfer amount before deposit"
    );
    // Test unauthorized Deposit items into bucket (unauthorized depositor)

    // Set authorization to system - not necessary since transferring from primary inventory to bucket
    // isn't considered a transfer in world-contracts-v2's access system

    vm.startPrank(nonInventoryOwnerPlayer);
    vm.expectRevert(UnauthorizedDepositFromOwnerInventory.selector);
    world.sm_v0_2_0__deposit(ssuId, bucketId, true, depositTransferItems);
    vm.stopPrank();

    vm.startPrank(player);
    vm.expectRevert(UnauthorizedDepositFromOwnerInventory.selector);
    world.sm_v0_2_0__deposit(ssuId, bucketId, true, depositTransferItems);
    vm.stopPrank();

    vm.startPrank(admin);
    world.sm_v0_2_0__deposit(ssuId, bucketId, true, depositTransferItems);
    vm.stopPrank();
    // Verify the deposit was successful
    uint64 bucketBalanceAfterDeposit = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    uint64 metadataQtyAfterDepositFinal = InventoryBalances.getQuantity(ssuId, itemId);
    assertEq(
      metadataQtyAfterDepositFinal,
      metadataQtyAfterDeposit + totalDepositAmount,
      "Expected smart object's inventory balances to be smaller after deposit by `totalDepositAmount` amount"
    );
    assertEq(
      bucketBalanceAfterDeposit,
      afterDepositBucketBalance + totalDepositAmount,
      "Expected bucket balance to be larger after deposit by `totalDepositAmount` amount"
    );

    assertEq(
      InventoryItem.getQuantity(ssuId, itemId),
      startInventoryBal,
      "Expected primary inventory balance to not change after deposit - since we are depositing from primary"
    );
  }

  function testWithdrawFromBucketToPrimary() public {
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
    world.sm_v0_2_0__withdraw(ssuId, bucketId, true, withdrawTransferItems);
    vm.stopPrank();

    // Test authorized account, but unauthorized sender - Deposit items into bucket
    // vm.startPrank(player);
    // vm.expectRevert(
    //   abi.encodeWithSelector(
    //     AccessSystemLib.Access_NotDirectOwnerOrCanTransferToEphemeral.selector,
    //     storeProxySystemAddress,
    //     ssuId
    //   )
    // );
    // vm.resumeGasMetering();
    // world.sm_v0_2_0__withdraw(ssuId, bucketId, true, withdrawTransferItems);
    // vm.pauseGasMetering();
    // vm.stopPrank();

    // Set authorization to system
    // vm.startPrank(admin);
    // ephemeralInteractSystem.setTransferToEphemeralAccess(ssuId, storeProxySystemAddress, true);
    // vm.stopPrank();
    // Authorized Deposit items into bucket
    uint64 primaryBalanceBeforeWithdraw = uint64(InventoryItem.getQuantity(ssuId, itemId));
    vm.startPrank(player);
    world.sm_v0_2_0__withdraw(ssuId, bucketId, true, withdrawTransferItems);
    vm.stopPrank();
    // Verify the deposit was successful
    uint64 primaryBalanceAfterWithdraw = uint64(InventoryItem.getQuantity(ssuId, itemId));
    uint64 metadataQtyAfterWithdraw = InventoryBalances.getQuantity(ssuId, itemId);
    assertEq(
      metadataQtyAfterWithdraw,
      metadataQtyAfterDeposit - totalWithdrawAmount,
      "Expected smart object's inventory balances to be smaller after withdraw by `totalWithdrawAmount` amount"
    );
    assertEq(
      primaryBalanceAfterWithdraw,
      primaryBalanceBeforeWithdraw,
      "Expected primary inventory balance to not change after withdraw - since we are withdrawing to primary"
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

  function testWithdrawFullFromBucketToPrimary() public {
    /** Withdraw */
    vm.pauseGasMetering();
    uint64 totalWithdrawAmount = uint64(afterDepositBucketBalance);
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
    world.sm_v0_2_0__withdraw(ssuId, bucketId, true, withdrawTransferItems);
    vm.stopPrank();

    // Test authorized account, but unauthorized sender - Deposit items into bucket
    // vm.startPrank(player);
    // vm.expectRevert(
    //   abi.encodeWithSelector(
    //     AccessSystemLib.Access_NotDirectOwnerOrCanTransferToEphemeral.selector,
    //     storeProxySystemAddress,
    //     ssuId
    //   )
    // );
    // vm.resumeGasMetering();
    // world.sm_v0_2_0__withdraw(ssuId, bucketId, true, withdrawTransferItems);
    // vm.pauseGasMetering();
    // vm.stopPrank();

    // Set authorization to system
    // vm.startPrank(admin);
    // ephemeralInteractSystem.setTransferToEphemeralAccess(ssuId, storeProxySystemAddress, true);
    // vm.stopPrank();
    // Authorized Deposit items into bucket
    uint64 primaryBalanceBeforeWithdraw = uint64(InventoryItem.getQuantity(ssuId, itemId));
    vm.startPrank(player);
    world.sm_v0_2_0__withdraw(ssuId, bucketId, true, withdrawTransferItems);
    vm.stopPrank();
    // Verify the deposit was successful
    uint64 primaryBalanceAfterWithdraw = uint64(InventoryItem.getQuantity(ssuId, itemId));
    uint64 metadataQtyAfterWithdraw = InventoryBalances.getQuantity(ssuId, itemId);
    assertEq(
      metadataQtyAfterWithdraw,
      metadataQtyAfterDeposit - totalWithdrawAmount,
      "Expected smart object's inventory balances to be smaller after withdraw by `totalWithdrawAmount` amount"
    );
    assertEq(
      primaryBalanceAfterWithdraw,
      primaryBalanceBeforeWithdraw,
      "Expected primary inventory balance to not change after withdraw - since we are withdrawing to primary"
    );
    // // // expect bucket balance to be 0
    BucketedInventoryItemData memory bucketBalance = BucketedInventoryItem.get(bucketId, itemId);
    assertEq(uint64(bucketBalance.quantity), 0, "Expected bucket balance to be 0 after withdraw");
    assertEq(bucketBalance.exists, false, "Expected bucket balance to be cleared after zeroing out");
    // transfer items from buckets to ephemeral to zero out inventory balances

    // clear out inventorybalances
    bool inventoryBalance = InventoryBalances.getExists(ssuId, itemId);
    assertEq(inventoryBalance, false, "Expected smart object's inventory balances to be deleted if it zeroes out");
  }
}
