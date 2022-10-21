// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/curve/ILiquidityGaugeV2.sol";
import "../../interfaces/curve/ITokenMinter.sol";

abstract contract CrvPoolMgrBase {
    using SafeERC20 for IERC20;

    address public immutable crvPool;
    address public immutable crvLp;
    address public immutable crvGauge;
    address public constant CRV_MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    constructor(
        address _pool,
        address _lp,
        address _gauge
    ) {
        require(_pool != address(0x0), "CRVMgr: invalid curve pool");
        require(_lp != address(0x0), "CRVMgr: invalid lp token");
        require(_gauge != address(0x0), "CRVMgr: invalid gauge");

        crvPool = _pool;
        crvLp = _lp;
        crvGauge = _gauge;
    }

    // requires that gauge has approval for lp token
    function _stakeAllLpToGauge() internal {
        uint256 balance = IERC20(crvLp).balanceOf(address(this));
        if (balance != 0) {
            ILiquidityGaugeV2(crvGauge).deposit(balance);
        }
    }

    function _unstakeAllLpFromGauge() internal {
        _unstakeLpFromGauge(IERC20(crvGauge).balanceOf(address(this)));
    }

    function _unstakeLpFromGauge(uint256 _amount) internal {
        if (_amount != 0) {
            ILiquidityGaugeV2(crvGauge).withdraw(_amount);
        }
    }

    function _claimCrv() internal {
        ITokenMinter(CRV_MINTER).mint(crvGauge);
    }

    function _setCheckpoint() internal {
        ILiquidityGaugeV2(crvGauge).user_checkpoint(address(this));
    }

    function claimableRewards() public view returns (uint256) {
        //Total Mintable - Previously minted
        return
            ILiquidityGaugeV2(crvGauge).integrate_fraction(address(this)) -
            ITokenMinter(CRV_MINTER).minted(address(this), crvGauge);
    }

    function totalLp() public view returns (uint256 total) {
        total = IERC20(crvLp).balanceOf(address(this)) + IERC20(crvGauge).balanceOf(address(this));
    }
}

