// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ILoanToken.sol";
import "../interfaces/IWrapper.sol";


contract FulcrumWrapperLegacy is IWrapper, Ownable {
    using SafeMath for uint256;

    mapping(IERC20 => IERC20) public iTokenToToken;
    mapping(IERC20 => IERC20) public tokenToiToken;

    function addMarkets(ILoanToken[] memory markets) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            IERC20 underlying = IERC20(markets[i].loanTokenAddress());
            iTokenToToken[IERC20(address(markets[i]))] = underlying;
            tokenToiToken[underlying] = IERC20(address(markets[i]));
        }
    }

    function removeMarkets(ILoanToken[] memory markets) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            IERC20 underlying = IERC20(markets[i].loanTokenAddress());
            delete iTokenToToken[IERC20(address(markets[i]))];
            delete tokenToiToken[underlying];
        }
    }

    function wrap(IERC20 token) external view override returns (IERC20 wrappedToken, uint256 rate) {
        IERC20 underlying = iTokenToToken[token];
        IERC20 iToken = tokenToiToken[token];
        if (underlying != IERC20(0)) {
            return (underlying, uint256(1e36).div(ILoanToken(address(token)).tokenPrice()));
        } else if (iToken != IERC20(0)) {
            return (iToken, ILoanToken(address(iToken)).tokenPrice());
        } else {
            revert("Unsupported token");
        }
    }
}

