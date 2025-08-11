// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { console } from "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { Script } from "forge-std/Script.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { UNLIMITED_DELEGATION } from "@latticexyz/world/src/constants.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_NAMESPACE, RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { ownershipSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/OwnershipSystemLib.sol";
import { AccessSystemLib, accessSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/AccessSystemLib.sol";
import { InventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { IBaseWorld } from "@eveworld/world-v2/src/codegen/world/IWorld.sol";
import { SmartCharacterSystem, smartCharacterSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/SmartCharacterSystemLib.sol";
import { Location, LocationData } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/Location.sol";
import { DeployableState } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/DeployableState.sol";
import { FuelSystem, fuelSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/FuelSystemLib.sol";
import { FuelParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/fuel/types.sol";
import { SmartAssemblySystem, smartAssemblySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/SmartAssemblySystemLib.sol";
import { EntityRecordParams, EntityMetadataParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/entity-record/types.sol";
import { Tenant, Characters, CharactersByAccount, EntityRecord } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/index.sol";
import { SmartStorageUnitSystem, smartStorageUnitSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/SmartStorageUnitSystemLib.sol";
import { CreateAndAnchorParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/deployable/types.sol";
import { DeployableSystem, deployableSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/DeployableSystemLib.sol";
import { ObjectIdLib } from "@eveworld/world-v2/src/namespaces/evefrontier/libraries/ObjectIdLib.sol";
import { State } from "@eveworld/world-v2/src/codegen/common.sol";
import { InventorySystem, inventorySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/InventorySystemLib.sol";
import { EphemeralInventorySystem, ephemeralInventorySystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/EphemeralInventorySystemLib.sol";
import { EphemeralInteractSystemLib, ephemeralInteractSystem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/systems/EphemeralInteractSystemLib.sol";

import { CreateInventoryItemParams } from "@eveworld/world-v2/src/namespaces/evefrontier/systems/inventory/types.sol";
import { InventoryItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/InventoryItem.sol";
import { EphemeralInvItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/EphemeralInvItem.sol";

import { BucketMetadata } from "../../src/codegen/tables/BucketMetadata.sol";
import { BucketConfig } from "../../src/codegen/tables/BucketConfig.sol";
import { InventoryBalances } from "../../src/codegen/tables/InventoryBalances.sol";
import { BucketedInventoryItem } from "../../src/codegen/tables/BucketedInventoryItem.sol";

/** DELETE */
import { Entity } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/tables/Entity.sol";
import { OwnershipByObject } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/OwnershipByObject.sol";
/** DELETE */

import { IWorld } from "@world/IWorld.sol";
import { SetupTest } from "../SetupTest.t.sol";
import "@systems/StorageSystem/Errors.sol";
import { BucketMetadata } from "../../src/codegen/tables/BucketMetadata.sol";

contract StoreProxy is SetupTest {
  address private assignee = address(2);
  address private nonAuthorized = address(3);
  uint256 ssuId;
  //Smart Gate IDs
  bytes32 tenantId;

  address admin = address(vm.addr(vm.envUint("PRIVATE_KEY")));
  address player = address(1);
  address unauthorizedPlayer = address(3);

  uint256 itemId;
  uint256 itemTypeId;

  uint256 smartStorageUnitId = 1246;
  uint256 smartStorageUnitSmartId;

  uint64 STARTING_INV_ITEM_QUANTITY = 100;
  uint64 STARTING_EPH_ITEM_QUANTITY = 100;

  uint256 CHARACTER_TYPE_ID = 42000000100;
  uint256 SSU_TYPE_ID = 77917;
  uint256 FUEL_TYPE_ID = 78437;

  address storageManagerSystem;

  function setUp() public override {
    super.setUp();

    // world = IWorld(worldAddress);
    // StoreSwitch.setStoreAddress(worldAddress);
    // Load the current world address from the `.env`.
    // worldAddress = vm.envAddress("WORLD_ADDRESS");

    // // Allow the MUD table calls to be used in the following tests.
    // StoreSwitch.setStoreAddress(worldAddress);

    // // Setup to use MUD system calls in the following tests.
    // world = IWorld(worldAddress);

    // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // admin = vm.addr(deployerPrivateKey);
    tenantId = Tenant.getTenantId();
    // player = address(1); // setting the address to the system contract as prank does not work for subsequent calls in world() calls
    // unauthorizedPlayer = address(3); // another player for testing unauthorized access
    // itemId = vm.envUint("ITEM_ID");
    itemTypeId = vm.envUint("ITEM_TYPE_ID");
    storageManagerSystem = address(world.sm_v0_2_0__getSystemAddress());
    vm.startPrank(player, admin);
    safeCreateCharacter(admin, 1, 7777, "adminCharacter");
    safeCreateCharacter(player, 2, 7777, "playerCharacter");
    vm.stopPrank();
    vm.startPrank(unauthorizedPlayer, admin);
    safeCreateCharacter(unauthorizedPlayer, 3, 7778, "unauthorizedCharacter");
    vm.stopPrank();

    // Add delegation setup
    vm.startPrank(player);
    world.registerDelegation(admin, UNLIMITED_DELEGATION, new bytes(0));
    vm.stopPrank();

    ssuId = ObjectIdLib.calculateObjectId(tenantId, 1245);

    // console.log("Creating and anchoring smart storage unit");
    vm.startPrank(admin);

    if (DeployableState.getCurrentState(ssuId) == State.NULL) {
      createAnchorAndOnline(ssuId, admin);
    }
    // console.log("Smart storage unit created and anchored");

    if (!Entity.getExists(ssuId)) {
      revert("invalid ssuId");
    }

    // Ensure the smartObjectId is an ownership assigned object
    if (OwnershipByObject.getAccount(ssuId) == address(0)) {
      revert("invalid smartobject owner");
    }
    // console.log("Generating smartObjectId for item");
    //Create and deposit inventory items
    itemId = ObjectIdLib.calculateObjectId(tenantId, itemTypeId);
    // console.log("Creating and depositing inventory items");

    CreateInventoryItemParams[] memory items = new CreateInventoryItemParams[](1);

    items[0] = CreateInventoryItemParams({
      smartObjectId: itemId,
      tenantId: tenantId,
      typeId: itemTypeId,
      itemId: 0,
      quantity: STARTING_INV_ITEM_QUANTITY,
      volume: 10
    });

    vm.startPrank(admin, admin);
    inventorySystem.createAndDepositInventory(ssuId, items);
    vm.stopPrank();

    CreateInventoryItemParams[] memory itemsTwo = new CreateInventoryItemParams[](1);

    itemsTwo[0] = CreateInventoryItemParams({
      smartObjectId: itemId,
      tenantId: tenantId,
      typeId: itemTypeId,
      itemId: 0,
      quantity: STARTING_EPH_ITEM_QUANTITY,
      volume: 10
    });

    // console.log("Creating and depositing ephemeral items");

    vm.startPrank(player, admin);
    uint64 ephBalanceBefore = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    ephemeralInventorySystem.createAndDepositEphemeral(ssuId, player, itemsTwo);
    uint64 ephBalanceAfter = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    assertEq(ephBalanceBefore, 0, "Expected ephemeral inventory balance to be 0 before deposit");
    assertEq(
      ephBalanceAfter,
      STARTING_EPH_ITEM_QUANTITY,
      "Expected ephemeral inventory balance to be 100 after deposit"
    );
    vm.stopPrank();
  }

  function safeCreateCharacter(address account, uint256 characterId, uint256 tribeId, string memory name) private {
    uint256 someChar = ObjectIdLib.calculateObjectId(tenantId, characterId);

    if (CharactersByAccount.get(account) == 0) {
      smartCharacterSystem.createCharacter(
        someChar,
        account,
        tribeId,
        EntityRecordParams({ tenantId: tenantId, typeId: CHARACTER_TYPE_ID, itemId: characterId, volume: 100 }),
        EntityMetadataParams({ name: name, dappURL: "noURL", description: "." })
      );
    }
  }

  function createAnchorAndOnline(uint256 smartStructureId, address ownerAddress) private {
    LocationData memory locationParams = LocationData({ solarSystemId: 1, x: 1001, y: 1001, z: 1001 });

    EntityRecordParams memory entityRecordParams = EntityRecordParams({
      tenantId: tenantId,
      typeId: SSU_TYPE_ID,
      itemId: 1245,
      volume: 1000
    });

    CreateAndAnchorParams memory deployableParams = CreateAndAnchorParams({
      smartObjectId: smartStructureId,
      assemblyType: "SSU",
      entityRecordParams: entityRecordParams,
      owner: ownerAddress,
      locationData: locationParams
    });

    vm.startPrank(admin, admin);

    world.callFrom(
      ownerAddress,
      smartStorageUnitSystem.toResourceId(),
      abi.encodeCall(
        SmartStorageUnitSystem.createAndAnchorStorageUnit,
        (deployableParams, 100000000, 100000000, 100000000)
      )
    );

    uint256 fuelSmartObjectId = ObjectIdLib.calculateObjectId(tenantId, FUEL_TYPE_ID);

    vm.stopPrank();

    // Set up fuel parameters, deposit fuel, and bring online
    vm.startPrank(admin);
    fuelSystem.configureFuelParameters(
      ssuId,
      FuelParams({ fuelMaxCapacity: 100000000, fuelBurnRateInSeconds: 100000000 })
    );
    fuelSystem.depositFuel(ssuId, fuelSmartObjectId, 1000);
    deployableSystem.bringOnline(ssuId);
    vm.stopPrank();
  }

// @todo: re-enable when ownership transfer is supported for generalized object owner
//   function testTransferOwner() public {
//     vm.pauseGasMetering();
//     vm.startPrank(admin);
//     address currentOwner = OwnershipByObject.getAccount(ssuId);
//     assertEq(currentOwner, admin, "Expected current owner to be admin");
//     vm.resumeGasMetering();
//     // Transfer ownership to assignee
//     ownershipSystem.assignOwner(ssuId, player);
//     vm.pauseGasMetering();
//     // Verify new owner
//     address newOwner = OwnershipByObject.getAccount(ssuId);
//     assertEq(newOwner, player, "Expected new owner to be player");
//     vm.stopPrank();
//   }
}
