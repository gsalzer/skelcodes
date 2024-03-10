// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../Pausable.sol";
import "../interfaces/bloq/ISwapManager.sol";
import "../interfaces/vesper/IController.sol";
import "../interfaces/vesper/IStrategy.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListExt.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListFactory.sol";
import "./Strategy.sol";

contract MultiStrategy is Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address[] strategies;
    uint numStrategies;

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public Strategy(_controller, _pool, _receiptToken) {
    }

    function addNewStrategy(address strategy) public {
        strategies.push(strategy);
        ++numStrategies;
    }

    function rebalance() external override {
        //Strategy(strategy);
    }

    function beforeWithdraw() external override {

    }

    function interestEarned() external view virtual override returns (uint256) {
        return 0;
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return false;
    }

    function totalLocked() public view virtual override returns (uint256) {
        return 0;
    }

    function _handleFee(uint256 _fee) internal virtual override {
    }

    function _deposit(uint256 _amount) internal virtual override {

    }

    function _withdraw(uint256 _amount) internal virtual override {

    }

    function _approveToken(uint256 _amount) internal virtual override {

    }

    function _updatePendingFee() internal virtual override {

    }

    function _withdrawAll() internal virtual override {

    }

    function _migrateIn() internal virtual override {

    }

    function _migrateOut() internal virtual override {

    }

    function _claimReward() internal virtual override {

    }
}

