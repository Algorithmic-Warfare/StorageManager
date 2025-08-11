// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { BalanceSystem } from "../src/systems/StorageSystem/BalanceSystem.sol";
import { MyToken } from "./testtoken.sol";
contract GetBalance is Script {
  MyToken public token;

  function createAnERC20Token() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    // deploy an ERC20 token contract
    vm.startBroadcast(deployerPrivateKey);
    token = new MyToken(1_000_000 ether);
    vm.stopBroadcast();
  }

  function run() external {
    this.createAnERC20Token();
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    // Allow the MUD table calls to be used in the following tests.
    StoreSwitch.setStoreAddress(worldAddress);
    console.log("token address: ", address(token));
    // Setup to use MUD system calls in the following tests.
    IWorld world = IWorld(worldAddress);
    vm.startPrank(vm.addr(deployerPrivateKey));
    uint startGas = gasleft();
    // console.log("Starting gas: ", startGas);
    // uint256 totalSupply = world.sm_v0_2_0sm__getTokenSupply(address(token));
    uint256 balance = world.sm_v0_2_0sm__getSystemBalance(address(token));
    console.log("Balance of system: ");
    console.logUint(balance);
    vm.stopPrank();
  }
}
