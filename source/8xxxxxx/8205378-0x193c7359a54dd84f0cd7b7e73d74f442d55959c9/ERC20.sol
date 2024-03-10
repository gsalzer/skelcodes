pragma solidity ^0.4.24;
import "./ERC20Basic.sol";

contract ERC20 is ERC20Basic {
  // Optional token name
  string  public  name = "zeosX";
  string  public  symbol;
  uint256  public  decimals = 18; // standard token precision. override to customize
    
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
