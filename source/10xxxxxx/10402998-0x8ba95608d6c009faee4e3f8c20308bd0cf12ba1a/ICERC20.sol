pragma solidity >=0.6.2;

abstract contract ICERC20 {
  function approve(address spender, uint256 value) public virtual returns (bool);
  function balanceOf(address account) public virtual view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool);
  function transfer(address _to, uint256 _value) public virtual returns (bool);
  function mint(uint256) external virtual returns (uint256);
  function redeem(uint256 redeemTokens) external virtual returns (uint256);
  function repayBorrow(uint256 repayAmount) external virtual returns (uint256);
  function exchangeRateCurrent() external virtual view returns (uint256);
  function borrowBalanceCurrent(address account) external virtual view returns (uint256);
}
