pragma solidity 0.4.24;
import "./PaintsPool.sol";
import "./PaintDiscount.sol";
import "./Modifiers.sol";
import "./Utils.sol";

contract Game is PaintDiscount, PaintsPool, Modifiers {
    using SafeMath for uint;

     //функция оценивающая сколько будет стоить функция закрашивания
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint totalCallPrice) {

        uint moneySpent = moneySpentByUserForColor[_color][msg.sender];
        bool hasDiscount = hasPaintDiscountForColor[_color][msg.sender];
        uint discount = usersPaintDiscountForColor[_color][msg.sender];
        
        for (uint i = 0; i < _pixels.length; i++) {
            
            uint discountCallPrice = (nextCallPriceForColor[_color].mul(100 - discount)).div(100);
            
            if (hasDiscount == true) 
                uint price = discountCallPrice;
            else
                price = nextCallPriceForColor[_color]; 

            totalCallPrice += price;
            moneySpent += price;

            if (moneySpent >= 1 ether) {
                
                hasDiscount = true;
                discount = moneySpent / 1 ether;
                
                if (moneySpent >= 10 ether)
                    discount = 10;
            }
            
        }   
    }

    function drawTimeBank() public {

        uint lastPaintTime = lastPaintTimeForRound[currentRound];
        require ((now - lastPaintTime) > 20 minutes && lastPaintTime != 0, "20 minutes have not passed yet.");

        //распределяем банк времени команде раунда
        //победитель текущего раунда - последний закрасивший пиксель пользователь за этот раунд
        winnerOfRound[currentRound] = lastPainterForRound[currentRound];

        //разыгранный банк этого раунда = банк времени (1)
        winnerBankForRound[currentRound] = 1; 
        //10% банка времени переходит в следующий раунд
        timeBankForRound[currentRound + 1] = timeBankForRound[currentRound].div(10); 
        //45% банка времени распределится между всей командой участников раунда
        timeBankForRound[currentRound] = timeBankForRound[currentRound].mul(45).div(100); 
        //банк цвета переносится на следующий раунд
        colorBankForRound[currentRound + 1] = colorBankForRound[currentRound]; 
        //в этом раунде банк цвета обнуляется
        colorBankForRound[currentRound] = 0; 
        //ивент - был разыгран банк времени (победитель, раунд)
        emit TimeBankPlayed(winnerOfRound[currentRound], currentRound);

        isTBPDistributable = true;
        isGamePaused = true;
        timeBankDrawnForRound[currentRound] = true;

    }

    
    function paint(uint[] _pixels, uint _color, string _refLink) external payable isRegistered(_refLink) isLiveGame() {

        require(msg.value == estimateCallPrice(_pixels, _color), "Wrong call price");
        require(_color > 0 && _color <= totalColorsNumber, "The color with such id does not exist."); 

        // bytes32 refLink32 = Utils.toBytes32(_refLink);
        // require(keccak256(abi.encodePacked(_refLink)) == keccak256(abi.encodePacked()) || refLinkExists[refLink32] == true, "No such referral link exists.");
        
       //проверяем не прошло ли 20 минут с последней раскраски для розыгрыша банка времени
        if ((now - lastPaintTimeForRound[currentRound]) > 20 minutes && 
            lastPaintTimeForRound[currentRound] != 0 && 
            timeBankDrawnForRound[currentRound] == false) {

            drawTimeBank();
            msg.sender.transfer(msg.value);

        }
        
        else {
            //распределяем ставку по банкам
            _setBanks(_color);

            //закрашиваем пиксели
            for (uint i = 0; i < _pixels.length; i++) {
                _paint(_pixels[i], _color);
            }
            
            //распределяем дивиденды (пассивный доход) бенефециариам
            _distributeDividends(_color, _refLink);
        
            //сохраняем значение потраченных пользователем денег на покупку краски данного цвета
            _setMoneySpentByUserForColor(_color); 
            
            //сохраняем значение скидки на покупку краски данного цвета для пользователя
            _setUsersPaintDiscountForColor(_color);

            if (paintsCounterForColor[_color] == 0) {
                paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] = now;
            }

            paintsCounter++; //счетчик закрашивания любым цветом
            paintsCounterForColor[_color] ++; //счетчик закрашивания конкретным цветом
            counterToPainter[paintsCounter] = msg.sender; //счетчик закрашивания => пользователь
            counterToPainterForColor[_color][paintsCounterForColor[_color]] = msg.sender; //счетчик закрашивания конкретным цветом => пользователь

            if (isUserCountedForRound[currentRound][msg.sender] == false) {
                usersCounterForRound[currentRound] = usersCounterForRound[currentRound].add(1);
                isUserCountedForRound[currentRound][msg.sender] = true;
            }
        }

    }   

    //функция закрашивания пикселя цветом
    function _paint(uint _pixel, uint _color) internal {

        //устанавливаем значения для краски в пуле и цену вызова функции paint
        _fillPaintsPool(_color);
        
        require(msg.sender == tx.origin);

        require(_pixel > 0 && _pixel <= totalPixelsNumber, "The pixel with such id does not exist.");

       
        //берем предыдущий цвет данного пикселя
        uint oldColor = pixelToColorForRound[currentRound][_pixel];
    
        //перекрашиваем в новый цвет
        pixelToColorForRound[currentRound][_pixel] = _color; 
            
        //cохраняем предыдущий цвет в маппинге
        pixelToOldColorForRound[currentRound][_pixel] = oldColor; 
                
        //время последнего закрашивания во всем игровом поле в этом раунде
        lastPaintTimeForRound[currentRound] = now; 
    
        //самый последний разукрасивший пользователь на всем игровом поле в этом раунде
        lastPainterForRound[currentRound] = msg.sender;
                
        //если счетчик старого цвета положительный, уменьшаем его значение
        if (colorToPaintedPixelsAmountForRound[currentRound][oldColor] > 0) 
            colorToPaintedPixelsAmountForRound[currentRound][oldColor] = colorToPaintedPixelsAmountForRound[currentRound][oldColor].sub(1); 
    
        //при каждой раскраске пикселя, увеличиваем счетчик цвета
        colorToPaintedPixelsAmountForRound[currentRound][_color] = colorToPaintedPixelsAmountForRound[currentRound][_color].add(1); 

        //увеличиваем значение общего количества разукрашиваний данным цветом для итерации команды цвета
        colorToTotalPaintsForCBIteration[cbIteration][_color] = colorToTotalPaintsForCBIteration[cbIteration][_color].add(1);

        //увеличиваем значение общего количества разукрашиваний любым цветом для всего раунда
        totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(1); 

        pixelToPaintTimeForRound[currentRound][_pixel] = now;

        //если пользователь делал ставку данным цветом в течение 24 часов, повышаем его долю участия в команде времени
        if (lastPaintTimeOfUser[msg.sender] != 0 && now - lastPaintTimeOfUser[msg.sender] < 24 hours) 
            timeBankShare[tbIteration][msg.sender]++;
            
        else    
            timeBankShare[tbIteration][msg.sender] = 1;

        //если пользователь делал ставку данным цветом в течение 24 часов, повышаем его долю участия в команде цвета
        if (lastPaintTimeOfUserForColor[_color][msg.sender] != 0 && now - lastPaintTimeOfUserForColor[_color][msg.sender] < 24 hours) 
            colorBankShare[cbIteration][_color][msg.sender]++;

        else 
            colorBankShare[cbIteration][_color][msg.sender] = 1;

        lastPaintTimeOfUser[msg.sender] = now;
        lastPaintTimeOfUserForColor[_color][msg.sender] = now;
                
        //с каждым закрашиванием декреминтируем на 1 ед краски
        paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]].sub(1);
        
        //сохраняем значени поседнего закрашенного пикселя за раунд
        lastPaintedPixelForRound[currentRound] = _pixel;
        
        //ивент - закрашивание пикселя (пиксель, цвет, закрасивший пользователь)
        emit Paint(_pixel, _color, msg.sender, currentRound, now);    

        //устанавливаем значение последнего сыгранного раунда для пользователя равным текущему раунду
        lastPlayedRound[msg.sender] = currentRound;
            
        //проверяем не закрасилось ли все игровое поле данным цветом для розыгрыша банка цвета
        if (colorToPaintedPixelsAmountForRound[currentRound][_color] == totalPixelsNumber) {

            //цвет победивший в текущем раунде
            winnerColorForRound[currentRound] = _color;

            //распределяем банк цвета команде цвета
            winnerOfRound[currentRound] = lastPainterForRound[currentRound];        
            
            winnerBankForRound[currentRound] = 2;//разыгранный банк этого раунда = банк цвета (2)

            //50% банка цвета распределится между командой цвета раунда
            colorBankForRound[currentRound] = colorBankForRound[currentRound].div(2);

            timeBankForRound[currentRound + 1] = timeBankForRound[currentRound];//банк времени переносится на следующий раунд
            timeBankForRound[currentRound] = 0;//банк времени в текущем раунде обнуляется      
            emit ColorBankPlayed(winnerOfRound[currentRound], currentRound);  
            
            isGamePaused = true;
            isCBPDistributable = true;
            //distributeCBP();
        }
    }

    //функция распределения ставки
    function _setBanks(uint _color) private {
        
        colorBankToColorForRound[currentRound][_color] = colorBankToColorForRound[currentRound][_color].add(msg.value.mul(40).div(100));

        //40% ставки идет в банк цвета
        colorBankForRound[currentRound] = colorBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //40% ставки идет в банк времени
        timeBankForRound[currentRound] = timeBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //20% ставки идет на пассивные доходы бенефециариев
        dividendsBank = dividendsBank.add(msg.value.div(5)); 
    }

    //функция распределения дивидендов (пассивных доходов) - будет работать после подключения инстансов контрактов Цвета и Пикселя
    function _distributeDividends(uint _color, string _refLink) internal {
        
        //require(ownerOfColor[_color] != address(0), "There is no such color");
        bytes32 refLink32 = Utils.toBytes16(_refLink);
    
        //if  reflink provided
        if (refLinkExists[refLink32] == true) { 

            //25% дивидендов распределяем организаторам (может быть смарт контракт)
            pendingWithdrawals[founders] = pendingWithdrawals[founders].add(dividendsBank.div(4)); 

            //25% дивидендов распределяем бенефециарию цвета
            pendingWithdrawals[ownerOfColor[_color]] += dividendsBank.div(4);

            pendingWithdrawals[ownerOfPixel] += dividendsBank.div(4);

            //25% дивидендов распределяем реферу
            pendingWithdrawals[refLinkToUser[refLink32]] += dividendsBank.div(4);
            dividendsBank = 0;
        }

        else {

            pendingWithdrawals[founders] = pendingWithdrawals[founders].add(dividendsBank.div(3)); 
            pendingWithdrawals[ownerOfColor[_color]] += dividendsBank.div(3);
            pendingWithdrawals[ownerOfPixel] += dividendsBank.div(3);
            dividendsBank = 0;
        }
    }

    modifier isRegistered(string _refLink) {
        //если пользователь еще не зарегистрирован
        if (isRegisteredUser[msg.sender] != true) {
            bytes32 refLink32 = Utils.toBytes16(_refLink);
            //если такая реф ссылка действительно существует 
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

}
