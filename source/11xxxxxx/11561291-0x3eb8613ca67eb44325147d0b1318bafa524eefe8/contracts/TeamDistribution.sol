pragma solidity >=0.6.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import './libraries/TransferHelper.sol';
import './libraries/Math.sol';
import './libraries/SafeMath.sol';
import './libraries/DistributionLibrary.sol';
import './interfaces/ICAVO.sol';
import './interfaces/IExcavoERC20.sol';
import './interfaces/IxCAVO.sol';
import './interfaces/ITeamDistribution.sol';

abstract contract TeamDistribution is ITeamDistribution, ICAVO, IExcavoERC20, ReentrancyGuard {
    using SafeMath for uint;
    using DistributionLibrary for DistributionLibrary.Data;

    event TeamDistributed(address indexed recipient, uint amount);

    uint public override totalTeamDistribution;
    DistributionLibrary.Data private distribution;

    constructor(uint32 _blocksInPeriod, address[] memory _team, uint[] memory _amounts) public {
        require(_team.length == _amounts.length, 'TeamDistribution: INVALID_PARAMS');
        uint total;
        for (uint i = 0; i < _team.length; ++i) {
            distribution.maxAmountOf[_team[i]] = _amounts[i];
            total = total.add(_amounts[i]);
        }
        totalTeamDistribution = total;
        distribution.blocksInPeriod = _blocksInPeriod;
    }

    function availableTeamMemberAmountOf(address account) external view override returns (uint) {
        return distribution.availableAmountOf(account);
    }

    function teamMemberClaim(uint amount) external override nonReentrant {
        distribution.claim(amount);
        emit TeamDistributed(msg.sender, amount);
    }

    function startTeamDistribution() external override nonReentrant {
        distribution.start();
    }
}
