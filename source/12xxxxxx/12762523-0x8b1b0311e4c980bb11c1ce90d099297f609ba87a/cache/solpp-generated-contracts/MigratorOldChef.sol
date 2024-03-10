pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./tacoswapv2/interfaces/ITacoswapV2Pair.sol";
import "./tacoswapv2/interfaces/ITacoswapV2Factory.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IETacoChef.sol";
import "./MigratorDummy.sol";
import "./DummyToken.sol";


/**
 *@title MigratorOldChef contract
 * - Users can:
 *   #Migrate` migrates LP tokens from TacoChef to eTacoChef
 *   #migrateUserInfo
 * - only owner can
 *   #MigratePools
 **/

contract MigratorOldChef {
    address public oldChef;

    mapping(address => bool) public isMigrated;

    constructor(address _oldChef) {
        require(_oldChef != address(0x0), "Migrator::set zero address");
        oldChef = _oldChef;
    }

    function migrate(ITacoswapV2Pair orig) public returns (IERC20) {
        require(
            msg.sender == oldChef,
            "Migrator: not from old master chef"
        );

        DummyToken dummyToken = new DummyToken();
        
        dummyToken.mint(msg.sender, orig.balanceOf(msg.sender));
        orig.transferFrom(msg.sender, address(this), orig.balanceOf(msg.sender));

        return dummyToken;
    }
}

