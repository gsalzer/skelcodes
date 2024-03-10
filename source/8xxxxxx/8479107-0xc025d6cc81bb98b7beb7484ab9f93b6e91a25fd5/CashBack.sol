pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";

contract CashBack is Modifiers {
    using SafeMath for uint;

    function cashBackAmount(address _painter) public view returns (uint cashBackInWei) {
        // last cashBack Calculation Round for Painter
        uint round = cashBackCalculationRound[_painter];

        uint calcCashBack = cashBackCalculated[_painter];
        uint curCashBackPerPaint = maxCashBackPerPaintForRound[round].sub(cashBackPerPaintForRound[round][_painter]);
        uint curCashBack = curCashBackPerPaint.mul(userPaintsForRound[round][_painter]);

        cashBackInWei = calcCashBack.add(curCashBack);
    }

    function withdrawCashBack() external isLiveGame() {
        address withdrawer = msg.sender;
        uint curCashBack = cashBackAmount(withdrawer);
        require(curCashBack > 0, "Cashback can not be 0");

        // last cashBack Calculation Round for Withdrawer
        uint round = cashBackCalculationRound[withdrawer];

        // update states
        cashBackCalculated[withdrawer] = 0;
        cashBackPerPaintForRound[round][withdrawer] = maxCashBackPerPaintForRound[round];

        // transfer cashback
        withdrawer.transfer(curCashBack);
        emit CashBackWithdrawn(currentRound, withdrawer, curCashBack);
    }

    function _distributeCashBack(uint _value) internal {
        uint curRound = currentRound;  // gas consumption optimization
        address painter = msg.sender;

        uint totalPaints = totalPaintsForRound[curRound];
        uint curCashBackPerPaint = _value.div(totalPaints);
        uint updCashBackPerPaint = maxCashBackPerPaintForRound[curRound].add(curCashBackPerPaint);

        // update maxCashBackPerPaintForRound state
        maxCashBackPerPaintForRound[curRound] = updCashBackPerPaint;

        // update already earned cashback in this or prev rounds
        cashBackCalculated[painter] = cashBackAmount(painter);

        // update cashBackCalculationRound state
        if (cashBackCalculationRound[painter] < curRound) {
            cashBackCalculationRound[painter] = curRound;
            // add current round cashback
            cashBackCalculated[painter] = cashBackAmount(painter);
        }

        // update cashBackPerPaintForRound state
        cashBackPerPaintForRound[curRound][painter] = updCashBackPerPaint;

        // update totalCashBackForRound state
        totalCashBackForRound[curRound] = totalCashBackForRound[curRound].add(_value);
    }
}
