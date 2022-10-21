// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/SafeToken.sol";
import "../library/WhitelistUpgradeable.sol";

import "../interfaces/IBEP20.sol";
import "../interfaces/ISwapCallee.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IQore.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IPriceCalculator.sol";


contract QLiquidationTestnet is ISwapCallee, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    IQore public constant Qore = IQore(0x995cCA2cD0C269fdEe7d057A8A7aaA1586ecEf51);
    IPriceCalculator public constant PriceCalculatorBSC = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    address private constant qBNB = 0x14fA6A83A08B763B8A430e1fAeafe009D266F280;
//    address private constant qETH = 0xAf9A0488D21A3cec2012f3E6Fe632B65Aa6Ea61D;
    address private constant qUSDT = 0x93848E23F0a70891A67a98a6CEBb47Fa55A51508;
//    address private constant qDAI = 0xfc743504c7FF5526e3Ba97617F6e6Bf8fD8cfdF0;
    address private constant qBUSD = 0x5B8BA405976b3A798F47DAE502e1982502aF64c5;
    address private constant qQBT = 0x2D076EC4FE501927c5bea2A5bA8902e5e7A9B727;

//    address private constant BUNNY_BNB = 0x5aFEf8567414F29f0f927A0F2787b188624c10E2;
    address private constant WBNB_BUSD = 0xe0e92035077c39594793e61802a350347c320cf2;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

