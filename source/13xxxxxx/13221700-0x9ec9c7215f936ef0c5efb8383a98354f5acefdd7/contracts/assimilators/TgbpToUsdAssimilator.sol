// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../lib/ABDKMath64x64.sol";
import "../interfaces/IAssimilator.sol";
import "../interfaces/IOracle.sol";

contract TgbpToUsdAssimilator is IAssimilator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    using SafeMath for uint256;

    IOracle private constant oracle = IOracle(0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5);
    IERC20 private constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant tgbp = IERC20(0x00000000441378008EA67F4284A57932B1c000a5);

    uint256 private constant DECIMALS = 1e18;

    function getRate() public view override returns (uint256) {
        (, int256 price, , , ) = oracle.latestRoundData();
        return uint256(price);
    }

    // takes raw tgbp amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRawAndGetBalance(uint256 _amount) external override returns (int128 amount_, int128 balance_) {
        bool _transferSuccess = tgbp.transferFrom(msg.sender, address(this), _amount);

        require(_transferSuccess, "Curve/TGBP-transfer-from-failed");

        uint256 _balance = tgbp.balanceOf(address(this));

        uint256 _rate = getRate();

        balance_ = ((_balance * _rate) / 1e8).divu(DECIMALS);

        amount_ = ((_amount * _rate) / 1e8).divu(DECIMALS);
    }

    // takes raw tgbp amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRaw(uint256 _amount) external override returns (int128 amount_) {
        bool _transferSuccess = tgbp.transferFrom(msg.sender, address(this), _amount);

        require(_transferSuccess, "Curve/TGBP-transfer-from-failed");

        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(DECIMALS);
    }

    // takes a numeraire amount, calculates the raw amount of tgbp, transfers it in and returns the corresponding raw amount
    function intakeNumeraire(int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(DECIMALS) * 1e8) / _rate;

        bool _transferSuccess = tgbp.transferFrom(msg.sender, address(this), amount_);

        require(_transferSuccess, "Curve/TGBP-transfer-from-failed");
    }

    // takes a numeraire amount, calculates the raw amount of tgbp, transfers it in and returns the corresponding raw amount
    function intakeNumeraireLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr,
        int128 _amount
    ) external override returns (uint256 amount_) {
        uint256 _tgbpBal = tgbp.balanceOf(_addr);

        if (_tgbpBal <= 0) return 0;

        // DECIMALS
        _tgbpBal = _tgbpBal.mul(1e18).div(_baseWeight);

        // DECIMALS
        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in DECIMALS
        uint256 _rate = _usdcBal.mul(DECIMALS).div(_tgbpBal);

        amount_ = (_amount.mulu(DECIMALS) * DECIMALS) / _rate;

        bool _transferSuccess = tgbp.transferFrom(msg.sender, address(this), amount_);

        require(_transferSuccess, "Curve/TGBP-transfer-failed");
    }

    // takes a raw amount of tgbp and transfers it out, returns numeraire value of the raw amount
    function outputRawAndGetBalance(address _dst, uint256 _amount)
        external
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        uint256 _tgbpAmount = ((_amount) * _rate) / 1e8;

        bool _transferSuccess = tgbp.transfer(_dst, _tgbpAmount);

        require(_transferSuccess, "Curve/TGBP-transfer-failed");

        uint256 _balance = tgbp.balanceOf(address(this));

        amount_ = _tgbpAmount.divu(DECIMALS);

        balance_ = ((_balance * _rate) / 1e8).divu(DECIMALS);
    }

    // takes a raw amount of tgbp and transfers it out, returns numeraire value of the raw amount
    function outputRaw(address _dst, uint256 _amount) external override returns (int128 amount_) {
        uint256 _rate = getRate();

        uint256 _tgbpAmount = (_amount * _rate) / 1e8;

        bool _transferSuccess = tgbp.transfer(_dst, _tgbpAmount);

        require(_transferSuccess, "Curve/TGBP-transfer-failed");

        amount_ = _tgbpAmount.divu(DECIMALS);
    }

    // takes a numeraire value of tgbp, figures out the raw amount, transfers raw amount out, and returns raw amount
    function outputNumeraire(address _dst, int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(DECIMALS) * 1e8) / _rate;

        bool _transferSuccess = tgbp.transfer(_dst, amount_);

        require(_transferSuccess, "Curve/TGBP-transfer-failed");
    }

    // takes a numeraire amount and returns the raw amount
    function viewRawAmount(int128 _amount) external view override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(DECIMALS) * 1e8) / _rate;
    }

    function viewRawAmountLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr,
        int128 _amount
    ) external view override returns (uint256 amount_) {
        uint256 _tgbpBal = tgbp.balanceOf(_addr);

        if (_tgbpBal <= 0) return 0;

        // DECIMALS
        _tgbpBal = _tgbpBal.mul(1e18).div(_baseWeight);

        // DECIMALS
        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in DECIMALS
        uint256 _rate = _usdcBal.mul(DECIMALS).div(_tgbpBal);

        amount_ = (_amount.mulu(DECIMALS) * DECIMALS) / _rate;
    }

    // takes a raw amount and returns the numeraire amount
    function viewNumeraireAmount(uint256 _amount) external view override returns (int128 amount_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(DECIMALS);
    }

    // views the numeraire value of the current balance of the reserve, in this case tgbp
    function viewNumeraireBalance(address _addr) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 _balance = tgbp.balanceOf(_addr);

        if (_balance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((_balance * _rate) / 1e8).divu(DECIMALS);
    }

    // views the numeraire value of the current balance of the reserve, in this case tgbp
    function viewNumeraireAmountAndBalance(address _addr, uint256 _amount)
        external
        view
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(DECIMALS);

        uint256 _balance = tgbp.balanceOf(_addr);

        balance_ = ((_balance * _rate) / 1e8).divu(DECIMALS);
    }

    // views the numeraire value of the current balance of the reserve, in this case tgbp
    // instead of calculating with chainlink's "rate" it'll be determined by the existing
    // token ratio
    // Mainly to protect LP from losing
    function viewNumeraireBalanceLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr
    ) external view override returns (int128 balance_) {
        uint256 _tgbpBal = tgbp.balanceOf(_addr);

        if (_tgbpBal <= 0) return ABDKMath64x64.fromUInt(0);

        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in DECIMALS
        uint256 _rate = _usdcBal.mul(1e18).div(_tgbpBal.mul(1e18).div(_baseWeight));

        balance_ = ((_tgbpBal * _rate) / DECIMALS).divu(1e18);
    }
}

