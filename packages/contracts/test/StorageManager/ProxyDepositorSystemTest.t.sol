// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";

import { EphemeralInvItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/EphemeralInvItem.sol";
import { InventoryItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/InventoryItem.sol";
import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { EphemeralInteractSystemLib, ephemeralInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/EphemeralInteractSystemLib.sol";

import { BucketedInventoryItem } from "../../src/codegen/tables/BucketedInventoryItem.sol";
import { storeAuthSystem } from "../../src/codegen/systems/StoreAuthSystemLib.sol";
import { StorageManagerProxyDepositorSystem } from "../mocks/StorageManagerProxyDepositorSystem.sol";
import { TestAccessSystem } from "../mocks/TestAccessSystem.sol";
import { SetupTestWithBucketsTest } from "../SetupTestWithBucketsTest.t.sol";

contract ProxyDepositorSystemTest is SetupTestWithBucketsTest {
  ResourceId private proxySystemId;

  function setUp() public override {
    super.setUp();

    // Deploy and register the proxy depositor system under a dedicated namespace
    vm.startPrank(admin);
    bytes14 NS = "proxy_deposit";
    ResourceId nsRes = WorldResourceIdLib.encodeNamespace(NS);
    try IBaseWorld(worldAddress).registerNamespace(nsRes) {} catch {}

    StorageManagerProxyDepositorSystem proxy = new StorageManagerProxyDepositorSystem();
    proxySystemId = WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: NS, name: "Depositor" });
    IBaseWorld(worldAddress).registerSystem(proxySystemId, proxy, true);

    // Register a permissive access system and set it for this bucket so proxy system can be the caller
    TestAccessSystem access = new TestAccessSystem();
    ResourceId accessSystemId = WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: NS, name: "TestAccessSystem" });
    IBaseWorld(worldAddress).registerSystem(accessSystemId, access, true);
    // Sanity: ensure registry maps to the id
    ResourceId fetched = SystemRegistry.getSystemId(address(access));
    require(ResourceId.unwrap(fetched) == ResourceId.unwrap(accessSystemId), "access id mismatch");
    storeAuthSystem.setAccessSystemId(ssuId, bucketId, accessSystemId);

    // Ensure ephemeral transfer-from is authorized for the store proxy (already done in base), keep as-is
    // ephemeralInteractSystem.setTransferFromEphemeralAccess(ssuId, storeProxySystemAddress, true);

    vm.stopPrank();
  }

  function testProxyDepositFromEphemeral() public {
    // Prepare a small deposit sourced from player's ephemeral inventory
    uint64 qty = 7;
    InventoryItemParams[] memory items = new InventoryItemParams[](1);
    items[0] = InventoryItemParams({ smartObjectId: itemId, quantity: qty });

    uint64 ephBefore = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    uint64 bucketBefore = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    uint64 primaryBefore = uint64(InventoryItem.getQuantity(ssuId, itemId));

    // Call the proxy system via the world to preserve player as _msgSender at the world layer,
    // but StorageSystem will receive this system as the caller, which is allowed by TestAccessSystem.
    vm.startPrank(player);
    IBaseWorld(worldAddress).callFrom(
      player,
      proxySystemId,
      abi.encodeCall(StorageManagerProxyDepositorSystem.depositFromEphemeral, (ssuId, bucketId, items))
    );
    vm.stopPrank();

    uint64 ephAfter = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    uint64 bucketAfter = uint64(BucketedInventoryItem.getQuantity(bucketId, itemId));
    uint64 primaryAfter = uint64(InventoryItem.getQuantity(ssuId, itemId));

    assertEq(ephAfter, ephBefore - qty, "Ephemeral balance should decrease by qty");
    assertEq(bucketAfter, bucketBefore + qty, "Bucket balance should increase by qty");
    assertEq(primaryAfter, primaryBefore + qty, "Primary inventory should increase by qty");
  }
}
