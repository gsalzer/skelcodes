pragma solidity >= 0.6.6;

interface vaultInterface {
  function tokenBuy(address token, address account) external;
  function tokenSell(address token, address payable account) external;
  function addLiquidity(address account) external;
  function removeLiquidity(uint256 shares) external;
  function updatePrice() external;

  function getActive() external view returns(bool);
  function getMultiplier() external view returns(uint256);
  function getBullToken() external view returns(address);
  function getBearToken() external view returns(address);
  function getLatestRoundId() external view returns(uint256);
  function getPrice(address token) external view returns(uint256);
  function getEquity(address token) external view returns(uint256);
  function getBuyFee() external view returns(uint256);
  function getSellFee() external view returns(uint256);
  function getTotalLiqShares() external view returns(uint256);
  function getLiqFees() external view returns(uint256);
  function getBalanceEquity() external view returns(uint256);
  function getLiqTokens(address token) external view returns(uint256);
  function getLiqEquity(address token) external view returns(uint256);
  function getUserShares(address account) external view returns(uint256);

  function getTotalEquity() external view returns(uint256);
  function getTokenEquity(address token) external view returns(uint256);
  function getTotalLiqEquity() external view returns(uint256);
  function getDepositEquity() external view returns(uint256);
}

