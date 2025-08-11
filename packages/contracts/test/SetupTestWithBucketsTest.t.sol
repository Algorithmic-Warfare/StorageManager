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

import { BucketMetadata } from "../src/codegen/tables/BucketMetadata.sol";
import { BucketConfig } from "../src/codegen/tables/BucketConfig.sol";
import { InventoryBalances } from "../src/codegen/tables/InventoryBalances.sol";
import { BucketedInventoryItem } from "../src/codegen/tables/BucketedInventoryItem.sol";
import { StoreProxySystemLib, storeProxySystem } from "../src/codegen/systems/StoreProxySystemLib.sol";
import { accessUtilsSystem } from "../src/codegen/systems/AccessUtilsSystemLib.sol";

/** DELETE */
import { Entity } from "@eveworld/smart-object-framework-v2/src/namespaces/evefrontier/codegen/tables/Entity.sol";
import { OwnershipByObject } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/OwnershipByObject.sol";
/** DELETE */

import { IWorld } from "@world/IWorld.sol";
import { SetupTest } from "./SetupTest.t.sol";
import "@systems/StorageSystem/Errors.sol";
import { BucketMetadata } from "../src/codegen/tables/BucketMetadata.sol";

contract SetupTestWithBucketsTest is SetupTest {
  address private assignee = address(2);
  address private nonAuthorized = address(3);
  uint256 ssuId;
  //Smart Gate IDs
  bytes32 tenantId;
  bytes32 bucketId;

  uint64 totalDepositAmount = uint64(0);
  // primary inventory balances after deposit
  uint256 primaryQtyAfterDeposit;
  // ephemera balances after deposit
  uint256 ephBalanceAfterDeposit;
  // inventory metadata qty after deposit
  uint256 metadataQtyAfterDeposit;
  uint256 afterDepositBucketBalance;

  address admin = address(vm.addr(vm.envUint("PRIVATE_KEY")));
  address player = address(1);
  address unauthorizedPlayer = address(3);
  address nonInventoryOwnerPlayer = address(4);
  address nonTribePlayer = address(5);

  uint256 itemId;
  uint256 itemTypeId;

  uint256 smartStorageUnitId = 1246;
  uint256 smartStorageUnitSmartId;

  uint64 STARTING_INV_ITEM_QUANTITY = 100;
  uint64 STARTING_EPH_ITEM_QUANTITY = 100;

  uint256 CHARACTER_TYPE_ID = 42000000100;
  uint256 SSU_TYPE_ID = 77917;
  uint256 FUEL_TYPE_ID = 78437;

  //   address storageManagerSystem;
  address storeProxySystemAddress;

  function setUp() public virtual override {
    super.setUp();
    vm.pauseGasMetering();
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
    // storageManagerSystem = address(world.sm_v0_2_0__getSystemAddress());
    storeProxySystemAddress = address(world.sm_v0_2_0__getStoreProxyAddress());
    vm.startPrank(player, admin);
    safeCreateCharacter(admin, 1, 7777, "adminCharacter");
    safeCreateCharacter(player, 2, 7777, "playerCharacter");
    vm.stopPrank();
    vm.startPrank(unauthorizedPlayer, admin);
    safeCreateCharacter(unauthorizedPlayer, 3, 7778, "unauthorizedCharacter");
    vm.stopPrank();
    vm.startPrank(nonInventoryOwnerPlayer, admin);
    safeCreateCharacter(nonInventoryOwnerPlayer, 4, 7777, "nonInventoryOwnerCharacter");
    vm.stopPrank();
    vm.startPrank(nonTribePlayer, admin);
    safeCreateCharacter(nonTribePlayer, 5, 8888, "nonTribeCharacter");
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
    uint64 ephBalanceBeforeCreate = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    ephemeralInventorySystem.createAndDepositEphemeral(ssuId, player, itemsTwo);
    uint64 ephBalanceAfter = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    assertEq(ephBalanceBeforeCreate, 0, "Expected ephemeral inventory balance to be 0 before deposit");
    assertEq(
      ephBalanceAfter,
      STARTING_EPH_ITEM_QUANTITY,
      "Expected ephemeral inventory balance to be 100 after deposit"
    );
    vm.stopPrank();
    string memory bucketName = "test";
    // Create buckets
    vm.startPrank(admin);
    bytes32[] memory bucketIds = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketName);
    vm.stopPrank();
    bucketId = bucketIds[0];
    assertEq(bucketIds.length, 1, "Expected one bucket to be created");

    // Verify buckets were created
    assertEq(BucketMetadata.getExists(ssuId, bucketIds[0]), true);
    // create items to deposit

    InventoryItemParams[] memory transferItems = new InventoryItemParams[](2);
    transferItems[0] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(10) });
    transferItems[1] = InventoryItemParams({ smartObjectId: itemId, quantity: uint64(20) });
    for (uint256 i = 0; i < transferItems.length; i++) {
      totalDepositAmount += uint64(transferItems[i].quantity);
    }
    uint64 ephBalanceBefore = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    assertEq(
      ephBalanceBefore,
      STARTING_EPH_ITEM_QUANTITY,
      "Expected ephemeral inventory balance to be 100 before deposit occurs"
    );
    uint64 initialMetadataQty = InventoryBalances.getQuantity(ssuId, itemId);
    bytes32 roleId = keccak256(abi.encodePacked("TRANSFER_FROM_EPHEMERAL_ROLE", ssuId));
    bytes32[] memory rolesToCheck = new bytes32[](1);
    rolesToCheck[0] = roleId;
    bool[] memory hasRoles = accessUtilsSystem.hasRoles(rolesToCheck, storeProxySystemAddress);
    assertEq(hasRoles[0], false, "Expected store proxy to not have TRANSFER_FROM_EPHEMERAL_ROLE initially");
    // Set authorization to system
    vm.startPrank(admin);
    ephemeralInteractSystem.setTransferFromEphemeralAccess(ssuId, storeProxySystemAddress, true);
    vm.stopPrank();
    bool[] memory hasRolesAfter = accessUtilsSystem.hasRoles(rolesToCheck, storeProxySystemAddress);
    assertEq(hasRolesAfter[0], true, "Expected store proxy to have TRANSFER_FROM_EPHEMERAL_ROLE after it was set");
    // Authorized Deposit items into bucket
    vm.startPrank(player);
    uint64 ephBalanceBeforeTwo = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));

    vm.resumeGasMetering();
    world.sm_v0_2_0__deposit(ssuId, bucketId, false, transferItems);
    vm.pauseGasMetering();
    vm.stopPrank();

    metadataQtyAfterDeposit = InventoryBalances.getQuantity(ssuId, itemId);
    ephBalanceAfterDeposit = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    afterDepositBucketBalance = BucketedInventoryItem.getQuantity(bucketId, itemId);
    primaryQtyAfterDeposit = InventoryItem.getQuantity(ssuId, itemId);
    console.log("Ephemeral balance before deposit:", ephBalanceBeforeTwo);
    console.log("Ephemeral balance after deposit:", ephBalanceAfterDeposit);
    assertEq(
      ephBalanceAfterDeposit,
      ephBalanceBefore - totalDepositAmount,
      "Expected ephemeral inventory balance to be fewer after deposit"
    );
    vm.resumeGasMetering();
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
}
