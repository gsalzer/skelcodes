// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
contract TenetMine is Ownable {
    using SafeMath for uint256;
    struct MinePeriodInfo {
        uint256 tenPerBlockPeriod;
        uint256 totalTenPeriod;
    }
    uint256 public bonusEndBlock;
    uint256 public bonus_multiplier;
    uint256 public bonusTenPerBlock;
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public subBlockNumerPeriod;
    uint256 public totalSupply;
    MinePeriodInfo[] public allMinePeriodInfo;

    constructor(
        uint256 _startBlock,   
        uint256 _bonusEndBlockOffset,
        uint256 _bonus_multiplier,
        uint256 _bonusTenPerBlock,
        uint256 _subBlockNumerPeriod,
        uint256[] memory _tenPerBlockPeriod
    ) public {
        startBlock = _startBlock>0 ? _startBlock : block.number + 1;
        bonusEndBlock = startBlock.add(_bonusEndBlockOffset);
        bonus_multiplier = _bonus_multiplier;
        bonusTenPerBlock = _bonusTenPerBlock;
        subBlockNumerPeriod = _subBlockNumerPeriod;
        totalSupply = bonusEndBlock.sub(startBlock).mul(bonusTenPerBlock).mul(bonus_multiplier);
        for (uint256 i = 0; i < _tenPerBlockPeriod.length; i++) {
            allMinePeriodInfo.push(MinePeriodInfo({
                tenPerBlockPeriod: _tenPerBlockPeriod[i],
                totalTenPeriod: totalSupply
            }));
            totalSupply = totalSupply.add(subBlockNumerPeriod.mul(_tenPerBlockPeriod[i]));
        }
        endBlock = bonusEndBlock.add(subBlockNumerPeriod.mul(_tenPerBlockPeriod.length));        
    }
    function set_startBlock(uint256 _startBlock) public onlyOwner {
		require(block.number < _startBlock, "set_startBlock: startBlock invalid");
        uint256 bonusEndBlockOffset = bonusEndBlock.sub(startBlock);
        startBlock = _startBlock>0 ? _startBlock : block.number + 1;
        bonusEndBlock = startBlock.add(bonusEndBlockOffset);
        endBlock = bonusEndBlock.add(subBlockNumerPeriod.mul(allMinePeriodInfo.length));
	}
    function getMinePeriodCount() public view returns (uint256) {
        return allMinePeriodInfo.length;
    }
    function calcMineTenReward(uint256 _from,uint256 _to) public view returns (uint256) {
        if(_from < startBlock){
            _from = startBlock;
        }
        if(_from >= endBlock){
            return 0;
        }
        if(_from >= _to){
            return 0;
        }
        uint256 mineFrom = calcTotalMine(_from);
        uint256 mineTo= calcTotalMine(_to);
        return mineTo.sub(mineFrom);
    }
    function calcTotalMine(uint256 _to) public view returns (uint256 totalMine) {
        if(_to <= startBlock){
            totalMine = 0;
        }else if(_to <= bonusEndBlock){
            totalMine = _to.sub(startBlock).mul(bonusTenPerBlock).mul(bonus_multiplier);
        }else if(_to < endBlock){
            uint256 periodIndex = _to.sub(bonusEndBlock).div(subBlockNumerPeriod);
            uint256 periodBlock = _to.sub(bonusEndBlock).mod(subBlockNumerPeriod);
            MinePeriodInfo memory minePeriodInfo = allMinePeriodInfo[periodIndex];
            uint256 curMine = periodBlock.mul(minePeriodInfo.tenPerBlockPeriod);
            totalMine = curMine.add(minePeriodInfo.totalTenPeriod);
        }else{
            totalMine = totalSupply;
        }
    }    
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to,uint256 _end,uint256 _tokenBonusEndBlock,uint256 _tokenBonusMultipler) public pure returns (uint256) {
        if(_to > _end){
            _to = _end;
        }
        if(_from>_end){
            return 0;
        }else if (_to <= _tokenBonusEndBlock) {
            return _to.sub(_from).mul(_tokenBonusMultipler);
        } else if (_from >= _tokenBonusEndBlock) {
            return _to.sub(_from);
        } else {
            return _tokenBonusEndBlock.sub(_from).mul(_tokenBonusMultipler).add(_to.sub(_tokenBonusEndBlock));
        }
    }    
}

