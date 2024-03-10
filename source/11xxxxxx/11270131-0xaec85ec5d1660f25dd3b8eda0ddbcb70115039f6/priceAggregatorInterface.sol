pragma solidity >= 0.6.6;

interface priceAggregatorInterface {
  function registerVaultAggregator(address oracle) external;
  function priceRequest(
    address vault,
    uint256 lastUpdated
  )
  external
  view
  returns(int256[] memory, uint256);
  function roundIdCheck(address vault) external view returns(bool);
}

