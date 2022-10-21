/**
 *Submitted for verification at Etherscan.io on 2019-09-09
 * BEB dapp for www.betbeb.com
*/
pragma solidity^0.4.24;  
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * @param  newOwner address
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

contract LUCK is Ownable{
    address[] public bebdsds;
tokenTransfer public bebTokenTransfer; //代币 
    function LUCK(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
     }
     function present(address[] nanee)onlyOwner{
      bebdsds=nanee;
      //bebTokenTransfer.transfer(msg.sender,888*10**18);

     }
     function presentok()onlyOwner{
      delete bebdsds;
      //bebTokenTransfer.transfer(msg.sender,888*10**18);
     }
     function presentto()public{
      for(uint i=0;i<bebdsds.length;i++){
       bebTokenTransfer.transfer(bebdsds[i],88888*10**18);
        }
      //bebTokenTransfer.transfer(msg.sender,888*10**18);

     }
     function getSumAmount() public view returns(uint256){
        return bebdsds.length;
    }
    function ()payable{
    }
}
