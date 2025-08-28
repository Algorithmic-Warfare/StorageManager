pragma solidity >=0.8.24;

import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { InventoryItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/InventoryItem.sol";
import { OwnershipByObject } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/OwnershipByObject.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorldWithContext } from "@eveworld/smart-object-framework-v2/src/IWorldWithContext.sol";

import { storeAuthSystem } from "../../codegen/systems/StoreAuthSystemLib.sol";
import { storeLogicSystem } from "../../codegen/systems/StoreLogicSystemLib.sol";
import { storeProxySystem } from "../../codegen/systems/StoreProxySystemLib.sol";
import { InventoryBalances } from "../../codegen/tables/InventoryBalances.sol";
import { BucketedInventoryItemData, BucketedInventoryItem } from "../../codegen/tables/BucketedInventoryItem.sol";
import { BucketInventory } from "../../codegen/tables/BucketInventory.sol";
import "./Errors.sol";

contract StorageSystem is System {
  function getSystemAddress() public view returns (address) {
    return address(this);
  }

  function unsafe_increment(uint i) private pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  /**(
   * @notice Deposit items into a bucket.
   * @param smartObjectId The id of the smart object to deposit items into.
   * @param bucketId The id of the bucket to deposit items into.
   * @param transferItems The items to deposit into the bucket, represented as an array of
   *                      InventoryItemParams structs.
   * @dev This function checks if the user is authorized to deposit items into the bucket,
   *      and if the items exist in the ephemeral inventory. If they do exist,
   *      it creates a new entry in the BucketedInventoryItem table for the item and
   *      transfers it from the ephemeral inventory to the primary inventory.
   *      If the item already exists in the bucket, it updates the quantity of the item in the bucket.
   *      It also updates the total metadata for the item in the InventoryBalances table.
   */
  function deposit(
    uint256 smartObjectId,
    bytes32 bucketId,
    bool useOwnerInventory,
    InventoryItemParams[] memory transferItems
  ) public {
    if (!storeAuthSystem.canDeposit(smartObjectId, bucketId, _msgSender())) {
      revert UnauthorizedDeposit();
    }
    (, , address transferrer, ) = IWorldWithContext(_world()).getWorldCallContext(1);
    // for each item in transferItems, check if the item exists in the BucketedInventoryItem table for the bucketId
    // if it does, transfer the item from the ephemeral inventory to the primary inventory
    // if it doesn't, create a new entry in the BucketedInventoryItem table for the item and transfer
    // it from the ephemeral inventory to the primary inventory
    for (uint i = 0; i < transferItems.length; ) {
      InventoryItemParams memory item = transferItems[i];
      // if is depositing from primary inventory, check if the item has a net quantity in the primary inventory (i.e - not already allocated to a bucket)
      if (useOwnerInventory) {
        if (transferrer != OwnershipByObject.getAccount(smartObjectId)) {
          revert UnauthorizedDepositFromOwnerInventory();
        }
        uint256 primaryInventoryQuantity = InventoryItem.getQuantity(smartObjectId, item.smartObjectId);
        uint256 bucketInventoryItem = uint256(InventoryBalances.getQuantity(smartObjectId, item.smartObjectId));
        if (primaryInventoryQuantity - bucketInventoryItem < item.quantity) {
          revert InsufficientQuantityInOwnerInventory();
        }
      }
      // add to the total metadata for the item in the bucket
      storeLogicSystem._processAggBucketsBalance(smartObjectId, bucketId, false, item);
      storeLogicSystem._processDeposit(smartObjectId, bucketId, item);
      i = unsafe_increment(i);
    }
    // transfer the items from the ephemeral inventory to the primary inventory
    if (!useOwnerInventory) {
      storeProxySystem.proxyTransferFromEphemeral(smartObjectId, transferrer, transferItems);
    }
  }

  function withdraw(
    uint256 smartObjectId,
    bytes32 bucketId,
    bool useOwnerInventory,
    InventoryItemParams[] memory transferItems
  ) public {
    if (!storeAuthSystem.canWithdraw(smartObjectId, bucketId, _msgSender())) {
      revert UnauthorizedWithdraw();
    }
    (, , address transferrer, ) = IWorldWithContext(_world()).getWorldCallContext(1);

    for (uint i = 0; i < transferItems.length; ) {
      InventoryItemParams memory item = transferItems[i];
      // check if the item exists in the bucket
      if (!BucketedInventoryItem.getExists(bucketId, item.smartObjectId)) {
        // create a new entry in the BucketedInventoryItem table for the item
        // BucketedInventoryItem.set(bucketId, item.smartObjectId, true, uint64(item.quantity));
        revert ItemNotFoundInBucket(); // if the item does not exist in the bucket, revert as it should have been deposited first before it can be withdrawn
      }
      storeLogicSystem._processAggBucketsBalance(smartObjectId, bucketId, true, item);
      storeLogicSystem._processWithdraw(smartObjectId, bucketId, item);
      i = unsafe_increment(i);
    }
    if (!useOwnerInventory) {
      storeProxySystem.proxyTransferToEphemeral(smartObjectId, transferrer, transferItems);
    }
  }

  function internalTransfer(
    uint256 smartObjectId,
    bytes32 sourceBucketId,
    bytes32 recipientBucketId,
    InventoryItemParams[] memory transferItems
  ) public {
    if (!storeAuthSystem.canWithdraw(smartObjectId, sourceBucketId, _msgSender())) {
      revert UnauthorizedWithdraw();
    }
    if (!storeAuthSystem.canDeposit(smartObjectId, recipientBucketId, _msgSender())) {
      revert UnauthorizedDeposit();
    }
    // for each item in transferItems, check if the item exists in the BucketedInventoryItem table for the sourceBucketId
    // if it does, transfer the item from the source bucket to the recipient bucket
    // if it doesn't, revert
    for (uint256 i = 0; i < transferItems.length; i++) {
      InventoryItemParams memory item = transferItems[i];
      // check if the item exists in the source bucket
      if (!BucketedInventoryItem.getExists(sourceBucketId, item.smartObjectId)) {
        revert ItemNotFoundInBucket();
      }
      // check if the item exists in the recipient bucket - if it does, update the quantity
      // if it doesn't, create a new entry in the BucketedInventoryItem table for the item in the recipient bucket
      storeLogicSystem._processDeposit(smartObjectId, recipientBucketId, item);
      // check if the item has sufficient quantity in the source bucket
      storeLogicSystem._processWithdraw(smartObjectId, sourceBucketId, item);
    }
  }
}
