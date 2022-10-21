pragma solidity 0.5.8;
/*
 *	Lottery 5 of 36 (Weekly) v0.0.4
 */


contract SmartLotto {

    // CONSTANTS //////////////////////////////////////////////////////////////////////////////////////////////////////
    uint private constant TICKET_PRICE = 0.01 ether;

    uint8 private constant REQ_NUMBERS = 5;
    uint8 private constant MAX_NUMBER = 36;
    uint8 private constant MIN_WIN_MATCH = 2;
    uint8 private constant ARR_SIZE = REQ_NUMBERS - MIN_WIN_MATCH + 1;

    uint8 private constant DRAW_DOW = 2;
    uint private constant DRAW_HOUR = 16 hours;
    uint private constant BEF_PERIOD = 60 minutes;
    uint private constant AFT_PERIOD = 60 minutes;

    uint8 private constant PERCENT_FUND_PR = 20;
    uint8[ARR_SIZE] private PERCENT_FUNDS = [20, 30, 35, 15];

    // Controll addresses
    address private constant CONTROL = 0x203bF6B46508eD917c085F50F194F36b0a62EB02;
    address payable private constant PR = 0xCD66911b6f38FaAF5BFeE427b3Ceb7D18Dd09F78;
    address payable private constant ADMIN_JACKPOT = 0x531d3Bd0400Ae601f26B335EfbD787415Aa5CB81;

    uint private constant ACTIVITY_PERIOD = 20 weeks;
    uint private constant POOL_SIZE = 50;

    // STRUCTURES /////////////////////////////////////////////////////////////////////////////////////////////////////
    struct Member {
        address payable addr;
        uint8[REQ_NUMBERS] numbers;
        uint8 matchNumbers;
        uint prize;
    }

    struct Game {
        uint membersCounter;
        uint winnersCounter;
        uint8[REQ_NUMBERS] winNumbers;
        uint totalFund;
        uint[ARR_SIZE] funds;
        uint[ARR_SIZE] winners;
        uint8 status;
        mapping(uint => Member) members;
        mapping(uint => uint) winTickets;
    }

    // VARIABLES //////////////////////////////////////////////////////////////////////////////////////////////////////
    uint8 private contractStatus = 1;

    uint private gameNum = 1;
    mapping(uint => Game) private games;

    uint private firstActivityTime = 0;
    uint private lastActivityTime = 0;
    uint private adminJackpotAmount = 0;
    
    uint private poolCounter = 0;
    uint private controlPhase = 0;

    // EVENTS /////////////////////////////////////////////////////////////////////////////////////////////////////////
    // _action: 0 - New game, 1 - Change status (Drawing), 2 - Jackpot change
    event GameChanged(uint _gameNum, uint8 _action);
    event MemberChanged(uint _gameNum, uint _member, uint _prize);

    // API ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // For any status
    function getGameInfo(uint gamenum) public view returns 
            (uint _gamenum, uint _membersCounter, uint _totalFund, uint8 _status) {
        if (gamenum == 0) gamenum = gameNum;
        return (gamenum, games[gamenum].membersCounter, games[gamenum].totalFund, games[gamenum].status);
    }
    // For any status
    function getGameFunds(uint gamenum) public view returns (uint[ARR_SIZE] memory _funds) {
        if (games[gamenum].status > 0)
            _funds = games[gamenum].funds;
        else
            _funds = calcGameFunds();
        return _funds;
    }
    // For status > 0
    function getGameWinNumbers(uint gamenum) public view returns (uint8[REQ_NUMBERS] memory _winNumbers) {
        return games[gamenum].winNumbers;
    }
    // For status == 2
    function getGameWinners(uint gamenum) public view returns (uint[ARR_SIZE] memory _winners) {
        return games[gamenum].winners;
    }

    function getMemberInfo(uint gamenum, uint member) public view returns 
        (address _addr, uint _prize, uint8[REQ_NUMBERS] memory _numbers) {
        Member memory mbr = games[gamenum].members[member];
        return (mbr.addr, mbr.prize, mbr.numbers);
    }

    // FUNCTIONS //////////////////////////////////////////////////////////////////////////////////////////////////////
    // ENTRY POINT
    function() external payable {
        
        // Check contract status
        require(contractStatus == 1, "Contract closed.");
        
        // CONTROL
        if (msg.sender == CONTROL) {
            doControl();
            return;
        }
        
        // For admin & user game status must be 0
        require(games[gameNum].status == 0, "The game is drawing, try again later.");
        
        // ADMIN JACKPOT
        if (msg.sender == ADMIN_JACKPOT) {
            doAdminJackpot();
            return;
        }
        // USER
        uint8 weekday = getWeekday(now);
        uint nowMinute = getDayMinute(now);
        bool isDrawTime = (weekday == DRAW_DOW && (nowMinute > (DRAW_HOUR - BEF_PERIOD) / 60) && (nowMinute < (DRAW_HOUR + AFT_PERIOD) / 60));
        
        require(!isDrawTime, "The game is drawing, try again later.");
        require(msg.value == TICKET_PRICE, "Value must be '0.01' for play.");
        doUser();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    // Admin Jackpot process
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    function doAdminJackpot() private {
        // If value > 0, increase admin jackpot and jackpot for current game
        if (msg.value > 0) {
            adminJackpotAmount += msg.value;
            games[gameNum].funds[ARR_SIZE - 1] += msg.value;               // Increase last funds elem
            emit GameChanged(gameNum, 2);
            return;
        }
        returnAdminJackpot();
    }
    
    // Return admin jackpot after ACTIVITY PERIOD
    function returnAdminJackpot() private {
        // Requires
        require(adminJackpotAmount > 0, 
            "Admin Jackpot amount must be greater than 0.");
        uint gameJackpotAmount = games[gameNum].funds[ARR_SIZE - 1];
        require(gameJackpotAmount > adminJackpotAmount * 2 || (now - firstActivityTime) > ACTIVITY_PERIOD,
            "Jackpot return is not currently available.");

        if (gameJackpotAmount > adminJackpotAmount) {
            ADMIN_JACKPOT.transfer(adminJackpotAmount);
            games[gameNum].funds[ARR_SIZE - 1] -= adminJackpotAmount;
        } else {
            ADMIN_JACKPOT.transfer(gameJackpotAmount);
            games[gameNum].funds[ARR_SIZE - 1] = 0;
        }
        adminJackpotAmount = 0;
        emit GameChanged(gameNum, 2);

    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    // Control process
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    function doControl() private {
        require(msg.value == 0, "Control value must be 0.");
        // First time check contract activity and generate winning numbers
        if (games[gameNum].status == 0) {
            // Check contract activity
            checkContractActivity();
            if (contractStatus == 0) return;
            // Change game status to "Draw"
            games[gameNum].status = 1;
            // Generate winning numbers
            games[gameNum].winNumbers = generateNumbers();
            // Transfer PR fund
            uint fundPR = games[gameNum].totalFund * PERCENT_FUND_PR / 100;
            PR.transfer(fundPR);
            // Calculate game funds
            games[gameNum].funds = calcGameFunds();
            emit GameChanged(gameNum, 1);
            // Set control phase to 0 (Calculate)
            controlPhase = 0;
            // Reset pool counter to 0
            poolCounter = 0;
        }

        if (controlPhase == 0) {
            doCalculate();
        } else {
            doPayout();
        }

    }

    function doCalculate() private {

        // Process members list (calculate every match winners)
        uint index;
        uint8 mn;
        uint8[ARR_SIZE] memory _w;
        
        uint start = POOL_SIZE * poolCounter + 1;
        uint end = POOL_SIZE * poolCounter + POOL_SIZE;

        if (end > games[gameNum].membersCounter) end = games[gameNum].membersCounter;

        // Calulate winners for pool 
        for (uint i = start; i <= end; i++) {
            mn = findMatch(games[gameNum].winNumbers, games[gameNum].members[i].numbers);
            // Change ticket match numbers
            if (mn > 0)
                games[gameNum].members[i].matchNumbers = mn;
            // If ticket win prize 
            if (mn >= MIN_WIN_MATCH) {
                _w[mn - MIN_WIN_MATCH]++;
                games[gameNum].winnersCounter++;
                index = games[gameNum].winnersCounter;
                games[gameNum].winTickets[index] = i;
            }
        }

        // Icrease game winners count
        for (uint8 i = 0; i < ARR_SIZE; i++)
            if (_w[i] != 0)
                games[gameNum].winners[i] += _w[i];

        // If last pool
        if (end == games[gameNum].membersCounter) {
            
            // If not exist matches 2/5, 3/5 etc, increase game jackpot on fund2, fund3 etc
            for (uint8 i = 0; i < ARR_SIZE - 1; i++) {
                if (games[gameNum].winners[i] == 0) 
                    games[gameNum].funds[ARR_SIZE - 1] += games[gameNum].funds[i];
            }   

            // Check and transit Jackpot
            if (games[gameNum].winners[ARR_SIZE - 1] != 0) {
                adminJackpotAmount = 0;
            } else {
                games[gameNum + 1].funds[ARR_SIZE - 1] = games[gameNum].funds[ARR_SIZE - 1];
            }

            // Set control phase to 1 (Payout) and reset poolCounter to 0
            controlPhase = 1;
            poolCounter = 0;

        } else {
            poolCounter++;
        }

    }

    function doPayout() private {

        // Process winning tickets list and payout prize
        uint winTicket;
        uint prize;
        uint8 mn;
        uint start = POOL_SIZE * poolCounter + 1;
        uint end = POOL_SIZE * poolCounter + POOL_SIZE;

        if (end > games[gameNum].winnersCounter) end = games[gameNum].winnersCounter;

        // Loop winning tickets and payout RRR
        for (uint i = start; i <= end; i++) {
            winTicket = games[gameNum].winTickets[i];
            mn = games[gameNum].members[winTicket].matchNumbers;
            prize = games[gameNum].funds[mn - MIN_WIN_MATCH] / games[gameNum].winners[mn - MIN_WIN_MATCH];
            games[gameNum].members[winTicket].prize = prize;
            games[gameNum].members[winTicket].addr.transfer(prize);
            emit MemberChanged(gameNum, i, prize);
        }

        if (end == games[gameNum].winnersCounter) {
            // Change game status on "Closed"
            games[gameNum].status = 2;
            // Init Next Game
            gameNum++;
            emit GameChanged(gameNum, 0);
        } else {
            poolCounter++;
        }

    }

    // Check contract activity
    function checkContractActivity() private {
        uint balance = address(this).balance;
        // Set last activity
        if (games[gameNum].membersCounter > 0) {
            lastActivityTime = now;
        }
        // Check last activity
        if (now - lastActivityTime > ACTIVITY_PERIOD) {
            PR.transfer(balance);
            contractStatus = 0;
            games[gameNum].funds[ARR_SIZE - 1] = 0;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    // User process
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    function doUser() private {
        
        // First activity & last activity
        if (firstActivityTime == 0) {
            firstActivityTime = now;
            lastActivityTime = now;
        }
        
        doTicket();
    }
    
    // Ticket process
    function doTicket() private {

        bool err = false;
        uint8[REQ_NUMBERS] memory numbers;

        // Parse and check msg.DATA
        (err, numbers) = parseCheckData();

        uint mbrCnt;

        // If error DATA, generate random ticket numbers
        if (err) {
            numbers = generateNumbers();    
        } else {
            numbers = sortNumbers(numbers);    
        }

        // Increase member counter and total fund
        games[gameNum].membersCounter++;
        games[gameNum].totalFund += msg.value;

        // Store member
        mbrCnt = games[gameNum].membersCounter;
        games[gameNum].members[mbrCnt].addr = msg.sender;
        games[gameNum].members[mbrCnt].numbers = numbers;

        emit MemberChanged(gameNum, mbrCnt, 0);

    }

    // UTILS //////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Get timestamp minute of day
    function getDayMinute(uint timestamp) private pure returns (uint) {
        return ((timestamp / 60) % 1440);
    }

    // Get timestamp day of week
    function getWeekday(uint timestamp) private pure returns (uint8) {
        return uint8((timestamp / 86400 + 4) % 7);
    }
    
    // Generate random number
    function random(uint8 num) internal view returns (uint8) {
        return uint8((uint(blockhash(block.number - 1 - num*2)) + now) % MAX_NUMBER + 1);
    }

    // Generate winning numbers
    function generateNumbers() private view returns (uint8[REQ_NUMBERS] memory numbers) {
        // Generate random numbers
        for (uint8 i = 0; i < REQ_NUMBERS; i++) numbers[i] = random(i);
        // Sort numbers array
        numbers = sortNumbers(numbers);
        // Change dublicate numbers
        for (uint8 i = 0; i < REQ_NUMBERS - 1; i++)
            for (uint8 j = i + 1; j < REQ_NUMBERS; j++)
                if (numbers[i] == numbers[j])
                    numbers[j]++;

        return numbers;
    }

    // Sort array of number function
    function sortNumbers(uint8[REQ_NUMBERS] memory arrNumbers) private pure returns (uint8[REQ_NUMBERS] memory) {
        uint8 temp;
        for (uint8 i = 0; i < REQ_NUMBERS - 1; i++)
            for (uint j = 0; j < REQ_NUMBERS - i - 1; j++)
                if (arrNumbers[j] > arrNumbers[j + 1]) {
                    temp = arrNumbers[j];
                    arrNumbers[j] = arrNumbers[j + 1];
                    arrNumbers[j + 1] = temp;
                }

        return arrNumbers;
    }

    // Find match numbers function
    function findMatch(uint8[REQ_NUMBERS] memory arr1, uint8[REQ_NUMBERS] memory arr2) private pure returns (uint8) {
        uint8 cnt = 0;
        for (uint8 i = 0; i < REQ_NUMBERS; i++)
            for (uint8 j = 0; j < REQ_NUMBERS; j++)
                if (arr1[i] == arr2[j]) {
                    cnt++;
                    break;
                }
        return cnt;
    }

    // Parse and check msg.DATA function
    function parseCheckData() private pure returns (bool, uint8[REQ_NUMBERS] memory) {
        bool err = false;
        uint8[REQ_NUMBERS] memory numbers;

        // Check 5 numbers entered
        if (msg.data.length == REQ_NUMBERS) {
            // Parse DATA string
            for (uint8 i = 0; i < REQ_NUMBERS; i++)
                numbers[i] = uint8(msg.data[i]);

            // Check range: 1 - MAX_NUMBER
            for (uint8 i = 0; i < REQ_NUMBERS; i++)
                if (numbers[i] < 1 || numbers[i] > MAX_NUMBER) {
                    err = true;
                    break;
                }
            // Check dublicate numbers
            if (!err)
                for (uint8 i = 0; i < REQ_NUMBERS - 1; i++) {
                    for (uint8 j = i + 1; j < REQ_NUMBERS; j++) {
                        if (numbers[i] == numbers[j]) {
                            err = true;
                            break;
                        }
                    }
                    if (err) break;
                }
        } else {
            err = true;
        }
        return (err, numbers);
    }
    
    // Calculate game funds
    function calcGameFunds() private view returns (uint[ARR_SIZE] memory funds) {
        uint fundPR = games[gameNum].totalFund * PERCENT_FUND_PR / 100;
        for (uint8 i = 0; i < ARR_SIZE; i++)
            funds[i] = (games[gameNum].totalFund - fundPR) * PERCENT_FUNDS[i] / 100;
        funds[ARR_SIZE - 1] += games[gameNum].funds[ARR_SIZE - 1];
        return funds;
    }

}
