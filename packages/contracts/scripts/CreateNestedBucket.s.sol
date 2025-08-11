import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

contract CreateNestedBucket is Script {
  function run(string bucketName) external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    IWorld world = IWorld(worldAddress);
    address storeProxySystemAddress = world.sm_v0_2_0sm__getStoreProxyAddress();
    if (storeProxySystemAddress == address(0)) {
      revert("StoreProxySystem not registered to the World");
    }
    vm.startBroadcast(deployerPrivateKey);
    uint256[] bucketIds = world.sm_v0_2_0sm__createNestedBuckets(ssuId, bucketName);
    vm.stopBroadcast();
    for (uint256 i = 0; i < bucketIds.length; i++) {
      console.log("Created bucket");
      console.logUint(bucketIds[i]);
    }
  }
}
