pragma solidity 0.4.24;
import "./PaintsPool.sol";
import "./PaintDiscount.sol";
import "./CashBack.sol";
import "./Utils.sol";

contract Game is PaintDiscount, PaintsPool, CashBack {
    using SafeMath for uint;

    // set new value of priceLimitPaints
    function setPriceLimitPaints(uint _paintsNumber) external onlyAdmin() {
        priceLimitPaints = _paintsNumber;
    }

    // function estimating call price for given color
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint totalCallPrice) {
        uint moneySpent = moneySpentByUser[msg.sender];
        bool hasDiscount = hasPaintDiscount[msg.sender];
        uint discount = usersPaintDiscount[msg.sender];

        // next paint number
        uint curPaintNum = totalPaintsForRound[currentRound] + 1;

        // external call – add extra paints
        if (!isPaintCall) {
            curPaintNum += priceLimitPaints;
        }

        uint curPrice = _getPaintPrice(curPaintNum);  // price for next painting without discount
        uint price = curPrice;  // price for next painting

        for (uint i = 0; i < _pixels.length; i++) {
            if (hasDiscount) {
                price = curPrice.mul(100 - discount).div(100); // discount call price
            }

            totalCallPrice += price;
            moneySpent += price;

            if (moneySpent >= 1 ether) {
                hasDiscount = true;
                discount = moneySpent / 1 ether;

                if (moneySpent >= 10 ether) {
                    discount = 10;
                }
            }
        }

    }

    function drawTimeBank() public {
        uint curRound = currentRound;
        uint lastPaintTime = lastPaintTimeForRound[curRound];
        require ((now - lastPaintTime) > 20 minutes && lastPaintTime > 0, "20 minutes have not passed yet.");

        address winner = lastPainterForRound[curRound];
        uint curTbIter = tbIteration;
        uint prize = timeBankForRound[curRound].mul(90).div(100);  // 90% of time bank goes to winner;

        winnerOfRound[curRound] = winner;  // set winner of round
        winnerBankForRound[curRound] = 1;  // timebank(1) was drawn for this round
        timeBankForRound[curRound + 1] = timeBankForRound[curRound].div(10);  // 10% of time bank goes to next round
        timeBankForRound[curRound] = prize;

        colorBankForRound[curRound + 1] = colorBankForRound[curRound];  // color bank goes to next round
        colorBankForRound[curRound] = 0;

        // change global state - new game
        currentRound = curRound.add(1);
        tbIteration = curTbIter.add(1);
        _resetPaintsPool();

        // transfer time bank to winner
        winner.transfer(prize);
        emit TimeBankWithdrawn(curRound, curTbIter, winner, prize);
    }

    function paint(uint[] _pixels, uint _color, string _refLink) external payable isRegistered(_refLink) isLiveGame() {
        require (_pixels.length >= 1 && _pixels.length <= 15, "The number of pixels should be from 1 to 15 pixels");
        require(_color > 0 && _color <= totalColorsNumber, "The color with such id does not exist.");

        // drawTimeBank call and exit if 20 minutes passed since last paint
        if ((now - lastPaintTimeForRound[currentRound]) > 20 minutes &&
            lastPaintTimeForRound[currentRound] > 0) {

            drawTimeBank();
            msg.sender.transfer(msg.value);
            return;
        }

        // call estimateCallPrice from paint function
        isPaintCall = true;
        uint callPrice = estimateCallPrice(_pixels, _color);
        isPaintCall = false;

        require(msg.value >= callPrice, "Wrong call price – insufficient funds");

        // Add remaining money
        if (msg.value - callPrice > 0) {
            uint remainingMoney = msg.value - callPrice;
            // Update cashback amount for msg.sender
            cashBackCalculated[msg.sender] = cashBackCalculated[msg.sender].add(remainingMoney);
        }

        // distribute money to banks, cashBack and dividends
        if (totalPaintsForRound[currentRound] == 0) {
            // need for first cashback distribution to first painter
            totalPaintsForRound[currentRound] = _pixels.length;
            userPaintsForRound[currentRound][msg.sender] = _pixels.length;
            _setBanks(_color, _refLink, callPrice);
        } else {
            // for other cases – distribute cashback to prev painters
            _setBanks(_color, _refLink, callPrice);
            totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(_pixels.length);
            userPaintsForRound[currentRound][msg.sender] = userPaintsForRound[currentRound][msg.sender].add(_pixels.length);
        }

        colorToTotalPaintsForCBIteration[cbIteration][_color] = colorToTotalPaintsForCBIteration[cbIteration][_color].add(_pixels.length);

        //paint pixels
        for (uint i = 0; i < _pixels.length; i++) {
            _paint(_pixels[i], _color);
        }

        // save user spended money for this color
        _setMoneySpentByUserForColor(_color);

        _setUsersPaintDiscountForColor(_color);

        if (paintsCounterForColor[_color] == 0) {
            paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] = now;
        }

        paintsCounter++; //counter for all users paints
        paintsCounterForColor[_color]++; //counter for given color
        counterToPainter[paintsCounter] = msg.sender; //counter for given user
        counterToPainterForColor[_color][paintsCounterForColor[_color]] = msg.sender;

        if (isUserCountedForRound[currentRound][msg.sender] == false) {
            usersCounterForRound[currentRound] = usersCounterForRound[currentRound].add(1);
            isUserCountedForRound[currentRound][msg.sender] = true;
        }

        // check the winning in color bank
        if (winnerBankForRound[currentRound] == 2) {
            _drawColorBank();
        }
    }

    function _paint(uint _pixel, uint _color) internal {
        //set paints amount in a pool and price for paint
        _fillPaintsPool(_color);

        require(msg.sender == tx.origin, "Can not be a contract");
        require(_pixel > 0 && _pixel <= totalPixelsNumber, "The pixel with such id does not exist.");

        uint oldColor = pixelToColorForRound[currentRound][_pixel];

        pixelToColorForRound[currentRound][_pixel] = _color; // save old color for pixel
        pixelToOldColorForRound[currentRound][_pixel] = oldColor; // set new color for pixel

        lastPaintTimeForRound[currentRound] = now;
        lastPainterForRound[currentRound] = msg.sender;

        // decrease number of old color pixels
        if (colorToPaintedPixelsAmountForRound[currentRound][oldColor] > 0) {
            colorToPaintedPixelsAmountForRound[currentRound][oldColor] = colorToPaintedPixelsAmountForRound[currentRound][oldColor].sub(1);
        }

        // increase number of new color pixels
        colorToPaintedPixelsAmountForRound[currentRound][_color] = colorToPaintedPixelsAmountForRound[currentRound][_color].add(1);

        pixelToPaintTimeForRound[currentRound][_pixel] = now;

        lastPaintTimeOfUser[msg.sender] = now;
        lastPaintTimeOfUserForColor[_color][msg.sender] = now;

        // decrease paints pool by 1
        paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]].sub(1);

        lastPaintedPixelForRound[currentRound] = _pixel;
        lastPlayedRound[msg.sender] = currentRound;

        emit Paint(_pixel, _color, msg.sender, currentRound, now);

        // check wherether all pixels are the same color
        if (colorToPaintedPixelsAmountForRound[currentRound][_color] == totalPixelsNumber) {
            winnerColorForRound[currentRound] = _color;
            winnerOfRound[currentRound] = lastPainterForRound[currentRound];

            // color bank is 2
            winnerBankForRound[currentRound] = 2;

            // 10% of colorbank goes to next round
            colorBankForRound[currentRound + 1] = colorBankForRound[currentRound].div(10);

            // 90% of colorbank for winner
            colorBankForRound[currentRound] = colorBankForRound[currentRound].mul(90).div(100);

            //timebank goes to next round
            timeBankForRound[currentRound + 1] = timeBankForRound[currentRound];
            timeBankForRound[currentRound] = 0;
        }
    }

    function _setBanks(uint _color, string _refLink, uint _callPrice) private {
        bytes32 refLink32 = Utils.toBytes16(_refLink);

        uint valueToTimeBank = _callPrice.mul(40).div(100);  // 40% to TimeBank
        uint valueToColorBank = _callPrice.div(10);  // 10% to ColorBank
        uint valueToLuckyPot = _callPrice.div(20);  // 5% to LuckyPot
        uint valueGameFee = _callPrice.div(20);  // 5% Game Fee to Founders
        uint valueRef = _callPrice.div(20);  // 5% to Referrer
        uint valueCashBack = _callPrice.mul(35).div(100);  // 35% CashBack (+ valueRef without Referrer)

        // reflink provided
        if (refLinkExists[refLink32]) {
            pendingWithdrawals[refLinkToUser[refLink32]] = pendingWithdrawals[refLinkToUser[refLink32]].add(valueRef);
            _distributeCashBack(valueCashBack);  // CashBack with Refferer
        } else {
            _distributeCashBack(valueCashBack + valueRef);  // CashBack without Refferer
        }

        // set bank states
        timeBankForRound[currentRound] = timeBankForRound[currentRound].add(valueToTimeBank);
        colorBankForRound[currentRound] = colorBankForRound[currentRound].add(valueToColorBank);
        colorBankToColorForRound[currentRound][_color] = colorBankToColorForRound[currentRound][_color].add(valueToColorBank);
        luckyPotBank = luckyPotBank.add(valueToLuckyPot);
        pendingWithdrawals[founders] = pendingWithdrawals[founders].add(valueGameFee);
    }

    function _drawColorBank() private {
        uint curRound = currentRound;
        uint curCbIter = cbIteration;
        address winner = winnerOfRound[curRound];
        uint prize = colorBankForRound[curRound];

        // change global state - new game
        currentRound = curRound.add(1);
        cbIteration = curCbIter.add(1);
        _resetPaintsPool();

        // transfer color bank to winner
        winner.transfer(prize);
        emit ColorBankWithdrawn(curRound, curCbIter, winner, prize);
    }

    function _resetPaintsPool() private {
        uint firstPaintGenForColor = 1;

        for (uint i = 1; i <= totalColorsNumber; i++){
            callPriceForColor[i] = 0.005 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            currentPaintGenForColor[i] = firstPaintGenForColor;

            paintGenToAmountForColor[i][firstPaintGenForColor] = maxPaintsInPool;
            paintGenStartedForColor[i][firstPaintGenForColor] = true;
            paintGenToStartTimeForColor[i][firstPaintGenForColor] = now;
        }
    }

    modifier isRegistered(string _refLink) {

        if (isRegisteredUser[msg.sender] != true) {
            bytes32 refLink32 = Utils.toBytes16(_refLink);

            if (refLinkExists[refLink32]) {
                address referrer = refLinkToUser[refLink32];
                referrerToReferrals[referrer].push(msg.sender);
                referralToReferrer[msg.sender] = referrer;
                hasReferrer[msg.sender] = true;
            }
            uniqueUsersCount = uniqueUsersCount.add(1);
            newUserToCounter[msg.sender] = uniqueUsersCount;
            registrationTimeForUser[msg.sender] = now;
            isRegisteredUser[msg.sender] = true;
        }
        _;
    }

    function _getPaintPrice(uint _number) private pure returns (uint) {
        uint paintPrice = uint((int(_sqrt(_number * 22222222 + 308641358025)) - 7777777)*1e18 / 12345678 + 0.589996*1e18);
        uint temp = 1e13;  // for round - 10^-5
        return ((paintPrice + temp - 1) / temp) * temp;
    }

    // gives square root of given x.
    function _sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
