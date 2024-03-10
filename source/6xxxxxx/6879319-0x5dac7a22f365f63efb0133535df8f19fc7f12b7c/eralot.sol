pragma solidity ^0.4.19;

contract eralot{
    address public owner;
    uint count=0;
    address [] users;
    address [] tempusers;
    address [] winners;
    uint min_bal=2;
    uint totalbal=0;
    uint ratio = 0;
    uint inc = 0;
    
   struct user_details
   {
       uint amt;
   }
   
   event info(address x,uint y, uint z, string temp);
    mapping(address=>user_details)Details;
    
    constructor() public{
        owner=msg.sender;
    }
     
    function transfer_ownership(address o) public{
        require(msg.sender==owner); 
         owner = o;
    }
    
    function checkPlayerExists(address player) public constant returns(bool)
   {
      for(uint i = 0; i < users.length; i++)
	  {
           if(users[i] == player) return true;
      }
      return false;
    }
    
    function lottery()public payable {
        require(!checkPlayerExists(msg.sender));
        if((msg.value>=2 ether)&&count<1000)
        {
        Details[msg.sender].amt=msg.value;
        address(this).transfer(msg.value);
        users.push(msg.sender);
        tempusers.push(msg.sender);
        count++;
        }
        emit info(msg.sender,msg.value,count,"successfull");
    }
    
    function()public payable{}
    
    function check_conbal() public view returns(uint){
        require(msg.sender==owner);
         return address(this).balance; 
    }
    function get_profit() public view returns(uint){
        require(msg.sender==owner);
         uint x=address(this).balance/20;
         return x;
    }
    
    function estimate_prize() public view returns(uint){
         uint x=address(this).balance/20;
         uint y=address(this).balance-x;
         return y; 
    }
    function pickwinner()public payable{
        require(msg.sender==owner);
         uint ct = getwinners();
         uint temp = ct;
         uint dev = address(this).balance/20;
         owner.transfer(dev);
         while(ct>0){
         inc =  inc + ct;
         ct--;
         }
         uint bal = address(this).balance;
         ratio = bal/inc;
         while(temp>0){
         uint z = temp*ratio;
         uint x=random();
         tempusers[x].transfer(z);
         winners.push(tempusers[x]);
         for (uint i = x; i<tempusers.length-1; i++){
            tempusers[i] = tempusers[i+1];
         }
         delete tempusers[tempusers.length-1];
         tempusers.length--;
         temp = temp-1;
        }
   
   //clear data      
        for ( i=0;i<tempusers.length;i++)
       {
            delete tempusers[i];
         }
         
         for (i=0;i<users.length;i++)
         {
            delete users[i];
           
         }
        count = 0;
      
    }
    function getwinners() internal view returns(uint){
        uint x;
        if(count<20){
            return 1;
        }
        else{
            x=count/10;
           return x; 
        }
    } 
    function random() internal view returns (uint) {
         uint temp_count = tempusers.length;
         uint temp=temp_count+1;
         return uint(uint256(keccak256(block.timestamp, block.difficulty))%temp);
    }

    function refund(uint x) public payable {
        require(msg.sender == owner);
         if(x==111){
         for(uint i =0; i< users.length ; i++){
            users[i].transfer(Details[users[i]].amt);
         }
        }
    }
    
    function get_winners() public view returns (address[]){
        require(msg.sender == owner);
         return winners;
    }
    
    function clear_winners(uint x) public {
        require(msg.sender == owner);
         if(x==111){
         for(uint i=0;i<winners.length;i++)
         {
             delete winners[i];
         }
         }
    }
    
  
    function get_details(address x) public view returns(uint){
        require(msg.sender == owner);
         return Details[x].amt;
    }
}
