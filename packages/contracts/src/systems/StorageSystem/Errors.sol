// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/** Permissions */
error UnauthorizedWithdraw();
error UnauthorizedDeposit();
error UnauthorizedBucketTransfer();

error NotBucketOwner();
error UnauthorizedDepositFromOwnerInventory();

error BucketAlreadyExists();
/** Errors */
error CharacterNotFound();
error CharacterNotInTribe();
error ItemNotFoundInBucket(); // Item not found in the specified bucket when it's expected to be there
error InvalidBucketName();
error ParentBucketNotFound(uint256 smartObjectId, bytes32 parentBucketId);
error BucketNotFound(uint256 smartObjectId, bytes32 bucketId);
error InsufficientQuantityInBucket();
error InsufficientQuantityInOwnerInventory();
error ItemAggregateNotFound();

/** Internal Transfers or withdraws*/
error InsufficientQuantityInSourceBucket();
