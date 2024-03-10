//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
This contract receives XRUNE token emissions, approximately once a day. It
them allows it's `run` method to be called wich will split up it's current
balance between the private investors, tema, dao and ecosystem
contracts/addresses following their respective vesting curves.
*/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IEmissionsPrivateDispenser {
    function deposit(uint amount) external;
}

contract EmissionsSplitter {
    using SafeERC20 for IERC20;

    uint public constant ONE_YEAR = 31536000;
    uint public constant INVESTORS_EMISSIONS_HALF1 = 45000000e18;
    uint public constant INVESTORS_EMISSIONS_HALF2 = 30000000e18;
    uint public constant TEAM_EMISSIONS_HALF1 = 66000000e18;
    uint public constant TEAM_EMISSIONS_HALF2 = 44000000e18;
    uint public constant ECOSYSTEM_EMISSIONS = 250000000e18;

    IERC20 public token;
    uint public emissionsStart;
    address public dao; // DAO contract address
    address public ecosystem; // Coucil Gnosis Safe address
    address public team; // Team Gnosis Safe address
    address public investors; // EmissionsPrivateDispenser address

    uint public sentToTeam;
    uint public sentToInvestors;
    uint public sentToEcosystem;

    event Split(uint amount, uint dao, uint team, uint investors, uint ecosystem);

    constructor(address _token, uint _emissionsStart, address _dao, address _team, address _investors, address _ecosystem) {
        token = IERC20(_token);
        emissionsStart = _emissionsStart;
        dao = _dao;
        team = _team;
        investors = _investors;
        ecosystem = _ecosystem;
    }
    
    function shouldRun() public view returns (bool) {
        return token.balanceOf(address(this)) > 0;
    }

    function run() public {
        uint initialAmount = token.balanceOf(address(this));
        uint amount = initialAmount;
        require(amount > 0, "no balance to split");

        uint sentToInvestorsNow = 0;
        {
            // Investors get 45M tokens linearly over the first year
            uint investorsProgress = _min(((block.timestamp - emissionsStart) * 1e12) / ONE_YEAR, 1e12);
            uint investorsUnlocked = (investorsProgress * INVESTORS_EMISSIONS_HALF1) / 1e12;
            uint investorsAmount = _min(investorsUnlocked - sentToInvestors, amount);
            if (investorsAmount > 0) {
                sentToInvestorsNow += investorsAmount;
                sentToInvestors += investorsAmount;
                amount -= investorsAmount;
                token.safeApprove(investors, investorsAmount);
                IEmissionsPrivateDispenser(investors).deposit(investorsAmount);
            }
        }
        {
            // Investors get their remaining 30M tokens linearly over the second year
            uint elapsed = block.timestamp - emissionsStart;
            elapsed -= _min(elapsed, ONE_YEAR);
            uint investorsProgress = _min((elapsed * 1e12) / ONE_YEAR, 1e12);
            uint investorsUnlocked = (investorsProgress * INVESTORS_EMISSIONS_HALF2) / 1e12;
            uint investorsAmount = _min(investorsUnlocked - _min(investorsUnlocked, sentToInvestors), amount);
            if (investorsAmount > 0) {
                sentToInvestorsNow += investorsAmount;
                sentToInvestors += investorsAmount;
                amount -= investorsAmount;
                token.safeApprove(investors, investorsAmount);
                IEmissionsPrivateDispenser(investors).deposit(investorsAmount);
            }
        }
        
        uint sentToTeamNow = 0;
        {
            // Team get 66M tokens linearly over the first 2 years
            uint teamProgress = _min(((block.timestamp - emissionsStart) * 1e12) / (2 * ONE_YEAR), 1e12);
            uint teamUnlocked = (teamProgress * TEAM_EMISSIONS_HALF1) / 1e12;
            uint teamAmount = _min(teamUnlocked - sentToTeam, amount);
            if (teamAmount > 0) {
                sentToTeamNow += teamAmount;
                sentToTeam += teamAmount;
                amount -= teamAmount;
                token.safeTransfer(team, teamAmount);
            }
        }
        {
            // Team get their remaining 44M tokens linearly over the next 2 years
            uint elapsed = block.timestamp - emissionsStart;
            elapsed -= _min(elapsed, 2 * ONE_YEAR);
            uint teamProgress = _min((elapsed * 1e12) / (2 * ONE_YEAR), 1e12);
            uint teamUnlocked = (teamProgress * TEAM_EMISSIONS_HALF1) / 1e12;
            uint teamAmount = _min(teamUnlocked - _min(teamUnlocked, sentToTeam), amount);
            if (teamAmount > 0) {
                sentToTeamNow += teamAmount;
                sentToTeam += teamAmount;
                amount -= teamAmount;
                token.safeTransfer(team, teamAmount);
            }
        }

        uint ecosystemProgress = _min(((block.timestamp - emissionsStart) * 1e12) / (10 * ONE_YEAR), 1e12);
        uint ecosystemUnlocked = (ecosystemProgress * ECOSYSTEM_EMISSIONS) / 1e12;
        uint ecosystemAmount = _min(ecosystemUnlocked - sentToEcosystem, amount);
        if (ecosystemAmount > 0) {
            sentToEcosystem += ecosystemAmount;
            amount -= ecosystemAmount;
            token.safeTransfer(ecosystem, ecosystemAmount);
        }

        if (amount > 0) {
            token.safeTransfer(dao, amount);
        }

        emit Split(initialAmount, amount, sentToTeamNow, sentToInvestorsNow, ecosystemAmount);
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}

