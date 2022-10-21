pragma solidity ^0.5.0 <0.6.0;

interface C3StorageInterface {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function balanceAdd(address _to, uint256 value) external returns (bool success);
  function balanceSub(address _to, uint256 value) external returns (bool success);
  function balanceTransfer(address _from, address _to, uint256 value)
    external returns (bool success);

  function allowance(address _owner, address _spender) external view returns (uint256 remaining);
  function approve(address _owner, address _to, uint256 value) external returns (bool success);

  function totalSupply() external view returns (uint256);
  function totalSupplyAdd(uint256 value) external returns (bool success);
  function totalSupplySub(uint256 value) external returns (bool success);
}

