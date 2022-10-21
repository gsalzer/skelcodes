pragma solidity ^0.4.25;

/**
  SMART CHANCE
  
  EN:
  1. Fixed deposit - 1 Ether.
     The number of deposits from one address is not limited.
  2. The round consists of 10 deposits. At the end of the round, each participant
     gets either 110% of the deposit, or insurance compensation 70% of the
     deposit.
  3. Payments are made gradually - with each new deposit ONLY ONE payment to one
     of the participants of the previous round is sent. If the participant does
     not want to wait for a payout, he can send 0 Ether and get all his winnings.
  4. The prize fund is calculated as 7% of all deposits. To get the whole
     prize fund, it is necessary that after the participant no one invested during
     42 blocks (~ 10 minutes) and after that the participant needs to send
     0 Ether in 10 minutes.

  GAS LIMIT 300000
  
  RU:
  1. Сумма депозита фиксированная - 1 Ether.
     Количество депозитов с одного адреса не ограничено.
  2. Раунд состоит из 10 депозитов. По окончании раунда каждому участнику
     производится начисление - либо 110% от депозита, либо страховое возмещение
     70% от депозита.
  3. Выплаты производятся постепенно - с каждым новым депозитом отправляется
     ОДНА выплата одному из участников предыдущего раунда. Если участник не
     хочет ждать выплату, он может отправить 0 Ether и получить все свои выигрыши.
  4. Призовой фонд рассчитывается как 7% от депозитов. Чтобы получить весь
     призовой фонд, нужно, чтобы после участника никто не вкладывался в течение
     42 блоков (~10 минут), и чтобы он отправил 0 Ether через 10 минут.

  ЛИМИТ ГАЗА 300000
*/

contract SmartChance {
    uint public depositValue = 1 ether;
    uint public places = 10;
    uint public blocksBeforePrize = 42;
    uint public prize;
    uint public supportFee = 3;
    uint public prizeFee = 7;
    address public lastInvestor;
    uint public lastInvestedAt;
    uint[] public rewards = [ 110, 110, 110, 110, 110 ];
    address[] public placesMap;
    mapping (address => uint) public debts;
    mapping (address => uint) public debtsQueueIndex;
    address[] public debtsQueue;
    uint public debtIndex;
    address public support = msg.sender;
    
    uint private seed;
    
    // uint256 to bytes32
    function toBytes(uint256 x) internal pure returns (bytes b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
    
    // initializes variables for a pseudo-random number generator
    function randomize() internal {
        seed += block.timestamp + uint(msg.sender);
    }
    
    // returns a pseudo-random number
    function random(uint lessThan) internal view returns (uint) {
        return uint(sha256(toBytes(uint(blockhash(block.number - 1)) + seed))) % lessThan;
    }
    
    function registerInvestor(address investor) internal {
        placesMap.push(investor);
        if (debtsQueueIndex[investor] == 0) {
            debtsQueue.push(investor);
            debtsQueueIndex[investor] = debtsQueue.length;
        }
    }
    
    function addDebt(address investor, uint debt) internal {
        debts[investor] += debt;
    }
    
    function () public payable {
        require(block.number >= 6642584);
        
        randomize();
        if (msg.value == depositValue) {
            registerInvestor(msg.sender);
            if (placesMap.length == places) {
                uint place = random(places);
                
                uint prizeSum;
                uint x;
                for (x = 0; x < rewards.length; x++) {
                    uint reward = depositValue * rewards[x] / 100;
                    addDebt(placesMap[place], reward);
                    prizeSum += reward;
                    place = (place + 1) % places;
                }
                
                uint insurancePlaces = places - rewards.length;
                uint insuranceValue = (depositValue * places * (100 - supportFee - prizeFee) / 100 - prizeSum) / insurancePlaces;
                for (x = 0; x < insurancePlaces; x++) {
                    addDebt(placesMap[place], insuranceValue);
                    place = (place + 1) % places;
                }
                
                delete placesMap;
            }
            
            if (debtIndex < debtsQueue.length) {
                address investor = debtsQueue[debtIndex];
                if (investor != 0x0) {
                    if (debts[investor] > 0) {
                        investor.transfer(debts[investor]);
                        delete debts[investor];
                        delete debtsQueueIndex[investor];
                        delete debtsQueue[debtIndex];
                        debtIndex++;
                    }
                } else {
                    debtIndex++;
                }
            }
            
            lastInvestor = msg.sender;
            lastInvestedAt = block.number;
            support.transfer(msg.value * supportFee / 100);
            prize += msg.value * prizeFee / 100;
        } else if (msg.value == 0) {
            uint debt = debts[msg.sender];
            if (debt > 0) {
                msg.sender.transfer(debt);
                delete debts[msg.sender];
                delete debtsQueue[debtsQueueIndex[msg.sender] - 1];
                delete debtsQueueIndex[msg.sender];
            }
            if (lastInvestor == msg.sender && block.number >= lastInvestedAt + blocksBeforePrize) {
                lastInvestor.transfer(prize);
                delete prize;
                delete lastInvestor;
            }
        } else {
            revert();
        }
    }
}
