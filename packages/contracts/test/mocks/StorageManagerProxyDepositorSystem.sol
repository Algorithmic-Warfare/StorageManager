// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";

import { storageSystem } from "../../src/codegen/systems/StorageSystemLib.sol";


// A simple system that owns interactions with StorageManager by proxying deposits
// to the underlying StorageSystem. This allows buckets to delegate access to this
// system ID and gate who can initiate deposits via StoreAuthSystem policies.
contract StorageManagerProxyDepositorSystem is System {
  // Deposit items sourced from the caller's ephemeral inventory into a bucket
  function depositFromEphemeral(
    uint256 smartObjectId,
    bytes32 bucketId,
    InventoryItemParams[] memory items
  ) public {
    storageSystem.deposit(smartObjectId, bucketId, false, items);
  }

  // Deposit items sourced from the owner's primary inventory into a bucket
  // Caller must be the owner of the smartObjectId per StorageSystem checks
  function depositFromOwner(
    uint256 smartObjectId,
    bytes32 bucketId,
    InventoryItemParams[] memory items
  ) public {
    storageSystem.deposit(smartObjectId, bucketId, true, items);
  }
}
