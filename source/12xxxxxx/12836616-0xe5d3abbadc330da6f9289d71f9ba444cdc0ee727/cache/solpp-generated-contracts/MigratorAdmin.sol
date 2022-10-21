pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./tacoswapv2/interfaces/ITacoswapV2Pair.sol";
import "./tacoswapv2/interfaces/ITacoswapV2Factory.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IETacoChef.sol";
import "./MigratorDummy.sol";


/**
 *@title MigratorAdmin contract
 * - Users can:
 *   #Migrate` migrates LP tokens from TacoChef to eTacoChef
 *   #migrateUserInfo
 * - only owner can
 *   #MigratePools
 **/

contract MigratorAdmin is Ownable {
    IETacoChef public newChef;

    /**
     *  @param _newChef The address of eTacoChef.
     **/
    constructor(address _newChef) {
        require(_newChef != address(0x0), "Migrator::set zero address");
        newChef = IETacoChef(_newChef);
    }

    /**
     *  @dev Migrates UserInfo from TacoChef to eTacoChef.
     *   Can be called by user one time only.
     **/
    function updateUserInfo(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external onlyOwner {
        (, , , uint256 accRewardPerShare) = newChef.poolInfo(_pid);
        newChef.setUser(
            _pid,
            _user,
            _amount,
            (_amount * accRewardPerShare * 111111111111) / 1e12 / 1e11
        );
    }
}

