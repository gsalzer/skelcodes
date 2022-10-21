pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMasterChef.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TacoLocker is Ownable {
    using SafeERC20 for IERC20;
    IMasterChef private _masterChef;
    IERC20 public token;

    constructor(IMasterChef _mChef, IERC20 _token) public {
        _masterChef = _mChef;
        token = _token;
        IERC20(_token).safeApprove(address(_mChef), type(uint256).max);
    }

    function depositToMasterChef(uint256 _pid, uint256 _amount) external onlyOwner {
        _masterChef.deposit(_pid, _amount);
    }
}

