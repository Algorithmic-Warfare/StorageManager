pragma solidity >=0.8.24;

import { SmartObjectFramework } from "@eveworld/smart-object-framework-v2/src/inherit/SmartObjectFramework.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { ResourceIds } from "@latticexyz/store/src/codegen/tables/ResourceIds.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { ephemeralInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/EphemeralInteractSystemLib.sol";
import { inventoryInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/InventoryInteractSystemLib.sol";
import { deployableSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/DeployableSystemLib.sol";

contract StoreProxySystem is SmartObjectFramework {
  ResourceId public immutable storageSystemId =
    WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: "sm_v0_2_0", name: "StorageSystem" });
  // This contract is a static proxy that forwards calls to the ephemeralInteractSystem.
  // It is used to allow the StorageSystem to be upgradeable without breaking roles.
  modifier onlyStorageSystem() {
    // This modifier ensures that only the StorageSystem can call the function.
    // It is used to allow the StorageSystem to be upgradeable without breaking roles.

    if (ResourceIds.getExists(storageSystemId)) {
      require(_msgSender() == Systems.getSystem(storageSystemId), "Only StorageSystem can call this function");
    } else {
      // If the StorageSystem is not registered, we allow any caller.
      // This is useful for testing and development purposes.
      revert("StorageSystem not registered");
    }
    _;
  }

  function getStoreProxyAddress() public view returns (address) {
    // This function returns the address of the StoreProxySystem.
    // It is used to allow the StorageSystem to be upgradeable without breaking roles.
    return address(this);
  }

  function proxyTransferToEphemeral(
    uint256 smartObjectId,
    address recipient,
    InventoryItemParams[] memory transferItems
  ) public onlyStorageSystem {
    // This function is used to transfer items to an ephemeral object.
    // It is used to allow for items to be transferred to an ephemeral object.
    return ephemeralInteractSystem.transferToEphemeral(smartObjectId, recipient, transferItems);
  }

  function proxyTransferFromEphemeral(
    uint256 smartObjectId,
    address sender,
    InventoryItemParams[] memory transferItems
  ) public onlyStorageSystem {
    // This function is used to transfer items from an ephemeral object.
    // It is used to allow for items to be transferred from an ephemeral object.
    return ephemeralInteractSystem.transferFromEphemeral(smartObjectId, sender, transferItems);
  }

  function proxyCrossTransferToEphemeral(
    uint256 smartObjectId,
    address fromEphemeralOwner,
    address toEphemeralOwner,
    InventoryItemParams[] memory items
  ) public context onlyStorageSystem {
    // This function is used to transfer items from one ephemeral object to another.
    // It is used to allow for items to be transferred from one ephemeral object to another.
    // return ephemeralInteractSystem.crossTransferToEphemeral(smartObjectId, fromEphemeralOwner, toEphemeralOwner, items);
    // withdraw the items from the designated inventory
    // proxyTransferFromEphemeral(smartObjectId, fromEphemeralOwner, items);
    // deposit the items to the designated ephemeral inventory
    // proxyTransferToEphemeral(smartObjectId, toEphemeralOwner, items);
    ephemeralInteractSystem.crossTransferToEphemeral(smartObjectId, fromEphemeralOwner, toEphemeralOwner, items);
  }

  function proxyTransferToInventory(
    uint256 smartObjectId,
    uint256 toObjectId,
    InventoryItemParams[] memory items
  ) public onlyStorageSystem {
    // This function is used to transfer items to an inventory object.
    // It is used to allow for items to be transferred to an inventory object.
    return inventoryInteractSystem.transferToInventory(smartObjectId, toObjectId, items);
  }
}
