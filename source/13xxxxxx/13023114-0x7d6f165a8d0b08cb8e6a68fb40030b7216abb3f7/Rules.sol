pragma solidity ^0.5.11;

import "./SafeMath.sol";

library Rules {
    
    using SafeMath for uint256;

    struct Rule {               
        uint256 intervalFreezeBlock;        
        uint256 percent;                   
        bool    initRule;     
        uint256 maxAmount;
        uint256 remainAmount;              
    }

    function setRule(Rule storage rule, uint256 _intervalFreezeBlock, uint256 _percent, uint256 _maxAmount) internal {
        require(_intervalFreezeBlock > 0);
        require(_percent > 0);
        rule.intervalFreezeBlock = _intervalFreezeBlock;
        rule.percent = _percent;
        rule.initRule = true;
        rule.maxAmount = _maxAmount;
        rule.remainAmount = _maxAmount;
    }

    function freezeAmount(Rule storage rule, uint256 baseAmount, uint256 startFrozenBlock, uint256 lastFreezeBlock, uint256 currentBlock) internal view returns(uint256) {
        require(startFrozenBlock <= lastFreezeBlock, "startFrozenBlockmust be greater than or equal to lastFreezeBlock");
        if(currentBlock < lastFreezeBlock){
            return 0;
        }
        require(currentBlock >= lastFreezeBlock);
        require(baseAmount > 0, "baseAmount cant not be 0");
        require(rule.percent > 0);
        uint256 actualFactor =  currentBlock.sub(startFrozenBlock).div(rule.intervalFreezeBlock);
        uint256 alreadyFactor = lastFreezeBlock.sub(startFrozenBlock).div(rule.intervalFreezeBlock);
        require(actualFactor >= alreadyFactor, "invalid factor");
        uint256 factor = actualFactor - alreadyFactor;
        return baseAmount.mul(rule.percent).mul(factor).div(100);
    }
}
