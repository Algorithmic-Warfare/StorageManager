pragma solidity ^0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { HasRole } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/tables/HasRole.sol";
import { ownershipSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/OwnershipSystemLib.sol";
contract AccessUtilsSystem is System {
    function hasRoles(bytes32[] memory roleIds, address account) public view returns (bool[] memory) {
        bool[] memory results = new bool[](roleIds.length);
        for (uint256 i = 0; i < roleIds.length; i++) {
            results[i] = HasRole.getIsMember(roleIds[i], account);
        }
        return results;
    }

    function getOwnersOf(uint256[] memory smartObjectIds) public view returns (address[] memory) {
        address[] memory owners = new address[](smartObjectIds.length);
        for (uint256 i = 0; i < smartObjectIds.length; i++) {
            owners[i] = ownershipSystem.owner(smartObjectIds[i]);
        }
        return owners;
    }
}