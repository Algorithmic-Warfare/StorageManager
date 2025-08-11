pragma solidity ^0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";

import { BucketMetadataData, BucketMetadata } from "../../codegen/tables/BucketMetadata.sol";
import { BucketOwners } from "../../codegen/tables/BucketOwners.sol";
import { storeAuthSystem } from "../../codegen/systems/StoreAuthSystemLib.sol";

import { Bytes32StringPacker } from "../StringPacker/StringPackerBytes.sol";
import { BucketAlreadyExists, BucketNotFound, InvalidBucketName, ParentBucketNotFound, UnauthorizedBucketTransfer } from "./Errors.sol";
import { MAX_BUCKET_NAME_PARTS } from "./Constants.sol";
import { SharedUtils } from "./utils.sol";

contract BucketSystem is System {
  using Bytes32StringPacker for string;
  using Bytes32StringPacker for bytes32;

  function getCreateSystemAddress() public view returns (address) {
    return address(this);
  }
  /**
   * @notice Create a bucket with a name, which can be nested using `/` as a separator.
   * @param smartObjectId The id of the smart object to create the bucket for.
   * @param bucketName The name of the bucket to create, which can be nested using
   *                   `/` as a separator. For example, `my/bucket/name`.
   * @return bucketIds An array of bucket ids that were created, in the order they
   *                   were created. The first element is the id of the top-level
   *                   bucket, and the last element is the id of the most nested
   *                   bucket.
   * @dev This function will create a bucket for each part of the bucket name,
   *      and will return an array of bucket ids that were created. If a bucket
   *      already exists, it will not be created again, but the existing bucket
   *      id will be returned. If the bucket name is invalid (e.g. too
   *      many parts or empty), it will revert with an error.
   */
  function createNestedBuckets(uint256 smartObjectId, string memory bucketName) public returns (bytes32[] memory) {
    // split bucketName into parts by `/`
    string[] memory bucketParts = bucketName.split("/");
    // check max length for bucket parts <= 5
    if (bucketParts.length == 0 || bucketParts.length > MAX_BUCKET_NAME_PARTS) {
      revert InvalidBucketName();
    }
    // for each bucket part, check if it exists and try to create it if it doesn't
    bytes32[] memory temp = new bytes32[](bucketParts.length);
    uint x = 0;
    for (uint i = 0; i < bucketParts.length; ) {
      // if part is empty, skip it
      string memory bucketNamePart = bucketParts[i];
      if (bytes(bucketNamePart).length == 0) {
        i = SharedUtils.unsafeIncrement(i);
        continue;
      }

      // generate the bucket id deterministically
      bytes32 bucketId = SharedUtils.composeBucketId(smartObjectId, bucketNamePart);
      // check if the bucket already exists.
      // if it already exists and it's owner is not the sender, revert
      BucketMetadataData memory bucketData = BucketMetadata.get(smartObjectId, bucketId);
      if (bucketData.exists && bucketData.owner != _msgSender()) {
        revert BucketAlreadyExists();
      }
      // if bucket already exists and the owner is the sender, continue without creating it
      if (bucketData.exists) {
        // continue to the next bucket part
        temp[x] = bucketId;
        i = SharedUtils.unsafeIncrement(i);
        x = SharedUtils.unsafeIncrement(x);
        continue;
      }
      // if it doesn't, create it
      // get parentBucketId (the previous bucket part id)
      bytes32 parentBucketId = x > 0 ? temp[x - 1] : bytes32(0);
      // set the bucket metadata with the msg sender as the owner
      BucketMetadata.set(smartObjectId, bucketId, bool(true), _msgSender(), parentBucketId, bucketNamePart);
      if (!BucketOwners.getExists(smartObjectId, _msgSender())) {
        // if the owner does not exist, create it
        bytes32[] memory initialBucketIds = new bytes32[](1);
        initialBucketIds[0] = bucketId;
        BucketOwners.set(smartObjectId, _msgSender(), true, initialBucketIds);
      } else {
        // if the owner exists, add the bucketId to the owner's bucketIds
        BucketOwners.pushBucketIds(smartObjectId, _msgSender(), bucketId);
      }
      // add the bucketId to the owner's bucketIds
      // set the bucketIds
      temp[x] = bucketId;
      i = SharedUtils.unsafeIncrement(i);
      x = SharedUtils.unsafeIncrement(x);
    }
    // create a final array of the correct size
    bytes32[] memory bucketIds = new bytes32[](x);
    for (uint z = 0; z < x; ) {
      bucketIds[z] = temp[z];
      z = SharedUtils.unsafeIncrement(z);
    }

    return bucketIds;
  }

  function transferBucketToParent(uint256 smartObjectId, bytes32 bucketId, bytes32 newParentBucketId) public {
    if (!storeAuthSystem.canTransferBucket(smartObjectId, bucketId, _msgSender())) {
      revert UnauthorizedBucketTransfer();
    }

    // check if the bucket exists
    if (!BucketMetadata.getExists(smartObjectId, bucketId)) {
      revert BucketNotFound(smartObjectId, bucketId);
    }
    // check if the parent bucket exists
    if (!BucketMetadata.getExists(smartObjectId, newParentBucketId)) {
      revert ParentBucketNotFound(smartObjectId, newParentBucketId);
    }
    // transfer all items from the bucket to the parent bucket
    BucketMetadata.setParentBucketId(smartObjectId, bucketId, newParentBucketId);
  }
}
