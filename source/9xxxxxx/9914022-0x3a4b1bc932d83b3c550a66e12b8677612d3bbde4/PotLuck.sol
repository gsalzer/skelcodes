pragma solidity ^0.5.12;

import "./SortitionSumTreeFactory.sol";

contract PotLuck  {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    
    event PotEventCreated(uint256 eventId, uint256 expirationDateTime);
    event TicketBought(address _from, uint256 _ticketPrice, uint _ticketCount);
    event EventWinner(address _winnerAddr, uint256 _totalAmountWin);
    
    struct Pot {
        SortitionSumTreeFactory.SortitionSumTrees sortitionSumTrees;
        uint256 currentPotEventId;
    }

    struct PotEntry {
        uint256 potEventId;
        uint256 ticketPrice;
        uint256 maxTicketThreshold;
        uint256 expirationDateTime;
        uint256 totalAmount;
        uint256 totalTicketCount;

        // mapping(address => UserEntry) userEntries;
        // address payable [] userAddr;
    }
    
    struct PotDraw {
        address winner;
        uint256 netPrize;
        uint256 fee;
        bool drawn;
    }
    
    Pot pot;
    
    mapping(uint256 => PotEntry) public potEntries;
    
    mapping(uint256 => PotDraw) public potDraws;
    
    constructor() public {
        // minimumBet = 5000000000000000; // 0.005
        // fixBet = 5000000000000000; // 0,005
        // fixFee = 10000000000000; // 0.00001
    }
    
    function createPotEntry(
        bytes32 potEventId,
        uint256 _ticketPrice, 
        uint256 _maxTicketThreshold, 
        uint256 _duration) payable public {
        uint256 _potEventId = uint256(potEventId);
        
        require(msg.value >= _ticketPrice, "BET MUST BE GREATER THAN THE MINIMUM BET.");
        
        uint256 expirationDateTime = now + _duration;
        uint256 ticketEntry = msg.value / _ticketPrice;
        potEntries[_potEventId] = PotEntry(_potEventId, _ticketPrice, _maxTicketThreshold, expirationDateTime, msg.value, ticketEntry);
        pot.sortitionSumTrees.createTree(bytes32(potEventId), _maxTicketThreshold);
        
        pot.sortitionSumTrees.set(bytes32(potEventId), msg.value, bytes32(uint256(msg.sender)));
        emit PotEventCreated(_potEventId, expirationDateTime);
    }

    
    // User buy tickets.
    function buyEntry(bytes32 potEventId) payable public {
        uint256 _potEventId = uint256(potEventId);
        require(!checkEventIfExpired(_potEventId), "Event Expired");
        require(!_hasDrawn(_potEventId), "Event already ended");
        
        bytes32 userId = bytes32(uint256(msg.sender));
    
        require(msg.value >= potEntries[_potEventId].ticketPrice, "BET MUST BE GREATER THAN THE MINIMUM BET.");
        
        PotEntry storage pots = potEntries[_potEventId];
        
        // update the current draw
        uint256 currentAmount = pot.sortitionSumTrees.stakeOf(bytes32(_potEventId), userId);
        currentAmount = currentAmount+=msg.value;
        
        uint256 ticketEntry = msg.value / pots.ticketPrice;
        
        pot.sortitionSumTrees.set(bytes32(_potEventId), currentAmount, userId);
        
        pots.totalAmount+=msg.value;
        pots.totalTicketCount+=ticketEntry;
        
        if(_hasReachThreshold(_potEventId)){
            address payable winnerAddr = selectWinner(_potEventId);

            // https://ethereum.stackexchange.com/questions/41616/assign-decimal-to-a-variable-in-solidity
            address payable ownerAddrCompany = 0x99148fEb343A7D000B26396c134236E65bed70f0; // Can be changed.
            
            //Total prize minus fee.
            uint256 totalPrize = pots.totalAmount;
            uint256 fee = pots.totalAmount * 1 / 10000;
            
            PotDraw storage potDraw = potDraws[_potEventId];
            //Winner address.
            potDraw.winner = winnerAddr;
            
            //Total prize minus fee.
            potDraw.netPrize = totalPrize - fee;
            
            //Total fee to be trasnfer to impero account.
            potDraw.fee = fee;
            
            potDraw.drawn = true;
            
            winnerAddr.transfer(potDraw.netPrize);
            ownerAddrCompany.transfer(fee);
            // delete eventEntries[_eventId];
        
            emit EventWinner(winnerAddr, totalPrize);
        }
    }

    // function eventExpired(uint _potEventId) public {
    //     require(now >= potEntries[_potEventId].expirationDateTime, "Event not yet expired.");
    //     potEntries[_potEventId].expired = true;
    //     // selfdestruct(sender);
    // }
    
    function checkEventIfExpired(uint256 potEventId) public view returns(bool) {
        uint256 _potEventId = uint256(potEventId);
        if(now >= potEntries[_potEventId].expirationDateTime) {
            return true;
        } else {
            return false;
        }
    }
    
    function getUserEntry(bytes32 potEventId, address addr) public view returns(uint256, uint256) {
        uint256 _potEventId = uint256(potEventId);
        PotEntry storage pots = potEntries[_potEventId];
        bytes32 userId = bytes32(uint256(addr));
        uint256 currentAmount = pot.sortitionSumTrees.stakeOf(bytes32(_potEventId), userId);
        
        return (currentAmount, currentAmount / pots.ticketPrice);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refundTicket(uint256 potEventId, address payable addr) payable public {
        bytes32 userId = bytes32(uint256(addr));
        require(pot.sortitionSumTrees.stakeOf(bytes32(potEventId), userId) > 0, "Zero Balance");
        uint256 refundAmount = pot.sortitionSumTrees.stakeOf(bytes32(potEventId), userId);
        addr.transfer(refundAmount);
        pot.sortitionSumTrees.set(bytes32(potEventId), 0, userId);
    }
     
    function selectWinner(uint256 potEventId) public view returns(address payable) {
        uint256 _potEventId = uint256(potEventId);
        uint256 randomToken = random() % potEntries[_potEventId].totalAmount;
        return address(uint256(pot.sortitionSumTrees.draw(bytes32(_potEventId), randomToken)));
    }
    

    function random() public view returns(uint) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, now)));
    } 
    
    function _hasReachThreshold(uint256 potEventId) internal view returns (bool) {
        uint256 _potEventId = uint256(potEventId);
        return potEntries[_potEventId].totalTicketCount == potEntries[_potEventId].maxTicketThreshold;
    }
    
    function _hasEvent(uint256 potEventId) internal view returns (bool) {
        uint256 _potEventId = uint256(potEventId);
        return potEntries[_potEventId].potEventId == _potEventId;
    }
    
    function _hasDrawn(uint256 potEventId) internal view returns (bool) {
        uint256 _potEventId = uint256(potEventId);
        return potDraws[_potEventId].drawn;
    }
}
