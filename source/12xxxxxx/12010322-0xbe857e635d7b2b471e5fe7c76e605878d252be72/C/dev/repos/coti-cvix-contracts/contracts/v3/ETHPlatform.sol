// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IETHPlatform.sol";
import "./PlatformV2.sol";


//TOOD: Have a transfer function overridden!

contract ETHPlatform is PlatformV2, IETHPlatform {

    constructor(string memory _lpTokenName, string memory _lpTokenSymbolName, uint256 _initialTokenToLPTokenRate,
        IFeesCalculatorV3 _feesCalculator,
        ICVIOracleV3 _cviOracle,
        ILiquidation _liquidation) public PlatformV2(IERC20(address(0)), _lpTokenName, _lpTokenSymbolName, _initialTokenToLPTokenRate, _feesCalculator, _cviOracle, _liquidation) {
    }

    function depositETH(uint256 _minLPTokenAmount) external override payable returns (uint256 lpTokenAmount) {
        lpTokenAmount = deposit(msg.value, _minLPTokenAmount);
    }

    function openPositionETH(uint16 _maxCVI, uint168 _maxBuyingPremiumFeePercentage, uint8 _leverage) external override payable returns (uint256 positionUnitsAmount) {
        require(uint168(msg.value) == msg.value, "Too much ETH");
        positionUnitsAmount = openPosition(uint168(msg.value), _maxCVI, _maxBuyingPremiumFeePercentage, _leverage);
    }

    function transferTokens(uint256 _tokenAmount) internal override {
        msg.sender.transfer(_tokenAmount);
    }

    // ETH is passed automatically, nothing to do
    function collectTokens(uint256 _tokenAmount) internal override {
    }

    // ETH has already passed, so subtract amount to get balance before run
    function getTokenBalance(uint256 _tokenAmount) internal view override returns (uint256) {
        return address(this).balance.sub(_tokenAmount);
    }

    function sendProfit(uint256 _amount, IERC20 _token) internal override {
        payable(address(feesCollector)).transfer(_amount);
    }
}

