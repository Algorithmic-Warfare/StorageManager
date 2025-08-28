pragma solidity ^0.8.24;

import { console } from "forge-std/console.sol";
import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorldWithContext } from "@eveworld/smart-object-framework-v2/src/IWorldWithContext.sol";
import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";
import { CallAccess } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/tables/CallAccess.sol";


contract TestAccessSystem is SmartObjectFramework {
  // This system is used to manage access to the store's bucket.
  // It should adhere to @awar-dev/storage-manager's delegated
  // access control standard (v0.2.0).

  /**
   * @notice Check if the sender can deposit into a bucket (for dex - we want this to be locked down to be true
   * @param smartObjectId The id of the smart object
   * @param bucketId The id of the bucket to check access for
   * @param sender The address of the sender
   * @return bool True if the sender can deposit, false otherwise
   * @dev This function should be called by the test system to check if a deposit is allowed.
   * It should return true if the sender is allowed to deposit into the bucket
   * and false otherwise. The access control logic that calls this should be implemented in the StoreAuthSystem.
   */
  function canDeposit(uint256 smartObjectId, bytes32 bucketId, address sender) public view context returns (bool) {
    // iterate through each of the current world call count - find it's address and log it + if has a system, log the system too
    uint256 currentCallCount = IWorldWithContext(_world()).getWorldCallCount();
    if (currentCallCount < 2) {
      return false;
    }
    // for (uint i = 1; i <= currentCallCount; i++) {
    //   (ResourceId sysid, bytes4 fnid, address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(i);
    //   console.log("Call Context - Index:");
    //   console.logUint(i);
    //   console.log(i);
    //   // Log the address of the system that made the call, it's systemId, selector, and sender and then determine it's name by decodig the ResourceId
    //   // address selectedCallSystemAddress = world.getSystemAddress(selectedCallSystemId);
    //   // console.log("Call Context - System Address:", selectedCallSystemAddress);
    //   // console.log("Call Context - System ID:", selectedCallSystemId);
    //   console.log("Call Context - System Name:");
    //   console.logBytes16(WorldResourceIdInstance.getName(sysid));
    //   console.log(WorldResourceIdInstance.toString(sysid));
    //   // console.log("Call Context - Selector:", selectedCallSelector);
    //   // console.log("Call Context - Sender:", selectedCallSender);
    //   // console.log("Call Context - Value:", selectedCallValue);
    //   console.log("Call Context - Msg Sender:", msgSender);
    // }
    // console.log("Retrying with exact check");
    (, , /*ResourceId sysid, bytes4 fnid, */ address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(
      currentCallCount - 2
    );
    // console.log("Call Context - System Name:");
    // console.logBytes16(WorldResourceIdInstance.getName(sysid));
    // console.log(WorldResourceIdInstance.toString(sysid));
    // // console.log("Call Context - Selector:", selectedCallSelector);
    // // console.log("Call Context - Sender:", selectedCallSender);
    // // console.log("Call Context - Value:", selectedCallValue);
    // console.log("Call Context - Msg Sender:", msgSender);
    // if (msgSender == address(orderbookDexSystem.getAddress())) {
    //   // Allow the test system to deposit into the bucket
    //   return true;
    // }
    return true;
  }

  /**
   * @notice Check if the sender can withdraw from a bucket (for dex - we want this to be locked down to only the test system)
   * @param smartObjectId The id of the smart object
   * @param bucketId The id of the bucket to check access for
   * @param sender The address of the sender
   * @return bool True if the sender can withdraw, false otherwise
   * @dev This function should be called by the test system to check if a withdrawal is allowed.
   * It should return true if the sender is allowed to withdraw from the bucket
   * and false otherwise. The access control logic that calls this should be implemented in the StoreAuthSystem.
   */
  function canWithdraw(uint256 smartObjectId, bytes32 bucketId, address sender) public view context returns (bool) {
    uint256 currentCallCount = IWorldWithContext(_world()).getWorldCallCount();
    if (currentCallCount < 2) {
      return false;
    }
    (ResourceId sysid, bytes4 fnid, address msgSender, ) = IWorldWithContext(_world()).getWorldCallContext(
      currentCallCount - 2
    );
    // if (msgSender == address(orderbookDexSystem.getAddress())) {
    //   // Allow the test system to withdraw from the bucket
    //   return true;
    // }
    return false;
  }

  /**
   * @notice Check if the sender can transfer a bucket to a different parent
   * @param smartObjectId The id of the smart object
   * @param bucketId The id of the bucket to check access for
   * @param sender The address of the sender
   * @return bool True if the sender can transfer the bucket, false otherwise
   * @dev This function should be called by the test system to check if a transfer of the bucket is allowed.
   * It should return false always
   */
  function canTransferBucket(uint256 smartObjectId, bytes32 bucketId, address sender) public pure returns (bool) {
    // Allow no one to transfer buckets except the test system
    return false;
  }
}
