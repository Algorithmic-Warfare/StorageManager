pragma solidity ^0.8.24;

import "./StringPackerErrors.sol";

library StringPacker {
  uint256 private constant MAX_LENGTH = 31;
  uint256 private constant LENGTH_MASK = 0xFF00000000000000000000000000000000000000000000000000000000000000;
  uint256 private constant DATA_MASK = 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

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
        parts[partIndex] = substring(input, lastIndex, i);
        partIndex++;
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

  function packSlow(string memory str) internal pure returns (uint256 packed) {
    bytes memory strBytes = bytes(str);
    uint256 length = strBytes.length;

    if (length > MAX_LENGTH) {
      revert StringTooLong();
    }

    // Check for invalid characters (e.g., '/') in the string
    for (uint256 i = 0; i < length; i++) {
      if (strBytes[i] == "/") {
        revert InvalidCharacterInString();
      }
    }

    // Store length in highest byte
    packed = uint256(length) << (31 * 8);

    // Store string data in remaining bytes
    for (uint256 i = 0; i < length; i++) {
      packed |= uint256(uint8(strBytes[i])) << ((30 - i) * 8);
    }
  }
  function pack(string memory str) internal pure returns (uint256 packed) {
    bytes memory b = bytes(str);
    uint256 len = b.length;
    if (len > MAX_LENGTH) revert StringTooLong();

    for (uint i; i < len; i++) {
      if (b[i] == "/") revert InvalidCharacterInString();
    }

    assembly {
      let dataPtr := add(b, 32)
      let acc := 0

      for {
        let i := 0
      } lt(i, len) {
        i := add(i, 1)
      } {
        let char := byte(0, mload(add(dataPtr, i)))
        let shift := mul(sub(30, i), 8)
        acc := or(acc, shl(shift, char))
      }

      packed := or(shl(248, len), acc)
    }
  }

  function unpack(uint256 packed) internal pure returns (string memory) {
    uint256 length = (packed & LENGTH_MASK) >> (31 * 8);
    bytes memory strBytes = new bytes(length);

    for (uint256 i = 0; i < length; i++) {
      uint256 char = (packed >> ((30 - i) * 8)) & 0xFF;
      strBytes[i] = bytes1(uint8(char));
    }

    return string(strBytes);
  }
}
