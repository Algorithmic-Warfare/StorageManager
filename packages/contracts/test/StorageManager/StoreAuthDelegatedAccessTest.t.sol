// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { SetupTestWithBucketsTest } from "../SetupTestWithBucketsTest.t.sol";
import { storeAuthSystem } from "../../src/codegen/systems/StoreAuthSystemLib.sol";
import { BucketMetadata } from "../../src/codegen/tables/BucketMetadata.sol";
import { TestAccessSystem } from "../mocks/TestAccessSystem.sol";

contract StoreAuthDelegatedAccessTest is SetupTestWithBucketsTest {
  // Use a dedicated test namespace to avoid ownership issues
  bytes14 constant TEST_NS = "test_access";

  function setUp() public override {
    super.setUp();
    // Ensure test namespace exists (idempotent)
    ResourceId nsRes = WorldResourceIdLib.encodeNamespace(TEST_NS);
    vm.startPrank(admin);
    try IBaseWorld(worldAddress).registerNamespace(nsRes) {
      // namespace registered
    } catch {
      // already registered; continue
    }

    // Deploy custom access system
    TestAccessSystem access = new TestAccessSystem();

    // Register the system under the test namespace
    ResourceId accessSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: TEST_NS,
      name: "TestAccessSystem"
    });

    IBaseWorld(worldAddress).registerSystem(accessSystemId, access, true);
    vm.stopPrank();

    // Validate registry mapping and set on the target bucket
    ResourceId fetchedId = SystemRegistry.getSystemId(address(access));
    assertEq(ResourceId.unwrap(fetchedId), ResourceId.unwrap(accessSystemId), "SystemRegistry id mismatch");

    // Only bucket owner (admin) can set the access system id
    vm.startPrank(admin);
    storeAuthSystem.setAccessSystemId(ssuId, bucketId, accessSystemId);
    vm.stopPrank();

    // Now canDeposit/canWithdraw should be delegated to TestAccessSystem, which returns true
    bool canDep = storeAuthSystem.canDeposit(ssuId, bucketId, player);
    assertTrue(canDep, "Expected delegated canDeposit to return true");

    bool canW = storeAuthSystem.canWithdraw(ssuId, bucketId, player);
    assertFalse(canW, "Expected delegated canWithdraw to return false since TestAccessSystem is a drop-only system");

    // canTransferBucket is delegated and returns false in TestAccessSystem
    bool canTransfer = storeAuthSystem.canTransferBucket(ssuId, bucketId, player);
    assertFalse(canTransfer, "Expected delegated canTransferBucket to return false");
  }

  function testProxyTransferSystem() public {
    

    
  }
}
