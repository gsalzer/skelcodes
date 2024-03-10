pragma solidity >=0.6.2;

abstract contract IERC20 {
  function approve(address spender, uint256 value) public virtual returns (bool);
  function balanceOf(address account) public virtual view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool);
  function transfer(address _to, uint256 _value) public virtual returns (bool);
}
