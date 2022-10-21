// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTXv4.sol";

contract NFTXv5 is NFTXv4 {
    function _calcFee(
        uint256 amount,
        uint256 ethBase,
        uint256 ethStep,
        bool isD2
    ) internal pure virtual override returns (uint256) {
        if (amount == 0) {
            return 0;
        } else if (isD2) {
            return 0; // this line was causing a bug when < 1.0 of a D2 token was minted
            // probably won't be using fees much for this version of smart contracts anyway
        } else {
            uint256 n = amount;
            uint256 nSub1 = amount >= 1 ? n.sub(1) : 0;
            return ethBase.add(ethStep.mul(nSub1));
        }
    }
}

