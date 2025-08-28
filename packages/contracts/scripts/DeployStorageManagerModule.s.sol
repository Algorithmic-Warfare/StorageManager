// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { StorageManagerModule } from "../src/StorageManagerModule.sol";

contract DeployStorageManagerModule is Script {
  function run() external {
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    vm.startBroadcast(deployerPrivateKey);

    console.log("Deploying StorageManagerModule...");
    StorageManagerModule module = new StorageManagerModule();
    console.log("StorageManagerModule deployed at:", address(module));

    console.log("Installing module into World (root)...");
    IWorld(worldAddress).installRootModule(module, bytes(""));
    console.log("Module installed.");

    vm.stopBroadcast();

    // Verify installation
    address installedModule = IWorld(worldAddress).getModuleAddress(keccak256(abi.encodePacked("StorageManagerModule")));
    require(installedModule == address(module), "Module installation failed");
    console.log("Verified module installation at:", installedModule);
  }
}
