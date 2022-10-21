pragma solidity >=0.6.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import '../libraries/TransferHelper.sol';
import '../libraries/Math.sol';
import '../libraries/SafeMath.sol';
import '../libraries/DistributionLibrary.sol';
import '../interfaces/ICAVO.sol';
import '../interfaces/IExcavoERC20.sol';
import '../interfaces/IxCAVO.sol';
import './TestCAVO.sol';

contract DistributionTest is TestCAVO {
    using SafeMath for uint;
    using DistributionLibrary for DistributionLibrary.Data;

    event Distributed(address indexed recipient, uint amount);
    event DistributionStarted(address indexed sender, uint blockNumber);

    DistributionLibrary.Data private testDistribution;
    uint private totalDistribution;

    constructor(uint32 _blocksInPeriod, address[] memory _team, uint[] memory _amounts) public {
        require(_team.length == _amounts.length, 'DistributionTest: INVALID_PARAMS');
        uint total;
        for (uint i = 0; i < _team.length; ++i) {
            testDistribution.maxAmountOf[_team[i]] = _amounts[i];
            total = total.add(_amounts[i]);
        }
        totalDistribution = total;
        testDistribution.blocksInPeriod = _blocksInPeriod;

        _mint(address(this), totalDistribution);
    }

    function testAvailableAmountOf(address account) external view returns (uint) {
        return testDistribution.availableAmountOf(account);
    }

    function testClaim(uint amount) external {
        testDistribution.claim(amount);
        emit Distributed(msg.sender, amount);
    }

    function testStartDistribution() external nonReentrant {
        testDistribution.start();
        emit DistributionStarted(msg.sender, block.number);
    }
}
