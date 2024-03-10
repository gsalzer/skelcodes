pragma solidity ^0.5.8;
import './SafeMath.sol';

contract VDPoolBasic {
    function price() external view returns(uint256);
    function currentLevel() external view returns(uint256);
    function currentLevelRemaining() external view returns(uint256);
}

contract VDPoolThrottler {
    function getCooldownBlocks() external view returns(uint256);
}

contract VDPool is VDPoolBasic {
    using SafeMath for uint256;
    /*
     * STATES
     */
    address public master;
    address public caller;

    uint256 public ethCapacity = 0;
    uint256 public basicExchangeRate = 0;
    uint256 public currentLevel = 0;
    uint256 public currentLevelStartBlock = 0;
    uint256 public cooldownBlocks = 0; // by default wait 1 block before enterring next level
    VDPoolThrottler throttlerContract;
    uint256 public currentPrice = 0;
    uint256 public currentLevelRemaining = 0;

    bool public paused;

    /*
     * EVENTS
     */
    event LevelDescend(uint256 level, uint256 price, uint256 startBlock, uint256 cooldownBlocks, uint256 currentBlock);

    /*
     * MODIFIERS
     */
    /// only master can call the function
    modifier onlyOwner {
        require(master == msg.sender, "only owner can call");
        _;
    }

    /// only master can call the function
    modifier onlyCaller {
        require(caller == msg.sender, "only caller can call");
        _;
    }

    /// function not paused
    modifier notPaused {
        require(paused == false, "function is paused");
        _;
    }

    constructor(uint256 _ethCapacity, uint256 _currentLevel, uint256 _basicExchangeRate) public {
        master = msg.sender;
        ethCapacity = _ethCapacity;
        currentLevel = _currentLevel;
        currentPrice = (currentLevel.sub(1)).mul(10).add(_basicExchangeRate);
        currentLevelRemaining = _ethCapacity;
        basicExchangeRate = _basicExchangeRate;
    }

    function setPause(bool value) external onlyOwner {
        paused = value;
    }

    function setCaller(address who) external onlyOwner {
        caller = who;
    }

    function setOwner(address who) external onlyOwner {
        master = who;
    }

    function setCooldownBlocks(uint256 bn) external onlyOwner {
        cooldownBlocks = bn;
    }

    function setThrottlerContract(address contractAddress) external onlyOwner {
        throttlerContract = VDPoolThrottler(contractAddress);
    }

    function price() external view returns (uint256) {
        uint256 tokens = computeTokenAmount(1 ether);
        return tokens;
    }

    function computeTokenAmount(uint256 ethAmount) public view returns (uint256) {
        uint256 tokens = ethAmount.mul(currentPrice);
        return tokens;
    }

    function buyToken(uint256 ethAmount) external onlyCaller notPaused returns (uint256) {
        require(currentLevelStartBlock <= block.number, "cooling down");
        uint256 eth = ethAmount;
        uint256 tokens = 0;
        while (eth > 0) {
            if (eth <= currentLevelRemaining) {
                tokens = tokens + computeTokenAmount(eth);
                currentLevelRemaining = currentLevelRemaining.sub(eth);
                eth = 0;
            }else {
                tokens = tokens + computeTokenAmount(currentLevelRemaining);
                eth = eth.sub(currentLevelRemaining);
                currentLevelRemaining = 0;
            }

            if (currentLevelRemaining == 0){
                currentLevel = currentLevel.sub(1);
                require (currentLevel > 0, "end of levels");
                currentPrice = (currentLevel.sub(1)).mul(10).add(basicExchangeRate);
                currentLevelRemaining = ethCapacity;
                if (address(throttlerContract) != address(0)) {
                    cooldownBlocks = throttlerContract.getCooldownBlocks();
                }
                if (currentLevelStartBlock > block.number ) {
                    // handling the case of desending multiple level in one tx
                    currentLevelStartBlock = currentLevelStartBlock + cooldownBlocks;
                } else {
                    currentLevelStartBlock = block.number + cooldownBlocks;
                }
                emit LevelDescend(currentLevel, currentPrice, currentLevelStartBlock, cooldownBlocks, block.number);
            }
        }

        return tokens;
    }
}

