pragma solidity ^0.5.0 <0.6.0;

interface ERC20ControllerInterface {
  function totalSupply(address _requestedBy) external view returns (uint256);
  function balanceOf(address _requestedBy, address tokenOwner) external view returns (uint256 balance);
  function allowance(address _requestedBy, address tokenOwner, address spender)
    external view returns (uint256 remaining);
  function transfer(address _requestedBy, address to, uint256 tokens) external returns (bool success);
  function approve(address _requestedBy, address spender, uint256 tokens) external returns (bool success);
  function transferFrom(address _requestedBy, address from, address to, uint256 tokens) external returns (bool success);

  function burn(address _requestedBy, uint256 value) external returns (bool success);
  function burnFrom(address _requestedBy, address from, uint256 value) external returns (bool success);
}

