pragma solidity ^0.4.23;

import "./CutiePausable.sol";

contract CutieERC721Metadata is CutiePausable /* is IERC721Metadata */ {
    string public metadataUrlPrefix = "https://blockchaincuties.com/cutie/";
    string public metadataUrlSuffix = ".svg";

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string) {
        return "BlockchainCuties";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string) {
        return "CUTIE";
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string infoUrl) {
        return
        concat(toSlice(metadataUrlPrefix),
            toSlice(concat(toSlice(uintToString(_tokenId)), toSlice(metadataUrlSuffix))));
    }

    function setMetadataUrl(string _metadataUrlPrefix, string _metadataUrlSuffix) public onlyOwner {
        metadataUrlPrefix = _metadataUrlPrefix;
        metadataUrlSuffix = _metadataUrlSuffix;
    }

    /*
     * @title String & slice utility library for Solidity contracts.
     * @author Nick Johnson <arachnid@notdot.net>
     *
     * @dev Functionality in this library is largely implemented using an
     *      abstraction called a 'slice'. A slice represents a part of a string -
     *      anything from the entire string to a single character, or even no
     *      characters at all (a 0-length slice). Since a slice only has to specify
     *      an offset and a length, copying and manipulating slices is a lot less
     *      expensive than copying and manipulating the strings they reference.
     *
     *      To further reduce gas costs, most functions on slice that need to return
     *      a slice modify the original one instead of allocating a new one; for
     *      instance, `s.split(".")` will return the text up to the first '.',
     *      modifying s to only contain the remainder of the string after the '.'.
     *      In situations where you do not want to modify the original slice, you
     *      can make a copy first with `.copy()`, for example:
     *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
     *      Solidity has no memory management, it will result in allocating many
     *      short-lived slices that are later discarded.
     *
     *      Functions that return two slices come in two versions: a non-allocating
     *      version that takes the second slice as an argument, modifying it in
     *      place, and an allocating version that allocates and returns the second
     *      slice; see `nextRune` for example.
     *
     *      Functions that have to copy string data will return strings rather than
     *      slices; these can be cast back to slices for further processing if
     *      required.
     *
     *      For convenience, some functions are provided with non-modifying
     *      variants that create a new slice and return both; for instance,
     *      `s.splitNew('.')` leaves s unmodified, and returns two values
     *      corresponding to the left and right parts of the string.
     */

    struct slice {
        uint _len;
        uint _ptr;
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice self, slice other) internal pure returns (string) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }


    function uintToString(uint256 a) internal pure returns (string result) {
        string memory r = "";
        do {
            uint b = a % 10;
            a /= 10;

            string memory c = "";

            if (b == 0) c = "0";
            else if (b == 1) c = "1";
            else if (b == 2) c = "2";
            else if (b == 3) c = "3";
            else if (b == 4) c = "4";
            else if (b == 5) c = "5";
            else if (b == 6) c = "6";
            else if (b == 7) c = "7";
            else if (b == 8) c = "8";
            else if (b == 9) c = "9";

            r = concat(toSlice(c), toSlice(r));
        } while (a > 0);
        result = r;
    }
}

