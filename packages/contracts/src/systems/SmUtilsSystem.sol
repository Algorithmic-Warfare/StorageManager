pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Inventory } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/Inventory.sol";
import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { InventoryItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/InventoryItem.sol";
import { EphemeralInventory } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/EphemeralInventory.sol";
import { EphemeralInvItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/EphemeralInvItem.sol";

import { InventoryBalances } from "../codegen/tables/InventoryBalances.sol";
import { storeAuthSystem } from "../codegen/systems/StoreAuthSystemLib.sol";
import { BucketMetadata, BucketMetadataData } from "../codegen/tables/BucketMetadata.sol";
import { BucketOwners } from "../codegen/tables/BucketOwners.sol";
import { BucketInventory } from "../codegen/tables/BucketInventory.sol";
import { BucketedInventoryItem } from "../codegen/tables/BucketedInventoryItem.sol";

import { Bytes32StringPacker } from "./StringPacker/StringPackerBytes.sol";
import { SharedUtils, BucketMetadataWithId } from "./StorageSystem/utils.sol";

contract SmUtilsSystem is System {
  using Bytes32StringPacker for string;

  function deriveBucketId(uint256 smartObjectId, string memory bucketName) public pure returns (bytes32) {
    return bytes32(keccak256(abi.encode(smartObjectId, bucketName.pack())));
  }

  function getPrimaryInventoryOwnerItems(
    uint256 smartObjectId,
    address owner
  ) public view returns (InventoryItemParams[] memory) {
    uint256[] memory items = Inventory.getItems(smartObjectId);
    InventoryItemParams[] memory temp = new InventoryItemParams[](items.length);
    uint256 count = 0;

    for (uint256 i = 0; i < items.length; i++) {
      uint256 primaryInventoryQuantity = InventoryItem.getQuantity(smartObjectId, items[i]);
      if (primaryInventoryQuantity > 0) {
        uint256 bucketInventoryItem = InventoryBalances.getQuantity(smartObjectId, items[i]);
        if (primaryInventoryQuantity - bucketInventoryItem == 0) {
          continue;
        }
        temp[count] = InventoryItemParams({
          smartObjectId: items[i],
          quantity: primaryInventoryQuantity - bucketInventoryItem
        });
        count++;
      }
    }

    // Now copy the exact-sized array
    InventoryItemParams[] memory ownerInventoryItems = new InventoryItemParams[](count);
    for (uint256 j = 0; j < count; j++) {
      ownerInventoryItems[j] = temp[j];
    }

    return ownerInventoryItems;
  }

  function getEphemeralInventoryItems(
    uint256 smartObjectId,
    address owner
  ) public view returns (InventoryItemParams[] memory) {
    uint256[] memory items = EphemeralInventory.getItems(smartObjectId, owner);
    InventoryItemParams[] memory temp = new InventoryItemParams[](items.length);
    uint256 count = 0;

    for (uint256 i = 0; i < items.length; i++) {
      uint256 ephemeralInventoryQuantity = EphemeralInvItem.getQuantity(smartObjectId, owner, items[i]);
      if (ephemeralInventoryQuantity > 0) {
        temp[count] = InventoryItemParams({ smartObjectId: items[i], quantity: ephemeralInventoryQuantity });
        count++;
      }
    }

    // Now copy the exact-sized array
    InventoryItemParams[] memory ephemeralInventoryItems = new InventoryItemParams[](count);
    for (uint256 j = 0; j < count; j++) {
      ephemeralInventoryItems[j] = temp[j];
    }

    return ephemeralInventoryItems;
  }

  function getBucketInventoryItems(
    uint256 smartObjectId,
    bytes32 bucketId
  ) public view returns (InventoryItemParams[] memory) {
    uint256[] memory items = BucketInventory.getItems(smartObjectId, bucketId);
    InventoryItemParams[] memory temp = new InventoryItemParams[](items.length);
    uint256 count = 0;

    for (uint256 i = 0; i < items.length; i++) {
      uint256 bucketInventoryQuantity = BucketedInventoryItem.getQuantity(bucketId, items[i]);
      if (bucketInventoryQuantity > 0) {
        temp[count] = InventoryItemParams({ smartObjectId: items[i], quantity: bucketInventoryQuantity });
        count++;
      }
    }

    // Now copy the exact-sized array
    InventoryItemParams[] memory bucketInventoryItems = new InventoryItemParams[](count);
    for (uint256 j = 0; j < count; j++) {
      bucketInventoryItems[j] = temp[j];
    }

    return bucketInventoryItems;
  }

  function getBucketsMetadata(
    uint256 smartObjectId,
    bytes32[] memory bucketIds
  ) public view returns (BucketMetadataData[] memory) {
    BucketMetadataData[] memory bucketsMetadata = new BucketMetadataData[](bucketIds.length);
    for (uint i = 0; i < bucketIds.length; i++) {
      BucketMetadataData memory bucketMetadata = BucketMetadata.get(smartObjectId, bucketIds[i]);
      bucketsMetadata[i] = BucketMetadataData({
        exists: bucketMetadata.exists,
        owner: bucketMetadata.owner,
        parentBucketId: bucketMetadata.parentBucketId,
        name: bucketMetadata.name
      });
    }
    return bucketsMetadata;
  }

  function getBatchCanDeposit(
    uint256 smartObjectId,
    bytes32[] memory bucketIds,
    address sender
  ) public returns (bool[] memory) {
    bool[] memory results = new bool[](bucketIds.length);
    for (uint256 i = 0; i < bucketIds.length; i++) {
      results[i] = storeAuthSystem.canDeposit(smartObjectId, bucketIds[i], sender);
    }
    return results;
  }
  function getBatchCanWithdraw(
    uint256 smartObjectId,
    bytes32[] memory bucketIds,
    address sender
  ) public returns (bool[] memory) {
    bool[] memory results = new bool[](bucketIds.length);
    for (uint256 i = 0; i < bucketIds.length; i++) {
      results[i] = storeAuthSystem.canWithdraw(smartObjectId, bucketIds[i], sender);
    }
    return results;
  }

  function getOwnerBalance(uint256 smartObjectId, uint256 itemId) public view returns (uint256) {
    if (!InventoryItem.getExists(smartObjectId, itemId)) {
      return uint256(0);
    }
    uint64 storageSystemAccountedQuantity = InventoryBalances.getQuantity(smartObjectId, itemId);
    uint256 primaryInvBalance = InventoryItem.getQuantity(smartObjectId, itemId);
    return primaryInvBalance - uint256(storageSystemAccountedQuantity);
  }

  /**
   * Retrieves the bucket IDs owned by a specific owner for a given smart object.
   * @param smartObjectId The ID of the smart object.
   * @param owner The address of the owner whose bucket IDs are to be retrieved.
   * @return An array of bucket IDs owned by the specified owner.
   */
  function getBucketsByOwnerAtSSU(uint256 smartObjectId, address owner) public view returns (bytes32[] memory) {
    return BucketOwners.getBucketIds(smartObjectId, owner);
  }

  function getBucketMetadata(
    uint256 smartObjectId,
    bytes32 bucketId
  ) public view returns (BucketMetadataWithId memory) {
    BucketMetadataData memory bucketMetadata = BucketMetadata.get(smartObjectId, bucketId);
    return
      BucketMetadataWithId({
        bucketId: bucketId,
        exists: bucketMetadata.exists,
        owner: bucketMetadata.owner,
        parentBucketId: bucketMetadata.parentBucketId,
        name: bucketMetadata.name
      });
  }

  function getBucketMetadataChain(
    uint256 smartObjectId,
    bytes32 bucketId
  ) public view returns (BucketMetadataWithId[] memory) {
    // recursively get bucket metadata up to the root by following parentBucketId
    BucketMetadataWithId[] memory temp = new BucketMetadataWithId[](10); // max depth
    uint256 maxDepth = 6;
    uint256 count = 0;
    bytes32 currentBucketId = bucketId;
    while (currentBucketId != bytes32(0) && count < maxDepth) {
      BucketMetadataData memory bucketMetadata = BucketMetadata.get(smartObjectId, currentBucketId);
      if (!bucketMetadata.exists) {
        break;
      }
      temp[count] = BucketMetadataWithId({
        bucketId: currentBucketId,
        exists: bucketMetadata.exists,
        owner: bucketMetadata.owner,
        parentBucketId: bucketMetadata.parentBucketId,
        name: bucketMetadata.name
      });
      currentBucketId = bucketMetadata.parentBucketId;
      count++;
    }
    // Now copy the exact-sized array
    BucketMetadataWithId[] memory bucketMetadataChain = new BucketMetadataWithId[](count);
    for (uint256 j = 0; j < count; j++) {
      bucketMetadataChain[j] = temp[j];
    }
    return bucketMetadataChain;
  }

  function getBucketMetadataChainByName(
    uint256 smartObjectId,
    string memory bucketName
  ) public view returns (BucketMetadataWithId[] memory) {
    // compose bucketId by name
    bytes32 bucketId = SharedUtils.composeBucketId(smartObjectId, bucketName);
    return getBucketMetadataChain(smartObjectId, bucketId);
  }
}
