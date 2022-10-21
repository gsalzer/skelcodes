pragma solidity ^0.4.24;

contract Kongtou {
    
    address public owner;
    
    constructor() payable public  {
        owner = msg.sender;
    }
    
    // onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    //存入eth
    function() payable public {
        
    }

    //存入eth
    function deposit() payable public{
    }
    
    //eth转帐到指定地址
    function transferETH(address _to) payable public returns (bool){
        require(_to != address(0));
        require(address(this).balance > 0);
        _to.transfer(address(this).balance);
        return true;
    }
    
    //eth转帐到多个指定地址
    function transferETH(address[] _tos, uint256 amount) public returns (bool) {
        require(_tos.length > 0);
        for(uint32 i=0;i<_tos.length;i++){
            _tos[i].transfer(amount);
        }
        return true;
    }
    
    //查看eth余额
    function getETHBalance() view public returns(uint){
        return address(this).balance;
    }
    
   // 合约批量空投代币 
   function transferToken(address from,address caddress,address[] _tos,uint v)public returns (bool){
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transfer(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            caddress.call(id,from,_tos[i],v);
        }
        return true;
    }


  
   
    
}
