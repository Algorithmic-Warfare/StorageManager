pragma solidity ^0.8.24;

import { Bytes32StringPacker } from "../StringPacker/StringPackerBytes.sol";

// Create a struct that wraps BucketMetadataData and adds bucketId
struct BucketMetadataWithId {
  bytes32 bucketId;
  bool exists;
  address owner;
  bytes32 parentBucketId;
  string name;
}
library SharedUtils {
  using Bytes32StringPacker for string;
  using Bytes32StringPacker for bytes32;

  function composeBucketId(uint256 smartObjectId, string memory bucketName) public pure returns (bytes32) {
    return bytes32(keccak256(abi.encode(smartObjectId, bucketName.pack())));
  }

  function unsafeIncrement(uint i) public pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }
}
