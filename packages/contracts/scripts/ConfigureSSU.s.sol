import { Script } from "forge-std/Script.sol";

import { ephemeralInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/EphemeralInteractSystemLib.sol";
import { inventoryInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/InventoryInteractSystemLib.sol";
import { ownershipSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/OwnershipSystemLib.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

contract ConfigureSSU is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    bool configureAsImmutable = vm.envBool("CONFIGURE_AS_IMMUTABLE");
    IWorld world = IWorld(worldAddress);
    address storeProxySystemAddress = world.sm_v0_2_0sm__getStoreProxyAddress();
    if (storeProxySystemAddress == address(0)) {
      revert("StoreProxySystem not registered to the World");
    }
    vm.startBroadcast(deployerPrivateKey);
    ephemeralInteractSystem.setTransferFromEphemeralAccess(ssuId, storeProxySystemAddress, true);
    ephemeralInteractSystem.setTransferToEphemeralAccess(ssuId, storeProxySystemAddress, true);
    ephemeralInteractSystem.setCrossTransferToEphemeralAccess(ssuId, storeProxySystemAddress, true);
    inventoryInteractSystem.setTransferFromInventoryAccess(ssuId, storeProxySystemAddress, true);
    inventoryInteractSystem.setTransferToInventoryAccess(ssuId, storeProxySystemAddress, true);
    vm.stopBroadcast();
    // Optionally make the SSU immutable by transferring ownership to the StoreProxySystem
    // @todo: re-enable this once we have a way to reassign ownership of the SSU
    // if (configureAsImmutable) {
    //   ownershipSystem.assignOwner(ssuId, storeProxySystemAddress);
    // }
  }
}

