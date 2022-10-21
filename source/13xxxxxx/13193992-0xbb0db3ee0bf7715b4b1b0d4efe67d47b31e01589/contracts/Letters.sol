// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Letters is ERC721Enumerable, ReentrancyGuard, Ownable {

    bool private seeded = false;
    uint32 private seed = 0;

    // Frequency distribution based on http://pi.math.cornell.edu/~mec/2003-2004/cryptography/subs/frequencies.html
    string[] private letters = [
        "e",
        "t",
        "a",
        "o",
        "i",
        "n",
        "s",
        "r",
        "h",
        "d",
        "l",
        "u",
        "c",
        "m",
        "f",
        "y",
        "w",
        "g",
        "p",
        "b",
        "v",
        "k",
        "x",
        "q",
        "j",
        "z"
    ];

    uint16[] private lettersDistribution = [
        1202,
        2112,
        2924,
        3692,
        4423,
        5118,
        5746,
        6348,
        6940,
        7372,
        7770,
        8058,
        8329,
        8590,
        8820,
        9031,
        9240,
        9443,
        9625,
        9774,
        9885,
        9954,
        9971,
        9982,
        9992,
        10000
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirst(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIRST", letters, lettersDistribution);
    }

    function getSecond(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SECOND", letters, lettersDistribution);
    }

    function getThird(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "THIRD", letters, lettersDistribution);
    }

    function getFourth(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FOURTH", letters, lettersDistribution);
    }

    function getFifth(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIFTH", letters, lettersDistribution);
    }

    function getSixth(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SIXTH", letters, lettersDistribution);
    }

    function getSeventh(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SEVENTH", letters, lettersDistribution);
    }

    function getEighth(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "EIGHTH", letters, lettersDistribution);
    }

    function getLetters(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(
            getFirst(tokenId),
            getSecond(tokenId),
            getThird(tokenId),
            getFourth(tokenId),
            getFifth(tokenId),
            getSixth(tokenId),
            getSeventh(tokenId),
            getEighth(tokenId)
        ));
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray, uint16[] memory sourceDistribution) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId), seed)));
        string memory output = "letter";
        if (seeded) {
            uint256 luck = rand % 10000;
            for (uint i = 0; i < sourceDistribution.length; i++) {
                if (luck < sourceDistribution[i]) {
                    output = sourceArray[i];
                    break;
                }
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getFirst(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getSecond(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getThird(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getFourth(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFifth(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getSixth(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getSeventh(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getEighth(tokenId);

        parts[16] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Letters #',
                        toString(tokenId),
                        '", "description": "just Letters. Feel free to use Letters in any way you want.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function setSeed(uint32 value) public onlyOwner {
        require(seeded == false, "Already seeded");
        seed = value;
        seeded = true;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor() ERC721("Letters", "LETTERS") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
