pragma solidity ^0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { InventoryBalances } from "../../codegen/tables/InventoryBalances.sol";
import { BucketedInventoryItem, BucketedInventoryItemData } from "../../codegen/tables/BucketedInventoryItem.sol";
import { BucketInventory } from "../../codegen/tables/BucketInventory.sol";

import "./Errors.sol";

contract StoreLogicSystem is System {
  function _processDeposit(uint256 smartObjectId, bytes32 bucketId, InventoryItemParams memory item) external {
    // check if the item exists in the bucket
    if (!BucketedInventoryItem.getExists(bucketId, item.smartObjectId)) {
      uint256 itemIndex = BucketInventory.lengthItems(smartObjectId, bucketId);
      BucketInventory.pushItems(smartObjectId, bucketId, item.smartObjectId);
      BucketedInventoryItem.set(bucketId, item.smartObjectId, true, uint64(item.quantity), uint64(itemIndex));
    } else {
      // update the quantity of the item in the bucket inventory
      uint64 existingQuantity = BucketedInventoryItem.getQuantity(bucketId, item.smartObjectId);
      BucketedInventoryItem.setQuantity(bucketId, item.smartObjectId, existingQuantity + uint64(item.quantity));
    }
  }

  function _processWithdraw(uint256 smartObjectId, bytes32 bucketId, InventoryItemParams memory item) external {
    // check if the item exists in the bucket
    if (!BucketedInventoryItem.getExists(bucketId, item.smartObjectId)) {
      // create a new entry in the BucketedInventoryItem table for the item
      // BucketedInventoryItem.set(bucketId, item.smartObjectId, true, uint64(item.quantity));
      revert ItemNotFoundInBucket(); // if the item does not exist in the bucket, revert as it should have been deposited first before it can be withdrawn
    } else {
      BucketedInventoryItemData memory itemData = BucketedInventoryItem.get(bucketId, item.smartObjectId);
      // update the quantity of the item in the bucket
      if (itemData.quantity < uint64(item.quantity)) {
        revert InsufficientQuantityInSourceBucket();
      }
      if (itemData.quantity == uint64(item.quantity)) {
        // if the quantity is equal to the requested quantity, remove the item from the bucket
        _removeItem(smartObjectId, bucketId, item, itemData);
      } else {
        // if the quantity is greater than the requested quantity, update the quantity in the bucket
        BucketedInventoryItem.setQuantity(bucketId, item.smartObjectId, itemData.quantity - uint64(item.quantity));
      }
    }
  }

  function _processAggBucketsBalance(
    uint256 smartObjectId,
    bytes32 bucketId,
    bool isWithdrawal,
    InventoryItemParams memory item
  ) external {
    if (!InventoryBalances.getExists(smartObjectId, item.smartObjectId)) {
      if (isWithdrawal) {
        revert ItemAggregateNotFound();
      }
      // create a new entry in the InventoryBalances table for the item
      InventoryBalances.set(smartObjectId, item.smartObjectId, true, uint64(item.quantity));
    } else {
      // update the metadata for the item in the bucket
      if (isWithdrawal) {
        uint64 existingMetadataQuantity = InventoryBalances.getQuantity(smartObjectId, item.smartObjectId);
        if (existingMetadataQuantity < uint64(item.quantity)) {
          revert InsufficientQuantityInBucket();
        }
        if (existingMetadataQuantity == uint64(item.quantity)) {
          // if the quantity is equal to the requested quantity, remove the item from the bucket
          InventoryBalances.deleteRecord(smartObjectId, item.smartObjectId);
        } else {
          InventoryBalances.setQuantity(
            smartObjectId,
            item.smartObjectId,
            existingMetadataQuantity - uint64(item.quantity)
          );
        }
      } else {
        InventoryBalances.setQuantity(
          smartObjectId,
          item.smartObjectId,
          InventoryBalances.getQuantity(smartObjectId, item.smartObjectId) + uint64(item.quantity)
        );
      }
    }
  }

  /**
   * @notice Remove an item from a bucket.
   * @param smartObjectId The id of the smart object to remove the item from.
   * @param bucketId The id of the bucket to remove the item from.
   * @param item The item to remove, represented as an InventoryItemParams struct.
   * @param itemData The data of the item in the bucket, represented as a BucketedInventoryItemData struct.
   * @dev This function will remove the item from the bucket and update the
   *      BucketedInventoryItem table accordingly. If the item is the last one in
   *      the bucket, it will be removed completely. If there are more items,
   *      it will swap the last item with the one being removed and pop off
   *      the top of the stack to save gas.
   */
  function _removeItem(
    uint256 smartObjectId,
    bytes32 bucketId,
    InventoryItemParams memory item,
    BucketedInventoryItemData memory itemData
  ) internal {
    uint256 length = BucketInventory.lengthItems(smartObjectId, bucketId);
    // Only perform swap if this isn't the last item (saves gas)
    if (length > 1 && itemData.index < length - 1) {
      uint256 lastElement = BucketInventory.getItemItems(smartObjectId, bucketId, length - 1);
      BucketInventory.updateItems(smartObjectId, bucketId, itemData.index, lastElement);
      BucketedInventoryItem.setIndex(bucketId, lastElement, itemData.index);
    }
    BucketInventory.popItems(smartObjectId, bucketId);
    if (BucketInventory.lengthItems(smartObjectId, bucketId) == 0) {
      // if the bucket is now empty, delete the bucket entry from BucketInventory table
      BucketInventory.deleteRecord(smartObjectId, bucketId);
    }
    BucketedInventoryItem.deleteRecord(bucketId, item.smartObjectId);
  }
}