//    address private constant ETH = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
//    address private constant DAI = 0x8a9424745056Eb399FD19a0EC26A14316684e274;  // BUSD pair
    address private constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address private constant USDT = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
    address private constant QBT = 0xF523e4478d909968090a232eB380E2dd6f802518;

    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private _routePairAddresses;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            IBEP20(underlying).approve(address(ROUTER), uint(- 1));
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
        }
    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[4] memory) {
        return [WBNB, BUSD, USDT, QBT];
    }

    function qTokens() public pure returns (address[4] memory) {
        return [qBNB, qBUSD, qUSDT, qQBT];
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setRoutePairAddress(address token, address route) external onlyOwner {
        require(route != address(0), "QLiquidationTestnet: invalid route address");
        _routePairAddresses[token] = route;
    }

    function approveTokenForRouter(address token) external onlyOwner {
        IBEP20(token).approve(address(ROUTER), uint(- 1));
    }

    /* ========== Pancake Callback FUNCTION ========== */

    function pancakeCall(address, uint, uint, bytes calldata data) external override {
        require(msg.sender == WBNB_BUSD, "QLiquidation: only used for WBNB_BUSD");
        (address qTokenBorrowed, address qTokenCollateral, address borrower, uint loanBalance, uint amount) = abi.decode(data, (address, address, address, uint, uint));

        uint liquidateBalance = Math.min(_swapWBNBtoBorrowToken(qTokenBorrowed, loanBalance), amount);
        _liquidate(qTokenBorrowed, qTokenCollateral, borrower, liquidateBalance);

        _repayToSwap(
            qTokenCollateral,
            loanBalance.mul(10000).div(9975).add(1),
            msg.sender
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function liquidate(address qTokenBorrowed, address qTokenCollateral, address borrow, uint amount) external onlyWhitelisted nonReentrant {
        _flashloan(qTokenBorrowed, qTokenCollateral, borrow, amount);
    }

    function autoLiquidate(address account) external onlyWhitelisted nonReentrant {
        (uint collateralInUSD, , uint borrowInUSD) = Qore.accountLiquidityOf(account);
        require(borrowInUSD > collateralInUSD, "QLiquidation: Insufficient shortfall");

        (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) = _getTargetMarkets(account);
        _flashloan(qTokenBorrowed, qTokenCollateral, account, liquidateAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _liquidate(address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) private {
        uint qTokenCollateralBalance = IQToken(qTokenCollateral).balanceOf(address(this));

        if (IQToken(qTokenBorrowed).underlying() == WBNB) {
            IWETH(WBNB).withdraw(amount);
            Qore.liquidateBorrow{value : amount}(qTokenBorrowed, qTokenCollateral, borrower, 0);
        } else {
            Qore.liquidateBorrow(qTokenBorrowed, qTokenCollateral, borrower, amount);
        }

        _redeemToken(qTokenCollateral, IQToken(qTokenCollateral).balanceOf(address(this)).sub(qTokenCollateralBalance));
    }

    function _getTargetMarkets(address account) private view returns (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) {
        uint maxSupplied;
        uint maxBorrowed;
        address[] memory markets = Qore.marketListOf(account);
        for (uint i = 0; i < markets.length; i++) {
            uint borrow = IQToken(markets[i]).borrowBalanceOf(account);
            uint supply = IQToken(markets[i]).underlyingBalanceOf(account);

            if (borrow > 0 && borrow > maxBorrowed) {
                maxBorrowed = borrow;
                qTokenBorrowed = markets[i];
            }

            uint collateralFactor = Qore.marketInfoOf(markets[i]).collateralFactor;
            if (collateralFactor > 0 && supply > 0 && supply > maxSupplied) {
                maxSupplied = supply;
                qTokenCollateral = markets[i];
            }
        }
        liquidateAmount = _getAvailableAmounts(qTokenBorrowed, qTokenCollateral, maxBorrowed, maxSupplied);
        return (qTokenBorrowed, qTokenCollateral, liquidateAmount);
    }

    function _getAvailableAmounts(address qTokenBorrowed, address qTokenCollateral, uint borrowAmount, uint supplyAmount) private view returns (uint closeAmount) {
        uint borrowPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenBorrowed);
        uint supplyPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenCollateral);
        require(supplyPrice != 0 && borrowPrice != 0, "QLiquidation: price error");

        uint borrowValue = borrowPrice.mul(borrowAmount).div(1e18);
        uint supplyValue = supplyPrice.mul(supplyAmount).div(1e18);

        uint maxCloseValue = borrowValue.mul(Qore.closeFactor()).div(1e18);
        uint maxCloseValueWithIncentive = maxCloseValue.mul(110).div(100);
        return closeAmount = maxCloseValueWithIncentive < supplyValue ? maxCloseValue.mul(1e18).div(borrowPrice)
                                                                      : supplyValue.mul(90).div(100).mul(1e18).div(borrowPrice);
    }

    function _swapWBNBtoBorrowToken(address _qTokenBorrowed, uint loanBalance) private returns (uint liquidateBalance) {
        address underlying = IQToken(_qTokenBorrowed).underlying();
        liquidateBalance = 0;
        if (underlying == WBNB) {
            liquidateBalance = loanBalance;
        } else {
            uint before = IBEP20(underlying).balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = underlying;

            ROUTER.swapExactTokensForTokens(loanBalance, 0, path, address(this), block.timestamp);
            liquidateBalance = IBEP20(underlying).balanceOf(address(this)).sub(before);
        }
    }

    function _flashloan(address _qTokenBorrowed, address _qTokenCollateral, address borrower, uint amount) private {
        address _underlying = IQToken(_qTokenBorrowed).underlying();

        uint borrowBalance;
        if (_underlying == WBNB) {
            borrowBalance = amount;
        } else {
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = _underlying;

            borrowBalance = ROUTER.getAmountsIn(amount, path)[0];
        }

        IPancakePair(WBNB_BUSD).swap(
            0, borrowBalance, address(this),
            abi.encode(_qTokenBorrowed, _qTokenCollateral, borrower, borrowBalance, amount)
        );

    }

    function _redeemToken(address _qTokenCollateral, uint amount) private returns (uint) {
        IBEP20 collateralToken = IBEP20(IQToken(_qTokenCollateral).underlying());

        uint collateralBalance = collateralToken.balanceOf(address(this));
        Qore.redeemToken(_qTokenCollateral, amount);

        if (address(collateralToken) == WBNB) {
            IWETH(WBNB).deposit{value : address(this).balance}();
        }

        return collateralToken.balanceOf(address(this)).sub(collateralBalance);
    }

    function _repayToSwap(address _qTokenCollateral, uint repayAmount, address to) private {
        address collateralToken = IQToken(_qTokenCollateral).underlying();

        if (collateralToken != WBNB) {
            address[] memory path = new address[](2);
            path[0] = collateralToken;
            path[1] = WBNB;

            ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
        }

        require(IBEP20(WBNB).balanceOf(address(this)) >= repayAmount, "QLiquidation: can't repay to pancake");
        WBNB.safeTransfer(to, repayAmount);
    }
}

