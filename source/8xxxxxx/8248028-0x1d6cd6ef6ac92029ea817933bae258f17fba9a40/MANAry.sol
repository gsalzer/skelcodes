pragma solidity 0.5.4;

import "./SafeMath.sol";
import "./Owned.sol";


contract MANAToken {
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function transfer(address _to, uint256 _value) public returns (bool);
  function balanceOf(address owner) public view returns (uint256);
}

contract MANAry is Owned{
    using SafeMath for uint256;

    MANAToken token;
   
    constructor() public {
    token = MANAToken(0x2a8Fd99c19271F4F04B1B7b9c4f7cF264b626eDB);
    }
    
    struct tickets {address _owner; uint numOfTickets;}
    mapping (address => mapping (uint => tickets)) ownerOfTickets;
    
    address [] playerAddress;
    address [] entries;
    address [] winner;
    
    uint public potTotal = 0;
    uint public roundNumber = 0;
    uint public numOfTicketsSold = 0;
    uint public cap = 100;
    
    uint unlockTime = now + 7 days;
    
    function buyTickets(uint amount) public payable /*onlyWhenTimeIsLeft*/{
        require(amount >= 1);
        require((ownerOfTickets[msg.sender][roundNumber].numOfTickets+amount)<=15);
        require((numOfTicketsSold+amount) <= cap);
        
        if((numOfTicketsSold+amount) >= cap){
            unlockTime=0;
        }
        
        require(token.transferFrom(msg.sender, address(this), amount.mul(100000000000000000000)));
        potTotal = token.balanceOf(address(this));
        
        if (ownerOfTickets[msg.sender][roundNumber].numOfTickets == 0)
        {
        playerAddress.push(msg.sender);
        ownerOfTickets[msg.sender][roundNumber] = tickets(msg.sender, amount);
        for(uint i=0; amount > i; i++){
            entries.push(msg.sender);
            numOfTicketsSold++;
        }
        }
        else
        {
        ownerOfTickets[msg.sender][roundNumber].numOfTickets += amount;
        
        for(uint j=0; amount > j; j++){
            entries.push(msg.sender);
            numOfTicketsSold++;
            
        }
        }
        
    }
    
    function distributePrize() public payable /*onlyWhenTimeIsUpOrAllTicketsSold*/{      
        if (numOfTicketsSold > 0){
        uint randomNumber = uint(keccak256(abi.encodePacked(now, msg.sender))).mod(numOfTicketsSold);
        winner.push(entries[randomNumber]);
        address winnerAddress = winner[roundNumber];
        uint ownerShare = potTotal.mul(1).div(100);
        uint potShare = potTotal.mul(9).div(100);
        uint winnerShare = potTotal.sub(ownerShare.add(potShare));
        require(token.transfer(owner, ownerShare));
        require(token.transfer(winnerAddress, winnerShare));
        potTotal=potShare;
        }
 
        else{
        winner.push(address(0));
        }

	    delete entries;
        roundNumber++;
        numOfTicketsSold = 0;
        unlockTime= now + 7 days;
    }
    
    function terminateContract() public payable onlyOwner{
        for(uint k=0; playerAddress.length > k; k++)
        {
        uint refund = ownerOfTickets[playerAddress[k]][roundNumber].numOfTickets;
        require(token.transfer(playerAddress[k], refund.mul(100000000000000000000)));
        }
        potTotal = token.balanceOf(address(this));
        require(token.transfer(owner, potTotal));
        selfdestruct(owner);
    }
    
    function getLastWinner() public view returns (address){
        if(roundNumber == 0){
        return winner[roundNumber];
        }
        else{
            return winner[roundNumber.sub(1)];
        }
    }
    
    function getTicketNum(address ticketHolder) public view returns(uint) {
        return ownerOfTickets[ticketHolder][roundNumber].numOfTickets;
        
    }
    
    function timeLeft() public view returns(uint) {
        if (unlockTime >= now) {
            return unlockTime.sub(now);
        }
        else {
            return 0;
        }
    }
    
    modifier onlyWhenTimeIsUpOrAllTicketsSold{
        require (unlockTime < now);
        _;
    }
    
    modifier onlyWhenTimeIsLeft{
        require (unlockTime > now);
        _;
    }
    
}


