pragma solidity ^0.4.25;

interface ERC20TokenInterface {
    function totalSupply() external constant returns (uint);
    function balanceOf(address _tokenOwner) external constant returns (uint balance);
    function allowance(address _tokenOwner, address spender) external constant returns (uint remaining);
   function transfer(address _to, uint _tokens) external returns (bool success);
    function approve(address _spender, uint _tokens) external returns (bool success);
    function transferFrom(address _from, address _to, uint _tokens) external returns (bool success);

}

  
