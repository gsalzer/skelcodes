pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./tacoswapv2/interfaces/ITacoswapV2Pair.sol";
import "./interfaces/IMasterChef.sol";
import "./DummyToken.sol";

/**
 *@title Migrator contract
 * - Users can:
 *   #Migrate` migrates LP tokens from TacoChef to eTacoChef
 *   #migrateUserInfo
 * - only owner can
 *   #MigratePools
 **/

contract MigratorDummy is Ownable {
    /**
     *  @dev Migrates LP tokens from TacoChef to eTacoChef.
     *   Deploy DummyToken. Mint DummyToken with the same amount of LP tokens.
     *   DummyToken is neaded to pass require in TacoChef contracts migrate function.
     **/
    function migrate(ITacoswapV2Pair orig) public returns (IERC20) {
        // Transfer all LP tokens from oldMaster to newMaster
        // Deploy dummy token
        // Mint same amount of dummy token for oldMaster

        DummyToken dummyToken = new DummyToken();
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return dummyToken;

        orig.transferFrom(msg.sender, owner(), lp);
        dummyToken.mint(msg.sender, lp);
        return dummyToken;
    }
}

