/*
ERC20CompetitiveRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "../ERC20CompetitiveRewardModule.sol";
import "../GysrUtils.sol";

/**
 * @title ERC20 competitive reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20CompetitiveRewardModule contract.
 */
library ERC20CompetitiveRewardModuleInfo {
    using GysrUtils for uint256;

    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of reward module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(address module)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint8
        )
    {
        IRewardModule m = IRewardModule(module);
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        return (address(tkn), tkn.name(), tkn.symbol(), tkn.decimals());
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param addr account address of interest for preview
     * @param shares number of shares that would be unstaked
     * @param gysr number of GYSR tokens that would be applied
     * @return estimated reward
     * @return estimated time multiplier
     * @return estimated gysr multiplier
     */
    function rewards(
        address module,
        address addr,
        uint256 shares,
        uint256 gysr
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        // get associated share seconds
        uint256 rawShareSeconds;
        uint256 bonusShareSeconds;
        (rawShareSeconds, bonusShareSeconds) = userShareSeconds(
            module,
            addr,
            shares
        );
        if (rawShareSeconds == 0) {
            return (0, 0, 0);
        }

        uint256 timeBonus = (bonusShareSeconds * 1e18) / rawShareSeconds;

        // apply gysr bonus
        uint256 gysrBonus =
            gysr.gysrBonus(shares, m.totalStakingShares(), m.usage());
        bonusShareSeconds = (gysrBonus * bonusShareSeconds) / 1e18;

        // compute rewards based on expected updates
        uint256 reward =
            (unlocked(module) * bonusShareSeconds) /
                (totalShareSeconds(module) +
                    bonusShareSeconds -
                    rawShareSeconds);

        return (reward, timeBonus, gysrBonus);
    }

    /**
     * @notice compute effective unlocked rewards
     * @param module address of reward module
     * @return estimated current unlocked rewards
     */
    function unlocked(address module) public view returns (uint256) {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        // compute expected updates to global totals
        uint256 deltaUnlocked;
        address tkn = m.tokens()[0];
        uint256 totalLockedShares = m.lockedShares(tkn);
        if (totalLockedShares != 0) {
            uint256 sharesToUnlock;
            for (uint256 i = 0; i < m.fundingCount(tkn); i++) {
                sharesToUnlock = sharesToUnlock + m.unlockable(tkn, i);
            }
            deltaUnlocked =
                (sharesToUnlock * m.totalLocked()) /
                totalLockedShares;
        }
        return m.totalUnlocked() + deltaUnlocked;
    }

    /**
     * @notice compute user share seconds for given number of shares
     * @param module module contract address
     * @param addr user address
     * @param shares number of shares
     * @return raw share seconds
     * @return time bonus share seconds
     */
    function userShareSeconds(
        address module,
        address addr,
        uint256 shares
    ) public view returns (uint256, uint256) {
        require(shares > 0, "crmi1");

        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        uint256 rawShareSeconds;
        uint256 timeBonusShareSeconds;

        // compute first-in-last-out, time bonus weighted, share seconds
        uint256 i = m.stakeCount(addr);
        while (shares > 0) {
            require(i > 0, "crmi2");
            i -= 1;
            uint256 s;
            uint256 time;
            (s, time) = m.stakes(addr, i);
            time = block.timestamp - time;

            // only redeem partial stake if more shares left than needed to burn
            s = s < shares ? s : shares;

            rawShareSeconds += (s * time);
            timeBonusShareSeconds += ((s * time * m.timeBonus(time)) / 1e18);
            shares -= s;
        }
        return (rawShareSeconds, timeBonusShareSeconds);
    }

    /**
     * @notice compute total expected share seconds for a rewards module
     * @param module address for reward module
     * @return expected total shares seconds
     */
    function totalShareSeconds(address module) public view returns (uint256) {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        return
            m.totalStakingShareSeconds() +
            (block.timestamp - m.lastUpdated()) *
            m.totalStakingShares();
    }
}

