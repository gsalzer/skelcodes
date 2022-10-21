// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract CnUtils {

    // 是否为操作符
    function isOperator(string memory s) internal pure returns (bool) {
        return isEqual(s, "+") || isEqual(s, "-") || isEqual(s, "*") || isEqual(s, "/");
    }

    // 是否是操作数
    function isOperand(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        for (uint256 i = 0; i < b.length; i++) {
            if (!(uint8(b[i]) >= 48 && uint8(b[i]) <= 57)) return false;
        }
        return true;
    }

    // 字符串是否相等
    function isEqual(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return (keccak256(bytes(s1)) == keccak256(bytes(s2)));
    }

    function getMin(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return b;
        else return a;
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    function str2uint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory _concatenatedString)
    {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        uint256 i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }
}

