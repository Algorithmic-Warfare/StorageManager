pragma solidity ^0.8.24;

import { IWorld } from "@world/IWorld.sol";
import { EphemeralInvItem } from "@eveworld/world-v2/src/namespaces/evefrontier/codegen/tables/EphemeralInvItem.sol";

import { BucketMetadata } from "../../src/codegen/tables/BucketMetadata.sol";
import { SetupTestWithBucketsTest } from "../SetupTestWithBucketsTest.t.sol";

contract PostSetupTest is SetupTestWithBucketsTest {
  function setUp() public override {
    super.setUp();
  }

  function testStorageManagerCreateSingleBucket() public {
    string memory bucketName = "testt";
    // Create buckets

    vm.startPrank(player);
    uint64 ephBalanceBefore = uint64(EphemeralInvItem.getQuantity(ssuId, player, itemId));
    assertEq(
      ephBalanceBefore,
      STARTING_EPH_ITEM_QUANTITY - 30,
      "Expected ephemeral inventory balance to be 70 (post-deposit to bucket in setup)"
    );
    bytes32[] memory bucketIds = world.sm_v0_2_0__createNestedBuckets(ssuId, bucketName);
    vm.stopPrank();
    assertEq(bucketIds.length, 1, "Expected one bucket to be created");
    // Verify buckets were created
    assertEq(BucketMetadata.getExists(ssuId, bucketId), true);
  }
}
