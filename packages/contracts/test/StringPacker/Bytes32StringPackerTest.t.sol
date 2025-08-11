// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@systems/StringPacker/StringPackerBytes.sol";

contract Bytes32StringPackerTest is Test {
  using Bytes32StringPacker for string;
  using Bytes32StringPacker for bytes32;

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

  function testSplitAtStartOfString() public {
    string memory input = ",start,middle,end";
    string[] memory result = input.split(",");
    assertEq(result.length, 4);
    assertEq(result[0], "");
    assertEq(result[1], "start");
    assertEq(result[2], "middle");
    assertEq(result[3], "end");
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
  // Pack‐only tests
  function testGas_pack_bytes32_minimal_slow() public {
    string memory s = "01234567890123456789As"; // 1 char
    s.packSlow(); // pack into bytes32
  }
  function testGas_pack_bytes32_minimal() public {
    string memory s = "01234567890123456789As"; // 1 char
    s.pack(); // pack into bytes32
  }

    // Pack‐only tests
  function testGas_pack_bytes32_minimal_asm() public {
    string memory s = "01234567890123456789As"; // 1 char
    s.packAsm(); // pack into bytes32
  }
      // Pack‐only tests
//   function testGas_pack_bytes32_minimal_asm__withchecks() public {
//     string memory s = "01234567890123456789As"; // 1 char
//     s.packMissingErrorParse(); // pack into bytes32
//   }
  
  function testGas_pack_bytes32_minimal_native() public {
    string memory s = "01234567890123456789As"; // 1 char
    s.packNative(); // pack into bytes32
  }

  function testPackUnpack() public {
    vm.pauseGasMetering();
    string memory original = "Hello, World!";
    vm.resumeGasMetering();
    bytes32 packed = original.pack();
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
    bytes32 packed = original.pack();
    string memory unpacked = packed.unpack();
    vm.pauseGasMetering();
    assertEq(original, unpacked);
  }

  function testPacksAreUnique() public {
    string memory original1 = "Hello, World!";
    string memory original2 = "Hello, World!!";
    bytes32 packed1 = original1.pack();
    bytes32 packed2 = original2.pack();
    assertNotEq(packed1, packed2, "packed strings should be unique");
  }

  function testEmptyString() public {
    string memory original = "";
    bytes32 packed = original.pack();
    string memory unpacked = packed.unpack();
    assertEq(original, unpacked);
  }

  function testMaxLength() public {
    // exactly 31 characters long
    string memory original = "This string is exactly 31 chars";
    bytes32 packed = original.pack();
    string memory unpacked = packed.unpack();
    assertEq(original, unpacked);
  }

  function testAllCharacters() public {
    string memory original = "+!@#$^&*()_1234567890ABCDEFGHIJ";
    vm.resumeGasMetering();
    bytes32 packed = original.pack();
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
    string memory withSlash = "/!@#$^&*()_1234567890ABCDEFGHIJ";
    vm.expectRevert(InvalidCharacterInString.selector);
    withSlash.pack();
  }

  function testBoundaryValues() public {
    vm.pauseGasMetering();
    // Empty string
    testEmptyString();

    // Maximum length
    testMaxLength();

    // Single character round-trip
    string memory singleChar = "A";
    vm.resumeGasMetering();
    bytes32 packedSingle = singleChar.pack();
    string memory unpackedSingle = packedSingle.unpack();
    vm.pauseGasMetering();
    assertEq(singleChar, unpackedSingle);

    vm.resumeGasMetering();
  }
}
