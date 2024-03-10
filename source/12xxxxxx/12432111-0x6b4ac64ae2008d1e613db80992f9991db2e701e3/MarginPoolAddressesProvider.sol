// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Ownable} from './Ownable.sol';
import './Address.sol';

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore
import {InitializableImmutableAdminUpgradeabilityProxy} from './InitializableImmutableAdminUpgradeabilityProxy.sol';

import {IMarginPoolAddressesProvider} from './IMarginPoolAddressesProvider.sol';
// import './BaseUpgradeabilityProxy.sol';
/**
 * @title MarginPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Lever Governance
 * @author Lever
 **/
contract MarginPoolAddressesProvider is Ownable, IMarginPoolAddressesProvider {
  mapping(bytes32 => address) private _addresses;

  bytes32 private constant MARGIN_POOL = 'MARGIN_POOL';
  bytes32 private constant MARGIN_POOL_CONFIGURATOR = 'MARGIN_POOL_CONFIGURATOR';
  bytes32 private constant POOL_ADMIN = 'POOL_ADMIN';
  bytes32 private constant EMERGENCY_ADMIN = 'EMERGENCY_ADMIN';
  bytes32 private constant PRICE_ORACLE = 'PRICE_ORACLE';
  bytes32 private constant LENDING_RATE_ORACLE = 'LENDING_RATE_ORACLE';
  bytes32 private constant LEVER_TOKEN = 'LEVER_TOKEN';
  bytes32 private constant TREASURY_ADDRESS = 'TREASURY_ADDRESS';
  bytes32 private constant REWARDS_DISTRIBUTION = 'REWARDS_DISTRIBUTION';
  bytes32 private constant SWAP_MINER = 'SWAP_MINER';
  bytes32 private constant ORDER_BOOK = 'ORDER_BOOK';

  constructor() public {
  }
  


  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implementationAddress`
   * IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param implementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address implementationAddress)
    external
    override
    onlyOwner
  {
    _updateImpl(id, implementationAddress);
    emit AddressSet(id, implementationAddress, true);
  }

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external override onlyOwner {
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress, false);
  }

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /**
   * @dev Returns the address of the MarginPool proxy
   * @return The MarginPool proxy address
   **/
  function getMarginPool() external view override returns (address) {
    return getAddress(MARGIN_POOL);
  }

  /**
   * @dev Updates the implementation of the MarginPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new MarginPool implementation
   **/
  function setMarginPoolImpl(address pool,address UniswapRouter, address SushiswapRouter,address _weth) external override onlyOwner {
    _updatePoolImpl(MARGIN_POOL, pool, UniswapRouter,SushiswapRouter, _weth);
    emit MarginPoolUpdated(pool);
  }

  /**
   * @dev Returns the address of the MarginPoolConfigurator proxy
   * @return The MarginPoolConfigurator proxy address
   **/
  function getMarginPoolConfigurator() external view override returns (address) {
    return getAddress(MARGIN_POOL_CONFIGURATOR);
  }

  /**
   * @dev Updates the implementation of the MarginPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new MarginPoolConfigurator implementation
   **/
  function setMarginPoolConfiguratorImpl(address configurator) external override onlyOwner {
    _updateImpl(MARGIN_POOL_CONFIGURATOR, configurator);
    emit MarginPoolConfiguratorUpdated(configurator);
  }

  /**
   * @dev The functions below are getters/setters of addresses that are outside the context
   * of the protocol hence the upgradable proxy pattern is not used
   **/

  function getPoolAdmin() external view override returns (address) {
    return getAddress(POOL_ADMIN);
  }

  function setPoolAdmin(address admin) external override onlyOwner {
    _addresses[POOL_ADMIN] = admin;
    emit ConfigurationAdminUpdated(admin);
  }

  function getEmergencyAdmin() external view override returns (address) {
    return getAddress(EMERGENCY_ADMIN);
  }

  function setEmergencyAdmin(address emergencyAdmin) external override onlyOwner {
    _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
    emit EmergencyAdminUpdated(emergencyAdmin);
  }

  function getPriceOracle() external view override returns (address) {
    return getAddress(PRICE_ORACLE);
  }

  function setPriceOracle(address priceOracle) external override onlyOwner {
    _addresses[PRICE_ORACLE] = priceOracle;
    emit PriceOracleUpdated(priceOracle);
  }


  function getLeverToken() external view override returns (address) {
    return getAddress(LEVER_TOKEN);
  }

  function setLeverToken(address lever) external override onlyOwner {
    _addresses[LEVER_TOKEN] = lever;
    emit LeverTokenUpdated(lever);
  }
  
  function getTreasuryAddress() external view override returns (address) {
    return getAddress(TREASURY_ADDRESS);
  }

  function setTreasuryAddress(address treasuryAddress) external override onlyOwner {
    _addresses[TREASURY_ADDRESS] = treasuryAddress;
    emit TreasuryAddressUpdated(treasuryAddress);
  }
  
  function getRewardsDistribution() external view override returns (address) {
    return getAddress(REWARDS_DISTRIBUTION);
  }

  function setRewardsDistribution(address rewardsDistribution) external override onlyOwner {
    _addresses[REWARDS_DISTRIBUTION] = rewardsDistribution;
    emit RewardsDistributionUpdated(rewardsDistribution);
  }

    /**
   * @dev Returns the address of the OrderBook proxy
   * @return The OrderBook proxy address
   **/
  function getOrderBook() external view override returns (address) {
    return getAddress(ORDER_BOOK);
  }

  /**
   * @dev Updates the implementation of the OrderBook, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param orderBook The new OrderBook implementation
   **/
  function setOrderBookImpl(address orderBook, address UniswapRouter, address _weth) external override onlyOwner {
    _updateImpl(ORDER_BOOK, orderBook, UniswapRouter, _weth);
    emit OrderBookUpdated(orderBook);
  }
    /**
   * @dev Returns the address of the SwapMiner proxy
   * @return The SwapMiner proxy address
   **/
  function getSwapMiner() external view override returns (address) {
    return getAddress(SWAP_MINER);
  }

  /**
   * @dev Updates the implementation of the SwapMiner, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param swapMiner The new SwapMiner implementation
   **/
  function setSwapMinerImpl(address swapMiner, address UniswapRouter, address _uniswapLevPairToken, address LeverUsdOracle) external override onlyOwner {
    _updateSwapMinerImpl(SWAP_MINER, swapMiner, UniswapRouter, _uniswapLevPairToken, LeverUsdOracle);
    emit SwapMinerUpdated(swapMiner);
  }

  

  /**
   * @dev Internal function to update the implementation of a specific proxied component of the protocol
   * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
   *   as implementation and calls the initialize() function on the proxy
   * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the initialize() function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   **/
  function _updateImpl(bytes32 id, address newAddress) internal {
    address payable proxyAddress = payable(_addresses[id]);

    InitializableImmutableAdminUpgradeabilityProxy proxy =
      InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
    bytes memory params = abi.encodeWithSignature('initialize(address)', address(this));

    if (proxyAddress == address(0)) {
      proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
      proxy.initialize(newAddress, params);
      _addresses[id] = address(proxy);
      emit ProxyCreated(id, address(proxy));
    } else {
      proxy.upgradeToAndCall(newAddress, params);
    }
  }

    /**
   * @dev Internal function to update the implementation of a specific proxied component of the protocol
   * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
   *   as implementation and calls the initialize() function on the proxy
   * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the initialize() function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   **/
  function _updateImpl(bytes32 id, address newAddress, address UniswapRouter,address _weth) internal {
    address payable proxyAddress = payable(_addresses[id]);

    InitializableImmutableAdminUpgradeabilityProxy proxy =
      InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
    bytes memory params = abi.encodeWithSignature('initialize(address,address,address)', address(this), UniswapRouter,_weth);

    if (proxyAddress == address(0)) {
      proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
      proxy.initialize(newAddress, params);
      _addresses[id] = address(proxy);
      emit ProxyCreated(id, address(proxy));
    } else {
      proxy.upgradeToAndCall(newAddress, params);
    }
  }
    /**
   * @dev Internal function to update the implementation of a specific proxied component of the protocol
   * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
   *   as implementation and calls the initialize() function on the proxy
   * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the initialize() function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   **/
  function _updatePoolImpl(bytes32 id, address newAddress, address UniswapRouter, address SushiswapRouter,address _weth) internal {
    address payable proxyAddress = payable(_addresses[id]);

    InitializableImmutableAdminUpgradeabilityProxy proxy =
      InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
    bytes memory params = abi.encodeWithSignature('initialize(address,address,address,address)', address(this), UniswapRouter,SushiswapRouter, _weth);

    if (proxyAddress == address(0)) {
      proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
      proxy.initialize(newAddress, params);
      _addresses[id] = address(proxy);
      emit ProxyCreated(id, address(proxy));
    } else {
      proxy.upgradeToAndCall(newAddress, params);
    }
  }

  function _updateSwapMinerImpl(bytes32 id, address newAddress, address UniswapRouter,address _uniswapLevPairToken,address LeverUsdOracle) internal {
    address payable proxyAddress = payable(_addresses[id]);

    InitializableImmutableAdminUpgradeabilityProxy proxy =
      InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
    bytes memory params = abi.encodeWithSignature('initialize(address,address,address,address)', address(this), UniswapRouter,_uniswapLevPairToken,LeverUsdOracle);

    if (proxyAddress == address(0)) {
      proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
      proxy.initialize(newAddress, params);
      _addresses[id] = address(proxy);
      emit ProxyCreated(id, address(proxy));
    } else {
      proxy.upgradeToAndCall(newAddress, params);
    }
  }


}

