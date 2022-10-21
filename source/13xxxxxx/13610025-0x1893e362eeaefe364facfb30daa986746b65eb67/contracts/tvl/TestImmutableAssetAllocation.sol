// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {ImmutableAssetAllocation} from "./ImmutableAssetAllocation.sol";

contract TestImmutableAssetAllocation is ImmutableAssetAllocation {
    string public constant override NAME = "testAllocation";

    function balanceOf(address, uint8)
        external
        view
        override
        returns (uint256)
    {
        return 42;
    }

    function testGetTokenData() external pure returns (TokenData[] memory) {
        return _getTokenData();
    }

    function _validateTokenAddress(address) internal view override {
        return;
    }

    function _getTokenData()
        internal
        pure
        override
        returns (TokenData[] memory)
    {
        TokenData[] memory tokens_ = new TokenData[](2);
        tokens_[0] = TokenData(
            0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe,
            "CAFE",
            6
        );
        tokens_[1] = TokenData(
            0xBEeFbeefbEefbeEFbeEfbEEfBEeFbeEfBeEfBeef,
            "BEEF",
            8
        );
        return tokens_;
    }
}

