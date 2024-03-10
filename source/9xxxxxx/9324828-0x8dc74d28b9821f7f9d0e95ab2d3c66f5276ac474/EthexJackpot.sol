pragma solidity 0.5.16;

/**
 * (E)t)h)e)x) Jackpot Contract 
 *  This smart-contract is the part of Ethex Lottery fair game.
 *  See latest version at https://github.com/ethex-bet/ethex-contracts 
 *  http://ethex.bet
 */

import "./DeliverFunds.sol";
import "./Ownable.sol";

contract EthexJackpot is Ownable {
    mapping(uint256 => address payable) public tickets;
    mapping(uint256 => Segment[4]) public prevJackpots;
    uint256[4] public amounts;
    uint256[4] public starts;
    uint256[4] public ends;
    uint256[4] public numberStarts;
    uint256 public numberEnd;
    uint256 public firstNumber;
    address public lotoAddress;
    address payable public newVersionAddress;
    EthexJackpot public previousContract;
    
    struct Segment {
        uint256 start;
        uint256 end;
        bool processed;
    }
    
    event Jackpot (
        uint256 number,
        uint256 count,
        uint256 amount,
        byte jackpotType
    );
    
    event Ticket (
        uint256 number
    );
    
    event Superprize (
        uint256 amount,
        address winner
    );
    
    uint256 internal constant PRECISION = 1 ether;
    
    modifier onlyLoto {
        require(msg.sender == lotoAddress, "Loto only");
        _;
    }
    
    function() external payable { }
    
    function migrate() external {
        require(msg.sender == owner || msg.sender == newVersionAddress);
        require(newVersionAddress != address(0), "NewVersionAddress required");
        newVersionAddress.transfer(address(this).balance);
    }

    function registerTicket(address payable gamer) external payable onlyLoto {
        distribute();
        uint8 i;
        if (gamer == address(0x0)) {
            for (; i < 4; i++)
                if (block.number >= ends[i])
                    setJackpot(i);
        }
        else {
            uint256 number = numberEnd + 1;
            for (; i < 4; i++) {
                if (block.number >= ends[i]) {
                    setJackpot(i);
                    numberStarts[i] = number;
                }
                else
                    if (numberStarts[i] == prevJackpots[starts[i]][i].start)
                        numberStarts[i] = number;
            }
            numberEnd = number;
            tickets[number] = gamer;
            emit Ticket(number);
        }
    }
    
    function setLoto(address loto) external onlyOwner {
        lotoAddress = loto;
    }
    
    function setNewVersion(address payable newVersion) external onlyOwner {
        newVersionAddress = newVersion;
    }
    
    function payIn() external payable { distribute(); }
    
    function settleJackpot() external {
        for (uint8 i = 0; i < 4; i++)
            if (block.number >= ends[i])
                setJackpot(i);

        uint256[4] memory payAmounts;
        uint256[4] memory wins;
        uint8[4] memory PARTS = [84, 12, 3, 1];
        for (uint8 i = 0; i < 4; i++) {
            uint256 start = starts[i];
            if (block.number == start || (start < block.number - 256))
                continue;
            if (prevJackpots[start][i].processed == false && prevJackpots[start][i].start != 0) {
                payAmounts[i] = amounts[i] * PRECISION / PARTS[i] / PRECISION;
                amounts[i] -= payAmounts[i];
                prevJackpots[start][i].processed = true;
                uint48 modulo = uint48(bytes6(blockhash(start) << 29));
                wins[i] = getNumber(prevJackpots[start][i].start, prevJackpots[start][i].end, modulo);
                emit Jackpot(wins[i], prevJackpots[start][i].end - prevJackpots[start][i].start + 1, payAmounts[i], byte(uint8(1) << i));
            }
        }
        
        for (uint8 i = 0; i < 4; i++)
            if (payAmounts[i] > 0 && !getAddress(wins[i]).send(payAmounts[i]))
                (new DeliverFunds).value(payAmounts[i])(getAddress(wins[i]));
    }

    function settleMissedJackpot(bytes32 hash, uint256 blockHeight) external onlyOwner {
        for (uint8 i = 0; i < 4; i++)
            if (block.number >= ends[i])
                setJackpot(i);
        
        if (blockHeight < block.number - 256) {
            uint48 modulo = uint48(bytes6(hash << 29));
        
            uint256[4] memory payAmounts;
            uint256[4] memory wins;
            uint8[4] memory PARTS = [84, 12, 3, 1];
            for (uint8 i = 0; i < 4; i++) {
                if (prevJackpots[blockHeight][i].processed == false && prevJackpots[blockHeight][i].start != 0) {
                    payAmounts[i] = amounts[i] * PRECISION / PARTS[i] / PRECISION;
                    amounts[i] -= payAmounts[i];
                    prevJackpots[blockHeight][i].processed = true;
                    wins[i] = getNumber(prevJackpots[blockHeight][i].start, prevJackpots[blockHeight][i].end, modulo);
                    emit Jackpot(wins[i], prevJackpots[blockHeight][i].end - prevJackpots[blockHeight][i].start + 1, payAmounts[i], byte(uint8(1) << i));
                }
            }
        
            for (uint8 i = 0; i < 4; i++)
                if (payAmounts[i] > 0 && !getAddress(wins[i]).send(payAmounts[i]))
                    (new DeliverFunds).value(payAmounts[i])(getAddress(wins[i]));
        }
    }
    
    function paySuperprize(address payable winner) external onlyLoto {
        uint256 superprizeAmount = amounts[0] + amounts[1] + amounts[2] + amounts[3];
        amounts[0] = 0;
        amounts[1] = 0;
        amounts[2] = 0;
        amounts[3] = 0;
        emit Superprize(superprizeAmount, winner);
        if (superprizeAmount > 0 && !winner.send(superprizeAmount))
            (new DeliverFunds).value(superprizeAmount)(winner);
    }
    
    function setOldVersion(address payable oldAddress) external onlyOwner {
        previousContract = EthexJackpot(oldAddress);
        for (uint8 i = 0; i < 4; i++) {
            starts[i] = previousContract.starts(i);
            ends[i] = previousContract.ends(i);
            numberStarts[i] = previousContract.numberStarts(i);
            uint256 start;
            uint256 end;
            bool processed;
            (start, end, processed) = previousContract.prevJackpots(starts[i], i);
            prevJackpots[starts[i]][i] = Segment(start, end, processed);
            amounts[i] = previousContract.amounts(i);
        }
        numberEnd = previousContract.numberEnd();
        firstNumber = numberEnd;
        previousContract.migrate();
    }
    
    function getAddress(uint256 number) public returns (address payable) {
        if (number <= firstNumber)
            return previousContract.getAddress(number);
        return tickets[number];
    }
    
    function setJackpot(uint8 jackpotType) private {
        uint24[4] memory LENGTH = [5000, 35000, 150000, 450000];
        prevJackpots[ends[jackpotType]][jackpotType].processed = prevJackpots[starts[jackpotType]][jackpotType].end == numberEnd;
        starts[jackpotType] = ends[jackpotType];
        ends[jackpotType] = starts[jackpotType] + LENGTH[jackpotType];
        prevJackpots[starts[jackpotType]][jackpotType].start = numberStarts[jackpotType];
        prevJackpots[starts[jackpotType]][jackpotType].end = numberEnd;
    }
    
    function distribute() private {
        uint256 distributedAmount = amounts[0] + amounts[1] + amounts[2] + amounts[3];
        if (distributedAmount < address(this).balance) {
            uint256 amount = (address(this).balance - distributedAmount) / 4;
            amounts[0] += amount;
            amounts[1] += amount;
            amounts[2] += amount;
            amounts[3] += amount;
        }
    }
    
    function getNumber(uint256 startNumber, uint256 endNumber, uint48 modulo) private pure returns (uint256) {
        return startNumber + modulo % (endNumber - startNumber + 1);
    }
}

