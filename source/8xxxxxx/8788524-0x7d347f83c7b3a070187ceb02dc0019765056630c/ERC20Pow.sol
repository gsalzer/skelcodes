pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ERC20.sol";

/**
* @dev ERC20Pow
*/
contract ERC20Pow is ERC20 {

    using SafeMath for uint256;

    // recommended value is 2**16
    uint256 private _MINIMUM_TARGET;

    // a big number is easier, bitcoin uses 2**224
    uint256 private _MAXIMUM_TARGET;

    // Reward halving interval, bitcoin uses 210000
    uint256 private _REWARD_INTERVAL;

    // Difficulty adjustment interval, bitcoin uses 2016
    uint256 private _BLOCKS_PER_READJUSTMENT;

    // Suppose the block is 10 minutes, the ETH block is 10 seconds, then the value is 600/10=60
    uint256 private _ETHBLOCK_EXCHANGERATE;

    // Urgent adjustment threshold
    uint256 private _URGENTADJUST_THRESHOLD;

    // Block count
    uint256 private _blockCount;

    // Block reward, bitcoin uses 5000000000
    uint256 private _blockReward;

    // Mining related
    uint256 private _miningTarget;
    bytes32 private _challengeNumber;

    // Prevent duplication
    mapping(bytes32 => bytes32) private _solutionForChallenge;

    // Calculate the time interval
    uint256 private _latestDifficultyPeriodStarted;

    /**
    * @dev Init
    */
    constructor (
        uint256 minimumTarget,
        uint256 maximumTarget,
        uint256 rewardInterval,
        uint256 blockReward,
        uint256 blocksPerReadjustment,
        uint256 ethBlockExchangeRate,
        uint256 urgentAdjustThreshold
    ) public {
        _MINIMUM_TARGET = minimumTarget;
        _MAXIMUM_TARGET = maximumTarget;
        _REWARD_INTERVAL = rewardInterval;
        _BLOCKS_PER_READJUSTMENT = blocksPerReadjustment;
        _ETHBLOCK_EXCHANGERATE = ethBlockExchangeRate;
        _URGENTADJUST_THRESHOLD = urgentAdjustThreshold;
        _blockReward = blockReward;
        _miningTarget = _MAXIMUM_TARGET;
        _latestDifficultyPeriodStarted = uint256(block.number);
        _newMiningBlock();
    }

    /**
    * @dev Current block number
    */
    function getBlockCount() public view returns (uint256) {
        return _blockCount;
    }

    /**
    * @dev Current challenge number
    */
    function getChallengeNumber() public view returns (bytes32) {
        return _challengeNumber;
    }

    /**
    * @dev Current mining difficulty
    */
    function getMiningDifficulty() public view returns (uint256) {
        return _MAXIMUM_TARGET.div(_miningTarget);
    }

    /**
    * @dev Current mining target
    */
    function getMiningTarget() public view returns (uint256) {
        return _miningTarget;
    }

    /**
    * @dev Current mining reward
    */
    function getMiningReward() public view returns (uint256) {
        return _blockReward;
    }

    /**
    * @dev Submit proof
    * Emits a {SubmitProof} event
    */
    function submitProof(uint256 nonce, bytes32 challengeDigest) public returns (bool) {

        // Calculated hash
        bytes32 digest = keccak256(abi.encodePacked(_challengeNumber, msg.sender, nonce));

        // Verify digest
        require(digest == challengeDigest, "ERC20Pow: invalid params");
        require(uint256(digest) <= _miningTarget, "ERC20Pow: invalid nonce");

        // Prevent duplication
        bytes32 solution = _solutionForChallenge[_challengeNumber];
        _solutionForChallenge[_challengeNumber] = digest;
        require(solution == bytes32(0), "ERC20Pow: already exists");

        // Mint
        if (0 != _blockReward) {
            _mint(msg.sender, _blockReward);
        }

        // Next round of challenges
        _newMiningBlock();

        emit SubmitProof(msg.sender, _miningTarget, _challengeNumber);
        return true;
    }

    /**
    * @dev Urgent adjust difficulty
    * When the hash power suddenly drops sharply, the difficulty can be reduced
    * Emits a {UrgentAdjustDifficulty} event
    */
    function urgentAdjustDifficulty() public returns (bool) {

        // Must greatly exceed expectations
        uint256 targetEthBlocksPerDiffPeriod = _BLOCKS_PER_READJUSTMENT.mul(_ETHBLOCK_EXCHANGERATE);
        uint256 ethBlocksSinceLastDifficultyPeriod = uint256(block.number).sub(_latestDifficultyPeriodStarted);
        require(ethBlocksSinceLastDifficultyPeriod.div(targetEthBlocksPerDiffPeriod) > _URGENTADJUST_THRESHOLD, "ERC20Pow: invalid operation");

        _reAdjustDifficulty();
        _newChallengeNumber();

        emit UrgentAdjustDifficulty(msg.sender, _miningTarget, _challengeNumber);
        return true;
    }

    /**
    * @dev internal
    */
    function _newChallengeNumber() internal {
        _challengeNumber = keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender));
    }

    /**
    * @dev internal
    */
    function _newMiningBlock() internal {

        // Block number + 1
        _blockCount = _blockCount.add(1);

        // Block reward is cut in half
        if (0 == _blockCount.mod(_REWARD_INTERVAL)) {
            _blockReward = _blockReward.div(2);
        }

        // Re-Adjust difficulty
        if(0 == _blockCount.mod(_BLOCKS_PER_READJUSTMENT)) {
            _reAdjustDifficulty();
        }

        // Generate challenge number
        _newChallengeNumber();
    }

    /**
    * @dev internal
    */
    function _reAdjustDifficulty() internal {

        uint256 targetEthBlocksPerDiffPeriod = _BLOCKS_PER_READJUSTMENT.mul(_ETHBLOCK_EXCHANGERATE);
        uint256 ethBlocksSinceLastDifficultyPeriod = uint256(block.number).sub(_latestDifficultyPeriodStarted);

        // If there were less eth blocks passed in time than expected
        if (ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod) {

            // Increase difficulty
            uint256 excessBlockPct = targetEthBlocksPerDiffPeriod.mul(100).div(ethBlocksSinceLastDifficultyPeriod);

            // Range 0 - 1000
            uint256 excessBlockPctExtra = excessBlockPct.sub(100);
            if(excessBlockPctExtra > 1000) excessBlockPctExtra = 1000;

            // Up to 50%
            _miningTarget = _miningTarget.sub(_miningTarget.div(2000).mul(excessBlockPctExtra));
        }
        else if(ethBlocksSinceLastDifficultyPeriod > targetEthBlocksPerDiffPeriod) {

            // Reduce difficulty
            uint256 shortageBlockPct = ethBlocksSinceLastDifficultyPeriod.mul(100).div(targetEthBlocksPerDiffPeriod);

            // Range 0 - 1000
            uint256 shortageBlockPctExtra = shortageBlockPct.sub(100);
            if(shortageBlockPctExtra > 1000) shortageBlockPctExtra = 1000;

            // Up to 50%
            _miningTarget = _miningTarget.add(_miningTarget.div(2000).mul(shortageBlockPctExtra));
        }

        if(_miningTarget < _MINIMUM_TARGET) _miningTarget = _MINIMUM_TARGET;
        if(_miningTarget > _MAXIMUM_TARGET) _miningTarget = _MAXIMUM_TARGET;
        _latestDifficultyPeriodStarted = block.number;
    }

    /**
    * @dev Emitted when new challenge number
    */
    event SubmitProof(address indexed miner, uint256 newMiningTarget, bytes32 newChallengeNumber);
    event UrgentAdjustDifficulty(address indexed miner, uint256 newMiningTarget, bytes32 newChallengeNumber);
}
