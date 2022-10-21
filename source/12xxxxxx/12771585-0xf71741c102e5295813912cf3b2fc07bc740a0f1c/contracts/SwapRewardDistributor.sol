// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapRewardDistributor is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('receiveApproval(address,uint256,address,uint256)')));
    uint public lockPercentage = 67;

    constructor () public {
    }

    function tokenBalance(address _token) external view returns(uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    function withdrawToken(address _token, address _destination, address _lockDestination, uint256 _lockingPeriod, uint256 _amount) external onlyOwner {
        uint256 _lockAmount = _amount.mul(lockPercentage).div(100);
        IERC20(_token).safeTransfer(_destination, _amount.sub(_lockAmount));
        if(_lockAmount != 0){
            approveAndCall(_token, _lockDestination, _lockAmount, _lockingPeriod);
        }
    }

    function approveAndCall(address _token, address _spender, uint256 _value, uint256 _lockingPeriod) internal returns (bool success) {
        IERC20(_token).safeApprove(_spender, _value);
        (bool thisSuccess,) = _spender.call(abi.encodeWithSelector(SELECTOR, _token, _value, address(this), _lockingPeriod));
        require(thisSuccess, "Spender- receiveApproval failed");
        return true;
    }

    function setLockPercentage(uint _lockPercentage) external onlyOwner {
        lockPercentage = _lockPercentage;
    }
}
