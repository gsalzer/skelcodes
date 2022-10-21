/**
 *Submitted for verification at Etherscan.io on 2020-05-01
*/

pragma solidity 0.5.11;

interface Etherking{
   function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}



contract EtherkingLottery{
    
     address public owner;
    address etherkingcontract=0x70E59FEAEaf7bf3612C81a2bf31399FA2660fA1f;
    event BuyTicket(uint amount,uint time,address _user,uint round,uint id);
    event Winner(uint256 amount,uint time,address winner,uint round,uint position,uint poolid);
        event DepositeEth(uint amount,uint time);

    uint public round=1;
    uint public counter=0;
    uint public currentUserid=0;
    uint public range=100;
    uint public globalcounter=1;
    uint public entryfees=10000;
    mapping(uint=>uint) public winningprice;
    
    struct PoolUserStruct {
        bool isExist;
       bool paid;
       address user;
       uint id;
       bool winner;
    }
    
    mapping (uint => PoolUserStruct) public jackpotwinnerList;
     
    constructor() public
    {
     owner=msg.sender;   
     winningprice[0]=0.5 ether;
     winningprice[1]=0.25 ether;
     winningprice[2]=0.1 ether;
     winningprice[3]=0.02 ether;
     winningprice[4]=0.02 ether;
     winningprice[5]=0.02 ether;
     winningprice[6]=0.02 ether;
     winningprice[7]=0.02 ether;
     winningprice[8]=0.02 ether;
     winningprice[9]=0.02 ether;
    }
    
     function depositeFundETH() public payable
    {
        emit DepositeEth(msg.value,now);
    }
    
  
    
    function depositeFund() public
    {
        require(Etherking(etherkingcontract).transferFrom(msg.sender,address(this), (100000000000000000000)),"token transfer failed");
       
       
    }
    
    function jackpotWinner() public
    {
        require(msg.sender==owner,"You are not authorized");
        counter=0;
      
    }
    
    
        
    function getEthBalance() public view returns(uint) {
    return address(this).balance;
    }
    
 
    
    
    
    function sendPendingBalance(uint amount) public
    {
         require(msg.sender==owner, "You are not authorized");  
        if(msg.sender==owner){
        if(amount>0 && amount<=getEthBalance()){
         if (!address(uint160(owner)).send(amount))
         {
             
         }
        }
        }
    }
    
        function sendPendingBalanceTokens(uint amount) public
    {
         require(msg.sender==owner, "You are not authorized");  
        if(msg.sender==owner){
        if(amount>0){
         if (!Etherking(etherkingcontract).transfer(owner,(amount*1000000000000000000)))
         {
             
         }
        }
        }
    }
    
}
