// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@systems/StringPacker/StringPacker.sol";

contract StringPackerTest is Test {
  using StringPacker for string;
  using StringPacker for uint256;
  address private creator = address(1);

  function setUp() public {}

  function testSplitBasicCommaSeparated() public {
    string memory input = "apple,banana,carrot";
    string[] memory result = input.split(",");
    assertEq(result.length, 3);
    assertEq(result[0], "apple");
    assertEq(result[1], "banana");
    assertEq(result[2], "carrot");
  }

  function testSplitSingleWord() public {
    string memory input = "hello";
    string[] memory result = input.split(",");
    assertEq(result.length, 1);
    assertEq(result[0], "hello");
  }

  function testSplitLeadingAndTrailing() public {
    string memory input = ",start,middle,end,";
    string[] memory result = input.split(",");
    assertEq(result.length, 5);
    assertEq(result[0], "");
    assertEq(result[1], "start");
    assertEq(result[2], "middle");
    assertEq(result[3], "end");
    assertEq(result[4], "");
  }

  function testSplitEmptyString() public {
    string memory input = "";
    string[] memory result = input.split(",");
    assertEq(result.length, 1);
    assertEq(result[0], "");
  }

  function testSubstringMiddle() public {
    string memory input = "hello world";
    string memory result = input.substring(6, 11);
    assertEq(result, "world");
  }

  function testSubstringWholeString() public {
    string memory input = "test";
    string memory result = input.substring(0, 4);
    assertEq(result, "test");
  }

  function testSubstringPartial() public {
    string memory input = "abcdefg";
    string memory result = input.substring(2, 5);
    assertEq(result, "cde");
  }

  function testSplitWithDifferentDelimiter() public {
    string memory input = "one|two|three";
    string[] memory result = input.split("|");
    assertEq(result.length, 3);
    assertEq(result[0], "one");
    assertEq(result[1], "two");
    assertEq(result[2], "three");
  }

  function testSplitRejectsMultiCharDelimiter() public {
    vm.expectRevert("Only single character delimiter supported");
    string memory input = "a,b";
    input.split("::");
  }

  function testPackUnpack() public {
    vm.pauseGasMetering();
    string memory original = "Hello, World!";
    vm.resumeGasMetering();
    uint256 packed = original.pack();
    string memory unpacked = packed.unpack();
    vm.pauseGasMetering();
    assertEq(original, unpacked);
  }

  function testPackLong() public {
    vm.pauseGasMetering();
    string memory original = "0123456789012345678901234567890";
    vm.resumeGasMetering();
    original.pack();
    vm.pauseGasMetering();
  }

  function testPackUnpackLong() public {
    vm.pauseGasMetering();
    string memory original = "0123456789012345678901234567890";
    vm.resumeGasMetering();
    uint256 packed = original.pack();
    string memory unpacked = packed.unpack();
    vm.pauseGasMetering();
    assertEq(original, unpacked);
  }

  function testGas_pack_uint256_minimal() public {
    string memory s = "01234567890123456789As";
    s.pack(); // original uint256 pack
  }

  function testGas_packSlow_uint256_minimal() public {
    string memory s = "01234567890123456789As";
    s.packSlow(); // original uint256 pack
  }

  function testPacksAreUnique() public {
    uint256 smartObjectId = uint256(1);
    string memory original1 = "Hello, World!";
    string memory original2 = "Hello, World!!";
    uint256 packed1 = original1.pack();
    uint256 packed2 = original2.pack();
    assertNotEq(packed1, packed2, "packed strings should be unique");

    assertNotEq(
      bytes32(keccak256(abi.encode(smartObjectId, packed1))),
      bytes32(keccak256(abi.encode(smartObjectId, packed2))),
      "encoded packged strings should be unique"
    );
  }

  function testEmptyString() public {
    string memory original = "";
    uint256 packed = original.pack();
    string memory unpacked = packed.unpack();
    assertEq(original, unpacked);
  }

  function testMaxLength() public {
    string memory original = "This string is exactly 31 chars";
    uint256 packed = original.pack();
    string memory unpacked = packed.unpack();
    assertEq(original, unpacked);
  }

  function testAllCharacters() public {
    string memory original = "+!@#$^&*()_1234567890ABCDEFGHIJ";
    vm.resumeGasMetering();
    uint256 packed = original.pack();
    vm.pauseGasMetering();

    string memory unpacked = packed.unpack();
    assertEq(original, unpacked);
  }

  function testRevertTooLong() public {
    string memory tooLong = "This string is definitely too long for our packer";
    vm.expectRevert(StringTooLong.selector);
    tooLong.pack();
  }

  function testRevertInvalidCharacter() public {
    string memory tooLong = "/!@#$^&*()_1234567890ABCDEFGHIJ";
    vm.expectRevert(InvalidCharacterInString.selector);
    tooLong.pack();
  }

  function testBoundaryValues() public {
    vm.pauseGasMetering();
    // Test minimum value (empty string)
    testEmptyString();

    // Test maximum length
    testMaxLength();

    // Test single character
    string memory singleChar = "A";
    vm.resumeGasMetering();

    uint256 packedSingle = singleChar.pack();
    string memory unpackedSingle = packedSingle.unpack();
    vm.pauseGasMetering();

    assertEq(singleChar, unpackedSingle);
    vm.resumeGasMetering();
  }
}
