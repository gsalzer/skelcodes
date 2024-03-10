// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./interfaces/ILottery.sol";

contract LotteryReward is Initializable, Ownable {
    using SafeERC20 for IERC20;

    ILottery public lottery;
    IERC20 public trade;

    function initialize(
        ILottery _lottery,
        IERC20 _trade
    ) external initializer {
        __Ownable_init();
        lottery = _lottery;
        trade = _trade;
    }

    event Inject(uint256 amount);
    event Withdraw(uint256 amount);

    uint8[4] private nullTicket = [0,0,0,0];

    function inject(uint256 _amount) external onlyOwner {
        trade.safeApprove(address(lottery), _amount);
        lottery.buy(_amount, nullTicket);
        emit Inject(_amount);
    }

    function adminWithdraw(uint256 _amount) external onlyOwner {
        trade.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(_amount);
    }

}
