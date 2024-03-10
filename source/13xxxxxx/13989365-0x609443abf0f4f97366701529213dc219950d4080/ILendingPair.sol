// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface ILendingPair {

  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(address);
  function operate(uint[] calldata _actions, bytes[] calldata _data) external payable;
  function transferLp(address _token, address _from, address _to, uint _amount) external;
  function supplySharesOf(address _token, address _account) external view returns(uint);
  function totalSupplyShares(address _token) external view returns(uint);
  function totalSupplyAmount(address _token) external view returns(uint);
  function totalDebtShares(address _token) external view returns(uint);
  function totalDebtAmount(address _token) external view returns(uint);
  function debtOf(address _token, address _account) external view returns(uint);
  function supplyOf(address _token, address _account) external view returns(uint);
  function pendingSystemFees(address _token) external view returns(uint);

  function supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view returns(uint);

  function initialize(
    address _lpTokenMaster,
    address _lendingController,
    address _uniV3Helper,
    address _feeRecipient,
    address _tokenA,
    address _tokenB
  ) external;
}
