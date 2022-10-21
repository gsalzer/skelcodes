// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./SafeMath.sol";

/**
 * @dev savix interest and supply calculations.
 *
*/
 library SavixSupply {
     
    uint256 public constant MAX_UINT256 = 2**256 - 1;
    uint256 public constant MAX_UINT128 = 2**128 - 1;
    uint public constant MINTIMEWIN = 60;
    uint public constant SECPERDAY = 3600 * 24;
    uint public constant DECIMALS = 9;

    struct SupplyWinBoundery 
    {
        uint256 x1;
        uint256 x2;
        uint256 y1;
        uint256 y2;
    }

    struct AdjustedSupplyData 
    {
        uint256 newSupply;
        uint256 adjustTime;
        uint adjustGradient;
    }
    
    function getSupplyWindow(uint256[2][] memory map, uint256 calcTime) internal pure returns (SupplyWinBoundery memory)
    {
        SupplyWinBoundery memory winBound;
        
        winBound.x1 = 0;
        winBound.x2 = 0;

        winBound.y1 = map[0][1];
        winBound.y2 = 0;

        for (uint i=0; i < map.length; i++) {
            if (map[i][0] == 0) continue;
            if (calcTime < map[i][0])
            {
                winBound.x2 = map[i][0];
                winBound.y2 = map[i][1];
                break;
            }
            else
            {
                winBound.x1 = map[i][0];
                winBound.y1 = map[i][1];
            }
        }
        if (winBound.x2 == 0) winBound.x2 = MAX_UINT256;
        if (winBound.y2 == 0) winBound.y2 = MAX_UINT128;
        return winBound;
    }


    // function to calculate new Supply with SafeMath for divisions only, shortest (cheapest) form
    function getAdjustedSupply(uint256[2][] memory map, uint256 transactionTime, uint256 lastAdjustTime, uint256 currentSupply, uint constGradient) internal pure returns (AdjustedSupplyData memory)
    {
        AdjustedSupplyData memory supplyData;
        supplyData.newSupply = currentSupply;
        supplyData.adjustTime = transactionTime;
        supplyData.adjustGradient = 0;
        
        // return unchanged supply if less than MINTIMEWIN secounds have passed
        // if (lastAdjustTime > 0 && transactionTime - lastAdjustTime < MINTIMEWIN)
        if (transactionTime - lastAdjustTime < MINTIMEWIN)
        {
            return (supplyData);
        }

        if (transactionTime >= map[map.length-1][0])
        {
            supplyData.newSupply = map[map.length-1][1] + constGradient * (transactionTime - map[map.length-1][0]);
            supplyData.adjustGradient = constGradient;
            
            return (supplyData);
        }
        
        SupplyWinBoundery memory winBound = getSupplyWindow(map, transactionTime);
        supplyData.adjustGradient = SafeMath.div(winBound.y2 - winBound.y1, winBound.x2 - winBound.x1);
        supplyData.newSupply = winBound.y1 + supplyData.adjustGradient * (transactionTime - winBound.x1);

        return (supplyData);
    }

    function getDailyInterest(uint256 currentTime, uint256 lastAdjustTime, uint256 currentSupply, uint256 lastSupply) internal pure returns (uint)
    {
            if (currentTime <= lastAdjustTime)
                return currentTime;
                
            uint256 InterestSinceLastAdjust = SafeMath.div((currentSupply - lastSupply) * 100 * 10**DECIMALS, lastSupply);
            return (SafeMath.div(InterestSinceLastAdjust * SECPERDAY, currentTime - lastAdjustTime));
    }
 }
