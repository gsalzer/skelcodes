// <SquareQueue>

/*
MIT License

Copyright (c) 2020 SquareQueue

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
pragma solidity ^0.5.16;

/**
 * @title one of the contracts in the Square Queue - One-dice ver pre-release 0.1. Continuous updates will be developed. Updating to a new version does not delete the legacy contract.
 *
 * @notice Please read the white paper. The comments and CODE of this smart contract are written in plain language and easy CODE for those who are not familiar with programming languages.
 * @author SquareQueue - SquareQueue@gmail.com https://github.com/squarequeue
 *
 * @notice Players can join the game either by using the SquareQueue webpage or by generating transactions directly SquareQueue smart-contract inner function.
 * @dev Join the game with the 'playSubmit' function and receive the result of the game with the __callback function. These two functions have separate tx / block.number but this.smartContract controls everything automatically.
 * SquareQueue is an impartial space that takes advantage of https://provable.xyz/ (Oraclize)'s a random data source to provide end-users with untampered entropy.
 */

import "SafeMath.sol";
import "provableAPI_0.5.sol";

contract SquareQueue is usingProvable {
    using SafeMath for uint;
    uint public playerCount;
    uint public callbackCount;
    uint public minEntryGas;
    uint public minEntryGasCallBack;
    
    constructor () public {
        provable_setProof(proofType_Ledger); // The proof type of the (RNG) random number generator is ledger
        owner = msg.sender;
        ECDSASigner = 0xbFd38732F3bD7Cd3e761ce578386d7E3B091ad24; // ECDSA (ecRecover) will be assigned to the new address.
        minEntryGas = 500000;
        maximumProfit = 5000000000000000000;
        provablelimitBlock = 15;
        provablelimitTime = 5 minutes;
        checkedTime = now;
        preJamCount = 0;
    }
    /**
     * @notice struct Play is used as a database for each game.
     * @param amount - Amount of Ethereum sent by a player to a game.
     * @param modulo - The type of game the player participated in is assigned.
     * @param rollUnder - The variable that will be used in the inverse proportion for the winning rate and prize Ether.
     * @param playBlockNumber - Stores the block number of a game in which the player participates, and is the baseline start block for automatic refunds if the processing is delayed due to unexpected EVM or Ethereum network or Provable(Oraclize) callback issues.
     * @param resultBlockNumber - The block number from which the result of the game is derived.
     * @param mask - It assigns a number or a combination of numbers chosen by the player and will be used to determine the game win or loss using random numbers and Bitwise operations. Details are described in the function contractDetermineExecute inside this contract.
     * @param possibleWinAmount - It is used to lock the contract's funds by pre-calculating ether that the player can obtain.
     * @param trophyIncreaseFee - Deducted by 'trophyFee'% of the player's game amount, and add to the trophy weight.
     * @param playCount - Represents the sequence number of the game.
     * @param player - Assign the player address(msg_sender).
     */
    struct Play {
        uint amount;
        uint modulo;
        uint rollUnder;
        uint playBlockNumber;
        uint resultBlockNumber;
        uint mask;
        uint possibleWinAmount;
        uint trophyIncreaseFee;
        uint playCount;
        uint Tpayment;
        uint Payment;
        address payable player;
    }

    /**
     * @notice a struct that calls a function that guarantees an automatic refund when the player's game state is deadlocked.
     * @notice function __callback, function checkNcleanJam - check if the callback arrived too late, and did not arrive completely, and failed the Random proof Verify test.
     * @param play_number - Game Counting. Same as struct Play @ playCount.
     * @param play_amount - True if the result of the game is derived; false if no result is obtained.
     * @param play_queryId - Individual gameplay unique identifier and a query id for callBack.
     */
    struct CheckJam {
        uint play_number;
        bool play_amount;
        bytes32 play_queryId;
    }
    
    mapping (uint => Play) public playTable;
    mapping (uint => CheckJam) public checkJamDB;

    modifier onlyOwner {
        require (msg.sender == owner, "This function can only create Tx by the owner of the contract.");
        _;
    }

    event submitGameParams(uint playCount, uint eventCode, address indexed player, uint playMask, uint playModulo, uint rollUnder, bytes32 indexed queryId);

    uint public minimumParticipateAmount = 0.1 ether; // a game minimum entry-amount
    uint public maximumParticipateAmount = 10 ether; // a game maximum entry-amount
    uint public playAmountLockedInAccount; // 'playAmountLockedInAccount' is a guarantee that the contract will be able to pay when the player wins.
    uint criticalPlayNumber = 62/*0xFFFFFFFFF*/; // The threshold that prevents the game from overflow.

    /**
     * @notice The owner can adjust entry-amount due to future changes in Ethereum value or any hard fork or gas rate change. 
     * @notice No matter how the owner change these values, the entry-amount variables are declared public, so you can call the value of the Contract at any time, such as through BlockExplorer, and so on.
     */ 
    function SetParticipateAmount(uint _minimumParticipateAmount, uint _maximumParticipateAmount) external onlyOwner {
        minimumParticipateAmount = _minimumParticipateAmount;
        maximumParticipateAmount = _maximumParticipateAmount;
    }

    /**
     * @notice The Provable(Oraclize) Random Data Source leverages the Ledger Proof and a custom application to generate unbiased random numbers. 
     * Parameters of queryId to request a random number.
     * @param numberOfBytes - This value returns a 2^(bit-bytes) entropy value. For example, a value of 4 would result in 2^32.
     * @param delay - Set 0 to run without delay.
     * @param callbackGas - The gasprice of the callback.
     * @param callbackGasAmplify - When the automatic refund loop operation occurs, it temporarily boosts the gas price. This price is supported by the contract, not the player.
     * @dev The values may be changed to optimize the performance of the contract. No matter how the owner change these values, variables are declared public, so you can call the value of the Contract at any time, such as through BlockExplorer, and so on.
     */
    uint public numberOfBytes = 7;
    uint public delay = 0;
    uint public callbackGas = 210000 + 40000;
    uint public callbackGasAmplify;
    uint public loopGas = 3500 + 21000;
    function setRNGqueryParameter(uint _numberOfBytes, uint _delay, uint _callbackGas) external onlyOwner {
        numberOfBytes = _numberOfBytes;
        delay = _delay;
        callbackGas = _callbackGas;
    }
    
    event restPlayAmountLockedInAccount(uint debugCode); // Lines for debugging
    
    /**
     * @notice can modify the variable to check the minimum gas value to ensure that the player has submitted enough gas to play the game.
     * @dev callback fee will be charged even if out of gas occurs. It must be reverted before an "out of gas" occurs.
     * The default is assigned to the constructor, but it can be modified because may need to consider future EVM environments.
     */
    function setMinGasEntry(uint _newGasEntry, uint _loopGas) external onlyOwner {
        minEntryGas = _newGasEntry;
        loopGas = _loopGas;
    }

    function callbackGasCalcul() private {
        minEntryGasCallBack = (jamCount.sub(preJamCount) * loopGas) + callbackGas;
        if (now > checkedTime + provablelimitTime && jamCount.sub(preJamCount) >= 3) {
            callbackGasAmplify = minEntryGasCallBack;
            minEntryGas += minEntryGasCallBack;
        } else {

        }
    }
    
    event test(uint testcode, uint contractfee, uint throphyfee, uint possiblewinamount); // Lines for debugging
    function standardNormalDistributionAndSDF () private {
        
    }
    
    /**
     * @notice This bitwise operation checks how many cases the player has submitted. The function contractDetermineExecute contains information about bitwise.
     * @param cntN play_mask
     * @return Counts how many numbers have selected and return the result. The return value is the ratio of dividends based on the player winning rate.
     */
    function calculatePlayQuota (uint cntN) private pure returns (uint _playQuota) {
        cntN = cntN - ((cntN >> 1) & 1431655765);
        cntN = (cntN & 0x33333333) + ((cntN >> 2) & 0x33333333);
        uint baseQ = ((cntN + (cntN >> 4) & 0xF0F0F0F) * 0x1010101) >> 24; 
        /**
         * Rather than applying the standard normal distribution / SDF / Hypergeometric distribution to values as a function, hard-coding it because there are only six cases.
         * Please note the Square Queue white paper for more details.
         */
        if (baseQ == 1) {return 61400;}if (baseQ == 2) {return 25100;}if (baseQ == 3) {return 17300;}if (baseQ == 4) {return 13900;}if (baseQ == 5) {return 12200;}if (baseQ < 0 || baseQ > 5) {return 0;}
    }
    /**
     * @notice When a transaction occurs in function playSubmit, all the process of game win/loss decision and winning ether transfer or refund will be automatically processed by smart-contracts.
     * @param _playMask Will be assigned to play_mask of struct Play.
     * @param _playModulo Will be assigned to play_modulo of struct Play.
     * @param _submitHash Check the ECDSA (Elliptic Curve Digital Signature Algorithm) signature with param _v, _r, _s. SquareQueue uses Provable (Oraclize) rather than commit-reveal RNGs, so ECDSA is not essential, but it is an effective way to deal with the occurrence of aggressive transactions.    
     */
    function playSubmit(uint _playMask, uint _playModulo, bytes32 _submitHash, uint8 _v, bytes32 _r, bytes32 _s) external payable {
        uint tempMinEntryGas = minEntryGas;
        callbackGasCalcul();
        //Make sure player have enough gas to join the game.
        require(gasleft() > minEntryGas, "There is not enough gas to play the game.");
        minEntryGas = tempMinEntryGas;
        
        address payable play_player = msg.sender;
        uint play_amount = msg.value;
        uint play_modulo = _playModulo;
        uint play_playBlockNumber = block.number;
        uint play_mask = _playMask;

        require (play_modulo == 6 /*|| play_modulo == 72*/, "Only 6 case games are available.");
        require (play_amount >= minimumParticipateAmount && play_amount <= maximumParticipateAmount, "Ehter amount must be within the game playable range.");
        require (play_mask > 0 && play_mask <= criticalPlayNumber, "The numbers chosen by the player must be within the gameable range.");
        require (ECDSASigner == ecrecover(_submitHash, _v, _r, _s), "ECDSA signature is not valid. ");

        /** 
        Players can choose a number of cases to increase their winning probability, but in this case, their dividends will be lower.
        On the contrary to this, dividends can be raised by lowering the winning probability. Everything is up to the player's choice.
        rollUnder is a variable used to calculate dividends by interacting with playMask.
        */
        uint play_rollUnder = calculatePlayQuota(play_mask);
        require (0 < play_rollUnder && play_rollUnder <= play_modulo.mul(10234), "The probability does not exist in the range.");

        uint play_possibleWinAmount;
        uint play_trophyIncreaseFee;

        //Deducted by 'trophyFee'1/10% of the player's game amount, and add to the trophy weight.
        uint _trophyIncreaseFee = play_amount * trophyFee / 1000;
        //Deducted by 'contractFee'1/10% of the player's game amount, and add to the trophy weight.
        uint contractFee = play_amount * contractCommissionPercentage / 1000;
        //It is used to lock the contract's funds by pre-calculating ether that the player can obtain.
        uint _possibleWinAmount = ((play_amount * play_rollUnder).div(10000)) - (contractFee + _trophyIncreaseFee);

        emit test (111, contractFee, _trophyIncreaseFee, _possibleWinAmount); // Lines for debugging
        
        if (trophyWeight + playAmountLockedInAccount + _possibleWinAmount + _trophyIncreaseFee <= address(this).balance) {
            require (_possibleWinAmount <= play_amount.add(maximumProfit), "At this time, it is not possible to play out of the range maximum ether profits of this contract.");

            //Fetch the player's possibleWinAmount&trophyIncreaseFee information into the database.
            play_possibleWinAmount = _possibleWinAmount;
            play_trophyIncreaseFee = _trophyIncreaseFee;

            //Guarantees that all potentially payable ethers are payable.
            playAmountLockedInAccount = playAmountLockedInAccount.add(play_possibleWinAmount);
            trophyWeight = trophyWeight.add(play_trophyIncreaseFee);
        } else {
            revert("There is not enough funds to play your game on SquareQueue Contract.");
        }
        
        /*
         * @dev Note that there is a fee charged for generating queryId even if an error occurs inside the contract after the queryId is generated.
         * @dev It is recommended to create a queryId that generates a callBack if the player can be sure to complete the game without any errors.
         */
        bytes32 queryId = getQueryId();

        // The queryId, which is guaranteed to be unique on the network, is usefully reused as an identifier for each game.
        Play storage play = playTable[uint(queryId)];

        //Make sure the current gameplay is allocated in the free space of the structure database. 
        if (play.player == address(0)) {
            //Fetch the player's current information into the database.
            play.player = play_player;
            play.amount = play_amount;
            play.modulo = play_modulo;
            play.playBlockNumber = play_playBlockNumber;
            play.mask = play_mask;
            play.possibleWinAmount = play_possibleWinAmount;
            play.trophyIncreaseFee = play_trophyIncreaseFee;
            play.rollUnder = play_rollUnder;
        } else {
            revert ("Cannot assign a player to the database.");
        }
        
        //assgin the game play count. Will be used for Function cleanPlayAmountLockedInAccount.
        playerCount = playerCount.add(1);
        
        /*
         * SquareQueue contract's automatic refund system works for gameplay that is deadlocked for any reason due to problems with EVM or Network or callBack or else.
         * To do this and operate a separate DB for easy identification.
         */
        storeJam(queryId);
        
        /**
        All data submitted by the player can be seen transparently through the input data item of the transaction.
        Nevertheless, submitGameParams generates an event to check that the contract's internal function returns correctly even it consumes a bit more gas.
        Players can always check for events using the ethereum block explorer. In addition, players can check their rollUnder and queryId value.
         */
        emit submitGameParams(play.playCount, 100, play.player, play.mask, play.modulo, play.rollUnder, queryId);
    }

    bytes32 public queryidToPerformTheCheck; //Variable that determines whether the game is in turn to run checkNcleanJam

    /**
     * @notice Every time the function provable_query(oraclize_query) is called, it returns a unique ID, hereby referred to as queryId, which is guaranteed to be unique in the given network execution context.
     */
    function getQueryId() private returns(bytes32 _Id) {
        uint _callbackGas = callbackGas;
        bool checkIdBool;

        if (now > checkedTime + provablelimitTime && jamCount.sub(preJamCount) >= 3) {
            _callbackGas = callbackGasAmplify;
            checkIdBool = true;
        }
        _Id = provable_newRandomDSQuery(delay, numberOfBytes, _callbackGas);
        
        if (checkIdBool == true) {
            checkedTime = now;
            queryidToPerformTheCheck = _Id;
            checkIdBool = false;
        } else {
            queryidToPerformTheCheck = 0x1111111111111112222222222233333322112222222211111111111111111111;
        }
        return(_Id);
    }
    
    /**
     * provableRandomValue - Declared for Random Number Generator(RNG) by Provable(Oraclize).
     * provablelimitBlock - SquareQueue will automatically issue a refund if __callback Tx is generated too late due to an unexpected EVM or network or other problem. The criterion is block number.
     * provablelimitTime - SquareQueue will automatically issue a refund if __callback Tx is generated too late due to an unexpected EVM or network or other problem. The criterion is Time.
     * As mentioned in the Ethereum Yellow Paper, Contracts can't get hashes before the latest 256 blocks.(However, 256 blocks are too much time for the user to wait for the game results, so SquareQueue'll cut that down.)
     * So in order to eliminate potential risks, the contract will refund if a callback occurs above the limit block.
     */
    uint provableRandomValue;
    uint public provablelimitBlock;
    uint public provablelimitTime;
    
    function setProvablelimitLine(uint _provablelimitBlock, uint _provablelimitTime) external onlyOwner {
        provablelimitBlock = _provablelimitBlock;
        provablelimitTime = _provablelimitTime;
    }

    uint public contractCommissionPercentage = 7; // n= 0.n% Deduct contract service charge. It is calculated as a percentage of the player's game amount.
    uint public trophyFee = 3; // n=0.n% Deduct trophy weight charge. It is calculated as a percentage of the player's game amount.

    /**
     * @notice The owner can adjust entry-amount due to future changes in Ethereum value or any hard fork or gas rate change. No matter how owner change these values, the entry-amount variables are declared public, so you can call the value of the Contract at any time, such as through BlockExplorer, and so on.
     * @param trophyWeight Trophy prize. This value cannot be changed by anyone, including the owner.
     * @param trophyTicketQualification Entry-amount lower than this value will not be accepted for winning the trophy.
     * @param trophyModulo Chance to win a Trophy 10000 == 0.01%
     * @param maximumProfit As a "wei" unit of "Ether". A player cannot take a prize-amount larger than this value. However, whatever the trophy prize-amount is, a player can earn it separately from this variable.
     * trophyTicketQualification and trophyModulo can be changed by the contract owner (reason for scalability). But, no matter how the owner change these values, variables are declared public, so you can call the value of the Contract at any time, such as through BlockExplorer, and so on.
     */
    uint public trophyWeight;
    uint public trophyTicketQualification = 0.5 ether;
    uint public trophyModulo = 10000;
    uint public maximumProfit;
    bool public trophy_period = false;
    function SetTrophyVariable(uint _trophyTicketQualification, uint _trophyModulo, bool _trophy_period) external onlyOwner {
        trophy_period = _trophy_period;
        trophyTicketQualification = _trophyTicketQualification;
        trophyModulo = _trophyModulo;
    }

    address payable public owner;
    address payable private nextOwner;
    address public ECDSASigner;

    /**
     * All events are written as a basis for transparently operating the return values of this smart contract.
     * Payment - Player Address, amount earned by the player in the game.
     * Tpayment - Player Address, Trophy prize earned by the player.
     * gameQueryIdRandomEntropy - Player Address, Provable(Oraclize) queryId, Random entropy.
     * gameResult - Player Choice(playMask), Game Choice(Random Number Generation Algorithm), The estimated amount of ether acquisition when the player wins.
     *              A player choice does not have to match the game choice perfectly to win the game. There is a wider winning strategy. Details are described in function contractDetermineExecute.
     * automaticRefund - The amount of ether refunded to the automatic refund system, queryId.
     */
    event Payment(uint eventCode, address indexed recipient, uint dividend);
    event Tpayment(uint eventCode, address indexed recipient, uint _tAmount);
    event gameQueryIdRandomEntropy(uint eventCode, address indexed recipient, bytes32 indexed ProvableQueryId, uint entropy);
    event gameResult(bytes32 indexed queryId, uint playCount, uint eventCode, uint PlayerChoice, uint GameChoice, uint payment, uint trophyPayment);
    event automaticRefund(uint eventCode, uint amount, bytes32 indexed queryId);

    /**
     * This function cannot have arguments, cannot return anything and must have external visibility and payable state mutability. 
     * It is executed on a call to the contract with empty calldata. This is the function that is executed on plain Ether transfers (e.g. via .send() or .transfer()). 
     * If no such function exists, but a payable fallback function exists, the fallback function will be called on a plain Ether transfer. 
     * If neither a receive Ether nor a payable fallback function is present, the contract cannot receive Ether through regular transactions and throws an exception.
     */
    //receive() external payable { //solidity 0.6.0
        function() external payable {

    }

    /**
     * In order to change the owner of this contract, the original owner must send a new owner address(function approveNextOwner), 
     * and then the ownership must be changed only after the new owner approves ownership(function acceptNextOwner).
     */
    function approveNextOwner(address payable _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

    /**
     * Assign a new ECDSA Address for SquareQueue.
     * ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address):
     * recover the address associated with the public key from elliptic curve signature or return zero on error. The function parameters correspond to ECDSA values of the signature:
     * r = first 32 bytes of signature s = second 32 bytes of signature v = final 1 byte of signature.
     */
    function setECDSASigner(address _newECDSASigner) external onlyOwner {
        cleaningBlock = block.number;
        prePlayerCount = playerCount;
        ECDSASigner = _newECDSASigner;
    }

    /**
     * If an unexpected error occurs after playSubmit and the Contract is reverted, the funds of the PlayAmountLockedInAccount of the corresponding tx will be locked forever.
     * Funtion contractDetermineExecute, checkNcleanJam solves this problem, but this function is necessary because it doesn't know what will change in the future EVM environment.
     * Don't worry. The send(transfer) statement throws an exception at revert, so all statements such as refunds and payments will be performed.
     * However, funds in PlayAmountLockedInAccount must be released. This function effectively cut off entrance new gameplay by allocating a new ECDSA and not telling the user 
     * the v, r, s values, and allocates 0 to PlayAmountLockedInAccount when more than a refundable block number has passed(If a refund is required, complete all refunds) and there is certainly no new gameplay.
     */
    uint cleaningBlock; // If there is already a game in progress, this variable to wait for the result of games.
    uint prePlayerCount; // If there is gameplay since the new ECDSA address was assigned, this variable prevents cleanLockedInAccountAndPlayCallcount function from executing.
    function cleanLockedInAccountAndPlayCallcount() external onlyOwner {
        require(cleaningBlock + provablelimitBlock <= block.number, "It can be executed after all automatic refunds have been processed.");
        require(prePlayerCount == playerCount, "There is already a user who played the game.");
        
        //If there is a deadlocked player, all ether will be refunded.
        checkNcleanJam();

        playAmountLockedInAccount = 0;
        callbackCount = 0;
    }

    /**
     * SquareQueue can set an upper limit on the amount of game entry and winnings. This value can be associated with maximumParticipateAmount to effectively prevent fund depletion.
     * No matter how the owner changes these values, variables are declared public, so you can call the value of the Contract at any time, such as through BlockExplorer, and so on.
     * and it will not any affect the game in progress.
     */
    function setMaximumProfit(uint _maximumProfit) public onlyOwner {
        maximumProfit = _maximumProfit;
    }

    // The owner of SquareQueue can increase the trophy weight. Of course, can't lower it. Our best wishes go with you.
    function bumpTrophyWeight(uint _bumpAmount) external onlyOwner {
        require (trophyWeight + playAmountLockedInAccount + _bumpAmount <= address(this).balance, "The contract needs to replenish the fund because it is scarce.");
        trophyWeight = trophyWeight.add(_bumpAmount);
    }

    /**
     * SquareQueue can upgrade the Contract and update the current version of the Contract to upgrade the game, add games, or get better.
     * In this case, you have to disable the older version of the Contract, but SquareQueue owner can't break it if there is a game in progress.
     * Thus, SquareQueue owners can use ECDSA variables to limit new game participation and dismiss Contract only after the results of all the games in progress have been obtained.
     */
    function contractDissolution() external onlyOwner {
        require (playAmountLockedInAccount == 0, "There is a game in progress.");
        selfdestruct(owner);
    }

    /**
     * Play_storage_play Call the game and player information via the identifier. 
     * @param _queryId Every time the function provable_query(oraclize_query) is called, it returns a unique ID in the network.
     * @param _entropy Key entropy of random numbers used to derive game results. The random data of provable(oraclize) is leveraging the Ledger proof to prove that the origin of the generated randomness is really a secure Ledger device.
     * @dev Run automatically when SquareQueue gets a callBack from Provable (Oraclize). If the Contract does not receive callBack, it will not run in any case.
     */
    function contractDetermineExecute(Play storage _play,bytes32 _queryId, uint _entropy) private {
        //Get the player's data from the __callback.
        uint _amount = _play.amount;
        uint _modulo = _play.modulo;
        address payable player = _play.player;

        //Check that the player has already participated in the game and is waiting for the result, not a new contract.
        if (_amount != 0 && player != address(0)) {
            _play.amount = 0;
            CheckJam storage checkJam = checkJamDB[_play.playCount];
            checkJam.play_amount = true;
        } else {
            revert ("The player does not exist in the database or is already closed.");
        }
        
        /**
         * game - Modular arithmetic of Provable's random numbers and player game types is used to calculate game base results.
         * gameWin & trophyWin - If the player meets the conditions for winning the prize, it will be replaced by the prize value, or else Zero as it is.
         */
        uint game = _entropy.mod(_modulo);
        uint gameWin = 0;
        uint trophyWin = 0;
        
        /**
         * The SquareQueue SmartContract establishes a foundation that builds on existing Ethereum and Provable(Oraclize) processes while creating transparency and trust with players.
         * These events make the calculation of "SquareQueue SmartContract" more transparent and fair, which is useful for players to check the game result. a player can always check with BlockExplorer or a similar solution, and so on.
         * Details are described in the event comment.
         */
        emit gameQueryIdRandomEntropy(200, _play.player, _queryId, _entropy);

        /**
         * SquareQueue generates a random number using the Random Data Source at https://provable.xyz/ (Oraclize) and uses this random number to calculate the player's winning result.
         * The Provable Random Data Source leverages the Ledger Proof and a custom application to generate unbiased random numbers and provide them on demand to blockchain and non-blockchain based applications.
         * The end applications can perform verification step to unsure that the randomness provided was truly generated in an secure hardware environment provided by a Ledger Nano S.
         * 
         * If the result of the game's random number includes the player's chosen numbers, the player wins the game and wins the prize. 
         * The player can choose only one number or choose multiple numbers. Everything depends on the choice of the player.
         * Consequentially, outcomes of the game have in numerous cases, and one of the best ways to calculate it effectively is to use Bitwise operators.
         * However, it is trouble to explain how the Bitwise operators are applied to the game, so I will explain a complex algorithm very easily.
         *  (Case to choose only in six figures(6).)
         * n = player Number, A = array of multiples of 2, B = bit of A
         *  |  n  |   A   |    B   |     i.e.    || When player select a number, all numbers are substitute by multiples of two starting with one. (inside game algorithms and Tx.)
         *  |_____|_______|________|_____________|| If player choose the number "2,3,5", "2 (000010), 4 (000100), 16 (010000)" is selected as the bitmask, and this value is aggregated and 22(010110) will be transmitted.
         *  |  1 =>   1  => 000001 |             || a player wins if only one number is matched, even if a player selects multiple numbers. (Of course, choose multiple numbers, a higher chance of winning but the lower prize.)
         *  |  2 =>   2  => 000010 |  (2) 000010 || The random number of the game, when 6 numbers are the reference, is one of the numbers 0,1,2,3,4,5 by uint game = uint(_entropy).mod(modulo);
         *  |  3 =>   4  => 000100 |  (4)+000100 || When the derived random number is called "r", "2^r" is used to determine the result of the game. If r is 5, then 2^5 = 32(100000):case1.
         *  |  4 =>   8  => 001000 |             ||(case 1:lose)|| (case 2:win)|| 32 (100000) and (22) 010110 Bitwise "& AND" returns 0. A bitwise AND is a binary operation that takes two equal-length binary representations.
         *  |  5 =>  16  => 010000 |  (5)+010000 || (22) 010110 || (22) 010110 || Thus, if both bits in the compared position are 1, the bit in the resulting binary representation is 1 (1 × 1 = 1); otherwise, the result is 0 (1 × 0 = 0 and 0 × 0 = 0).
         *  |  6 =>  32  => 100000 |=(22) 010110 || (32) 100000 || (16) 010000 || 
         *  |----------------------|-------------||-------------||-------------|| If r is 4, then 2^4 = 16(010000):case2. Bitwise operation results in a nonzero number.
         *  |                      |             ||   &  000000 ||   &  010000 || This means that the number or one of player choice matches the Game random number, so player winning.
         * 
         * As mentioned earlier, the comments and CODE of this smart contract are written in plain language for people who do not know the programming language.
         * This is not an exact description of a Bitmask Using Bitwise Operators. but, it makes it point more accessible because it is expressed as being the very closest analogy. 
         */
            if ((2 ** game) & _play.mask != 0) {
                gameWin = _play.possibleWinAmount;
            }
        //contract releases the locked funds to pay ether to the player.
        playAmountLockedInAccount = playAmountLockedInAccount.sub(_play.possibleWinAmount);
        uint _playAmountLockedInAccount = playAmountLockedInAccount; // Lines for debugging

        //calculate whether a trophy can be acquired separately from the game result.
        if (_amount >= trophyTicketQualification) {
            //The trophy is a process of accumulate 0.03% of Ether amount submitted by users to game. In the ICO period, only the accumulation is made, after which the winner comes out using provable.xyz random.
            if (trophy_period == true) {
                uint trophyRandomness = _entropy.mod(trophyModulo);
                if (trophyRandomness == 1) {
                    trophyWin = trophyWeight;
                    trophyWeight = 0;
                }
            }
        }
        
        sendFund(player, trophyWin, gameWin, _play);
        emit gameResult(_queryId, _play.playCount, 300, _play.mask, 2 ** game, gameWin, trophyWin);
        
        /* 
         * If there is a problem with callBack, we will automatically refund to the player.
         * This feature does not run every time, but when the threshold is reached.
         */
        if (_queryId == queryidToPerformTheCheck) {
            checkNcleanJam();
        } else { }
        
        // Lines for debugging
        if (playAmountLockedInAccount != _playAmountLockedInAccount) {
            emit restPlayAmountLockedInAccount (1010);
        }
    }

    /**
     * @param recipient Address
     * @param _tAmount Trophy prizes
     * @param _gAmount Game prizes
     * @notice Ether transfer function called from contractDetermineExecute/withDrawFund/refundPlay
     */
    function sendFund(address payable recipient, uint _tAmount, uint _gAmount, Play storage _play) private {
        if (_tAmount !=0 || _gAmount != 0) {

            if (_tAmount != 0 && _tAmount > 0) { //Determine if there is a trophy prize.
                recipient.transfer(_tAmount);
                emit Tpayment(400, recipient, _tAmount);
                _play.Tpayment = _tAmount;
            }
            
            if (_gAmount != 0 && _gAmount > 0) { //Determine if there is a game prize.
                recipient.transfer(_gAmount);
                emit Payment(500, recipient, _gAmount);
                _play.Payment = _gAmount;
            }
        }
    }

    /**
     * @param recipient Address
     * @param _withDrawAmount Ether amount to be sent.
     * @notice Trophy prizes never withdraws except in the case of winning.
     */
    function withDrawFund(address payable recipient, uint _withDrawAmount) external onlyOwner { 
        require (trophyWeight + playAmountLockedInAccount + _withDrawAmount <= address(this).balance, "The process cannot proceed, the withdrawal amount exceeds the withdrawable amount.");
        recipient.transfer(_withDrawAmount);
    }

    /**
     * a transaction executing a function of the SquareQueue is broadcasted by a player. The function contains a special instruction which manifest to Provable(Oraclize), who is constantly monitoring the Ethereum for such instruction, a request for data.
     * According to the parameters of such a request, Provable will fetch or compute a result, build, sign and broadcast the transaction carrying the result. In the default configuration, such a transaction will execute the __callback function which 
     * should be placed in the smart contract by its developer: for this reason, this transaction is referred to in the documentation as the Provable(Oraclize) __callback transaction.
     * One of the fundamental characteristics of Provable(Oraclize) is the capability of returning data to a smart contract together with one or more proofs of Authenticity of the data.
     * Authenticity proofs are at the core of Provable's oracle model. Smart contracts can request authenticity proofs together with their data by calling the provable_setProof function available in the usingProvable contract. 
     * The authenticity proof can be either delivered directly to the smart contract or it can be saved. When a smart contract requests for an authenticity proof, it must define a different callback function with the following arguments: 
     * function __callback(bytes32 queryId, string result, bytes proof) provable_setProof(oraclize_setProof) function of SquareQueue the following format : provable_setProof(proofType_Ledger) in the constructor.
     */
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress(), "Must comply with the provable cbAddress.");
        Play storage play = playTable[uint(_queryId)];
        callbackCount = callbackCount.add(1);
        
        bool BlockCheck = true; 
        
        if (block.number > play.playBlockNumber && block.number < play.playBlockNumber + provablelimitBlock) {
            
        } else {
            /**
             * if in extreme cases Tx is generated too late due to an unexpected EVM or network or other problem, player amount will be refunded.
             * "Too late callBack tx arrives, SquareQueue automatically refunded except fee."
             */
            refundPlay(_queryId, 602);
            BlockCheck = false;
        }
        
        if(provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0 && BlockCheck == true) {
            /**
             * @notice The proof verification has passed! Convert the random bytes received from the  query to a `uint256`.
             * to safely check the authenticity of the data received it is customary to verify the proof included in a Provable answer. Once the verifyProof method succeeds (returning 'true'), 
             * the user can be sure that neither Provable(Oraclize) nor other Parties have tampered with the results.
             */
            // generate random game values using Provable(Oraclize) Random Data Source.
            provableRandomValue = uint(keccak256(abi.encodePacked(_result)));

            /**
             * When the contract is thrown (e.g revert ...), the state is also reverted, so returning a value of zero.
             * e.g. this case also applies for an automatic refund.
             */
            play.resultBlockNumber = block.number;
            
            /// @dev Should never be run in any case unless receiving a Provable callBack.
            contractDetermineExecute(play, _queryId, provableRandomValue);
        } else {
            /**
             * If the proof verification is not passed, refund the player's ether amount and terminate the tx.
             * The proof provable_proofVerify has failed, so SquareQueue automatically refunded ether except fee.
             */
            if(BlockCheck == true) {
                refundPlay(_queryId, 611);
            }
        }
        
    }
    
    /**
     * @notice If the Contract does not work properly, it will revert all processes and refund the player's amount. However, the amount(e.g. fee,gas) deducted from the trophy and the contract is not refundable.
     * The whole process takes place automatically, without an owner or any player intervention. 'contractCommissionPercentage' is deducted to prevent malicious transactions.
     * @dev After this function is executed to eliminate any potential risks, all the contract's progress should be reverted.
     */
    function refundPlay(bytes32 _queryId, uint _id) private {
        uint _playAmountLockedInAccount = playAmountLockedInAccount; // Lines for debugging
        Play storage play = playTable[uint(_queryId)];
        
        uint _recoverAmount = play.possibleWinAmount;
        uint _amount = play.amount;
        
        if (_amount == 0) {
            revert("Since the player game ether amount is zero or the refund has already been completed.");
        } else {
            // Fetch the player game amount and issue a refund if ever there was one.
            uint deduct = contractCommissionPercentage + trophyFee;
            _amount = play.amount - play.amount * deduct / 1000;
            play.amount = 0;
            CheckJam storage checkJam = checkJamDB[play.playCount];
            checkJam.play_amount = true;
            play.possibleWinAmount = 0;
        }
        
        // Unlock ether to be refunded.
        playAmountLockedInAccount = playAmountLockedInAccount.sub(_recoverAmount);
        
        //Proceed with a refund and write a log.
        play.player.transfer(_amount);
        emit automaticRefund(_id, _amount, _queryId);
        
        //Lines for debugging
        if (playAmountLockedInAccount != _playAmountLockedInAccount) {
            emit restPlayAmountLockedInAccount (2020);
        }
    }

    /**
     * jamCount - Same as playerCount, used as a starting and ending point to check if callBack is correct.
     * checkedTime - Allocates the block that last checked time.
     * preJamCount - Allocates the block that last checked jamCount.
     */
    uint public jamCount;
    uint public checkedTime;
    uint public preJamCount;
    
    /**
     * @notice If callBack does not arrive until after provablelimitBlock, and the outcome of the game cannot be obtained, the ether will be refunded to the player.
     * @dev When callBack arrives too late, it solves the problem inside the callBack function. This function handles the case of what callBack is not completely.
     */
    function storeJam(bytes32 _queryId) private {
        jamCount = jamCount.add(1);
        CheckJam storage checkJam = checkJamDB[jamCount];
        checkJam.play_number = jamCount;
        checkJam.play_queryId = _queryId;
        
        Play storage _play = playTable[uint(checkJam.play_queryId)];
        _play.playCount = jamCount;
    }
    
    /**
     * Each provablelimitBlock is reached, it checks to all callback has been reached correctly.
     * @notice The process of checking for this callBack checks both the callBack arrival time in the __callBack function and the case where callBack does not come at all in the checkNcleanJam function.
     * All of these features guarantee that automatic refunds will be activated if there is a problem with the gameplay.
     */
    function checkNcleanJam() private {
        uint passCount;
        for(uint i = jamCount; preJamCount < i; i--) {
            CheckJam storage checkJam = checkJamDB[i];
            Play storage _play = playTable[uint(checkJam.play_queryId)];
            
            if (block.number == _play.playBlockNumber) {
                passCount ++;
                //Only the game tx of the previous block of the current block is processed.
            } else {
                if (_play.amount != 0) {
                    refundPlay(checkJam.play_queryId, 702);
                } else { }
            }
        }
        preJamCount = jamCount.sub(passCount) - 1;
    }
    /**
    Disclaimers

    Please note, during your use of the SquareQueue that online vehicle, and that it carries with it a certain degree of Ethereum financial risk. 
    Players should be aware of this risk and govern themselves accordingly. SquareQueue is intended as a Smart-Contracts for those who are interested in the pastime of Ethereum space. 
    The content within this smart-contract is designed for informational purposes. Any information posted within this website & CODE is accurate to the best of our knowledge. 
    All measures are taken to ensure that such information is accurate and up-to-date, but please take note that some of it may become outdated and/or may be subject to change at any time, 
    including descriptions of features at the developer that are reviewed, at the discretion of the said developer.
    SquareQueue maintains no responsibility for player service issues that are particular to the space that is reviewed, nor does it serve as a clearinghouse for player complaints. 
    SquareQueue does not guarantee the accuracy, adequacy, completeness of any services and shall not be liable for any errors, omissions or other defects in, delays or interruptions 
    in such services, or for any actions taken in reliance thereon or availability of any information and is not responsible for any errors or omissions, regardless of the cause or for 
    the results obtained from the use of such information. SquareQueue, its affiliates and their third party suppliers disclaim any and all express or implied warranties.
    In no event shall SquareQueue be liable for any direct, indirect, special or consequential damages, costs, expenses, legal fees, or losses (including lost income or lost profit and opportunity profits) 
    in connection with your or others’ use of the SquareQueue(includes ICO and an exchange market and all services related to SquareQueue.).
    Players must play on the basis of trusting that SquareQueue Smart-Contract written in Solidity language on the Ethereum Network & Provable(Oraclize) works as-is code.
     */

    /**
    Square Queue designates the beginning of 'space' as a 'game’ but will ultimately develop it towards 'virtual society’ and hope that the impartial laws & ruls of the virtual society will be projected into the real world.
     */
}
