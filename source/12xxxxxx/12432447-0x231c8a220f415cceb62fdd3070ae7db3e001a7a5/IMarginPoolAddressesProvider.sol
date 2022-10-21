// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title MarginPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Lever Governance
 * @author Lever
 **/
interface IMarginPoolAddressesProvider {
  event MarginPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event MarginPoolConfiguratorUpdated(address indexed newAddress);
  event MarginPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
  event LeverTokenUpdated(address indexed newAddress);
  event TreasuryAddressUpdated(address indexed newAddress);
  event RewardsDistributionUpdated(address indexed newAddress);
  event OrderBookUpdated(address indexed newAddress);
  event SwapMinerUpdated(address indexed newAddress);


  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getMarginPool() external view returns (address);

  function setMarginPoolImpl(address pool, address UniswapRouter,address SushiswapRouter, address weth) external;

  function getMarginPoolConfigurator() external view returns (address);

  function setMarginPoolConfiguratorImpl(address configurator) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLeverToken() external view returns (address);

  function setLeverToken(address lever) external;

  function getTreasuryAddress() external view returns (address);

  function setTreasuryAddress(address treasuryAddress) external;

  function getRewardsDistribution() external view returns (address);

  function setRewardsDistribution(address rewardsDistribution) external;

  function getOrderBook() external view returns (address);

  function setOrderBookImpl(address addressProvider, address UniswapRouter, address weth) external;

  function getSwapMiner() external view returns (address);

  function setSwapMinerImpl(address _swapMiner, address UniswapRouter, address _uniswapLevPairToken, address LeverUsdOracle) external;
}

