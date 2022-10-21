// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import './interfaces/IHegicETHOptions.sol';
import './interfaces/ICurve.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IChainlinkAggregatorV3.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/ITBDv2.sol';

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import 'hardhat/console.sol';

contract TBDFees is Ownable {
    using SafeMath for uint256;

    event WithdrawFees(
        address indexed owner,
        uint256 amount
    );

    event ChangeFee(
        address indexed owner,
        uint256 fee 
    );

    // Decimals for fee computation
    uint256 constant FEE_DECIMALS = 1e6;

    // Fee, 999000 to tax 0.01%
    uint256 public fee;

    /// @notice Change the charged fee on each option purchase
    /// @param _fee The new fee to use. To set 1% fees => 990000, 0.1% fees => 999000 
    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= FEE_DECIMALS, 'TBDv2/invalid-fee-amount');
        fee = _fee;
        emit ChangeFee(owner(), fee);
    }

    /// @notice Returns the value with fee taken into account
    /// @param _amount Amount without fees
    function computeAmountWithFees(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(fee).div(FEE_DECIMALS);
    }

    /// @notice Withdraw collected fees (all contract eth balance) to owner address
    function withdrawFees() external onlyOwner {
        require(address(this).balance > 0, 'TBDv2/no-collected-fees');

        emit WithdrawFees(owner(), address(this).balance);

        (bool success, ) = owner().call{value: address(this).balance}('');
        require(success, 'TBDv2/error-while-withdrawing');
    }
}
