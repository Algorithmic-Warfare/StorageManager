pragma solidity >=0.8.24;

import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { CharactersByAccount } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/CharactersByAccount.sol";
import { Characters } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/Characters.sol";
import { IWorldWithContext } from "@eveworld/smart-object-framework-v2/src/IWorldWithContext.sol";

import { BucketConfig } from "../../codegen/tables/BucketConfig.sol";
import { BucketMetadata } from "../../codegen/tables/BucketMetadata.sol";

import "./Errors.sol";

contract StoreAuthSystem is System {
  modifier onlyBucketOwner(uint256 smartObjectId, bytes32 bucketId) {
    address sender = _msgSender();
    address bucketOwner = BucketMetadata.getOwner(smartObjectId, bucketId);
    if (sender != bucketOwner) {
      revert NotBucketOwner();
    }
    _;
  }

  /**
   * @notice Set the access system for a bucket by id
   * @param bucketId The id of the bucket to set the access system for
   * @param systemId The id of the system to set as the access system. this will be called to deterimine if a withdraw or deposit is allowed
   */
  function setAccessSystemId(
    uint256 smartObjectId,
    bytes32 bucketId,
    ResourceId systemId
  ) public onlyBucketOwner(smartObjectId, bucketId) {
    BucketConfig.setAccessSystemId(bucketId, systemId);
  }

  function getCharacterTribeByAddress(address playerAddress) public view returns (uint256) {
    uint256 characterId = CharactersByAccount.getSmartObjectId(playerAddress);
    if (characterId == uint256(0)) {
      revert CharacterNotFound();
    }
    uint256 characterTribeId = Characters.getTribeId(characterId);
    if (characterTribeId == uint256(0)) {
      revert CharacterNotInTribe();
    }
    return characterTribeId;
  }

  function fetchAuthorizationSystemId(uint256 smartObjectId, bytes32 bucketId) public view returns (ResourceId) {
    ResourceId accessSystemId = BucketConfig.getAccessSystemId(bucketId);
    // if accessSystemId exists, return it
    if (accessSystemId.unwrap() != bytes32(0) && ResourceIds.getExists(accessSystemId)) {
      return accessSystemId;
    }
    // else check parent bucket id and recurse until we find a bucket with an access system or we reach the root
    bytes32 parentBucketId = BucketMetadata.getParentBucketId(smartObjectId, bucketId);
    if (parentBucketId != bytes32(0)) {
      return fetchAuthorizationSystemId(smartObjectId, parentBucketId);
    }
    return ResourceId.wrap(0);
  }

  /**
   * @notice   Check if a sender can deposit into a bucket. If the bucket has no access system,
   *           it will look at it's parent bucket id that system to check if parent has a system and
   *           so on until the parentBucketId is empty
   * @param smartObjectId The id of the smart object the bucket belongs to.
   * @param bucketId The id of the bucket to check.
   * @param sender The address of the sender to check.
   * @return bool True if the sender can deposit into the bucket, false otherwise.
   *
   */
  function canDeposit(uint256 smartObjectId, bytes32 bucketId, address sender) public returns (bool) {
    ResourceId accessSystemId = BucketConfig.getAccessSystemId(bucketId);
    // if depositSystemId exists, call it
    if (accessSystemId.unwrap() != bytes32(0) && ResourceIds.getExists(accessSystemId)) {
      bytes memory returnData = getWorld().call(
        accessSystemId,
        abi.encodeCall(this.canDeposit, (smartObjectId, bucketId, sender))
      );
      return abi.decode(returnData, (bool));
    }
    // else check if the sender is in the same tribe as the bucket owner
    address bucketOwner = BucketMetadata.getOwner(smartObjectId, bucketId);
    if (getCharacterTribeByAddress(bucketOwner) == getCharacterTribeByAddress(sender)) {
      return true;
    }
    return false;
  }

  function canWithdraw(uint256 smartObjectId, bytes32 bucketId, address sender) public returns (bool) {
    ResourceId accessSystemId = BucketConfig.getAccessSystemId(bucketId);
    // if accessSystemId exists, call it
    if (accessSystemId.unwrap() != bytes32(0) && ResourceIds.getExists(accessSystemId)) {
      bytes memory returnData = getWorld().call(
        accessSystemId,
        abi.encodeCall(this.canWithdraw, (smartObjectId, bucketId, sender))
      );
      return abi.decode(returnData, (bool));
    }
    // else check if the sender is in the same tribe as the bucket owner
    address bucketOwner = BucketMetadata.getOwner(smartObjectId, bucketId);
    if (getCharacterTribeByAddress(bucketOwner) == getCharacterTribeByAddress(sender)) {
      return true;
    }
    return false;
  }

  function canTransferBucket(uint256 smartObjectId, bytes32 bucketId, address sender) public returns (bool) {
    ResourceId accessSystemId = BucketConfig.getAccessSystemId(bucketId);
    // if accessSystemId exists, call it
    if (accessSystemId.unwrap() != bytes32(0) && ResourceIds.getExists(accessSystemId)) {
      bytes memory returnData = getWorld().call(
        accessSystemId,
        abi.encodeCall(this.canTransferBucket, (smartObjectId, bucketId, sender))
      );
      return abi.decode(returnData, (bool));
    }
    // else check if the sender is the same as the owner of the bucket
    if (sender == BucketMetadata.getOwner(smartObjectId, bucketId)) {
      return true;
    }
    return false;
  }

  function getWorld() internal view returns (IWorldWithContext) {
    return IWorldWithContext(_world());
  }
}
