// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./StringPackerErrors.sol";

library Bytes32StringPacker {
  uint8 private constant MAX_LENGTH = 31;

  /// @dev Split & substring are identical to the original library
  function split(string memory input, string memory delimiter) public pure returns (string[] memory) {
    bytes memory inputBytes = bytes(input);
    bytes memory delimiterBytes = bytes(delimiter);
    require(delimiterBytes.length == 1, "Only single character delimiter supported");

    uint count = 1;
    for (uint i = 0; i < inputBytes.length; i++) {
      if (inputBytes[i] == delimiterBytes[0]) {
        count++;
      }
    }

    string[] memory parts = new string[](count);
    uint partIndex = 0;
    uint lastIndex = 0;

    for (uint i = 0; i < inputBytes.length; i++) {
      if (inputBytes[i] == delimiterBytes[0]) {
        parts[partIndex++] = substring(input, lastIndex, i);
        lastIndex = i + 1;
      }
    }
    parts[partIndex] = substring(input, lastIndex, inputBytes.length);
    return parts;
  }

  function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex - startIndex);
    for (uint i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = strBytes[i];
    }
    return string(result);
  }

  /// @dev Pack up to 31 bytes of UTF-8 into a single bytes32, prefixing with length.
  function packSlow(string memory str) internal pure returns (bytes32 result) {
    bytes memory b = bytes(str);
    uint256 len = b.length;
    if (len > MAX_LENGTH) revert StringTooLong();

    // check for invalid character (e.g. '/')
    for (uint256 i = 0; i < len; i++) {
      if (b[i] == "/") revert InvalidCharacterInString();
    }

    // top byte = length
    result = bytes32(uint256(len) << (31 * 8));

    // next 31 bytes = data
    for (uint256 i = 0; i < len; i++) {
      result |= bytes32(uint256(uint8(b[i])) << ((30 - i) * 8));
    }
  }

  function packAsm(string memory str) internal pure returns (bytes32 result) {
    bytes memory b = bytes(str);
    uint256 len = b.length;
    if (len > MAX_LENGTH) revert StringTooLong();

    // check for invalid character (e.g. '/')
    for (uint256 i = 0; i < len; i++) {
      if (b[i] == "/") revert InvalidCharacterInString();
    }

    assembly {
      // store length in top byte (31*8 = 248)
      result := shl(248, len)
    }

    // now or in each character without any high-level casts
    for (uint i; i < len; i++) {
      uint8 c = uint8(b[i]);
      uint shift = (30 - i) * 8;
      assembly {
        // OR in the character byte at the correct position
        result := or(result, shl(shift, c))
      }
    }
  }
  function packSingleLoopAsm(string memory str) internal pure returns (bytes32 result) {
    bytes memory b = bytes(str);
    uint256 len = b.length;
    if (len > MAX_LENGTH) revert StringTooLong();

    // Inline the “invalid character” check in Solidity so we keep it simple
    for (uint i; i < len; i++) {
      if (b[i] == "/") revert InvalidCharacterInString();
    }

    assembly {
      // pointers
      let dataPtr := add(b, 32)
      // initialize a 256-bit accumulator to zero
      let acc := 0

      // build up characters
      for {
        let i := 0
      } lt(i, len) {
        i := add(i, 1)
      } {
        // load one byte from memory: byte(0, mload(ptr + i))
        let char := byte(0, mload(add(dataPtr, i)))
        // compute shift = (30 - i)*8
        let shift := mul(sub(30, i), 8)
        // OR the shifted character into our accumulator
        acc := or(acc, shl(shift, char))
      }

      // now OR in the length as the top byte (248 = 31*8)
      result := or(shl(248, len), acc)
    }
  }

  function pack(string memory str) internal pure returns (bytes32 result) {
    bytes memory b = bytes(str);
    uint256 len = b.length;
    if (len > 31) revert StringTooLong();

    assembly {
      let ptr := add(b, 32)
      let acc := 0

      for {
        let i := 0
      } lt(i, len) {
        i := add(i, 1)
      } {
        // Load the byte at index i
        let char := byte(0, mload(add(ptr, i)))

        // Reject "/" character (ASCII 0x2f)
        if eq(char, 0x2f) {
          // Store function selector of revert error
          mstore(0x00, 0x97c047b500000000000000000000000000000000000000000000000000000000) // keccak256("InvalidCharacterInString()")[0:4]
          revert(0x00, 0x04)
        }

        // Shift and OR into accumulator: position (30 - i) * 8
        acc := or(acc, shl(mul(sub(30, i), 8), char))
      }

      // OR length into highest byte (byte 31)
      result := or(shl(248, len), acc)
    }
  }

  function packNative(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 32))
    }
  }

  /// @dev Unpack a bytes32 that was packed above back into a `string`
  function unpack(bytes32 packed) internal pure returns (string memory) {
    // extract length from top byte
    uint256 len = uint8(bytes1(packed));

    bytes memory b = new bytes(len);
    for (uint256 i = 0; i < len; i++) {
      // shift so that the desired data byte lands in the lowest 8 bits
      uint256 shift = (30 - i) * 8;
      b[i] = bytes1(uint8(uint256(packed) >> shift));
    }
    return string(b);
  }
}
