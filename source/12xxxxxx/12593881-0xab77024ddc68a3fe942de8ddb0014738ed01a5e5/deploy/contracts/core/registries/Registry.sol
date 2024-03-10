// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumRegistry} from './interfaces/IRegistry.sol';
import {ISynthereumFinder} from '../interfaces/IFinder.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SynthereumInterfaces} from '../Constants.sol';
import {EnumerableSet} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {EnumerableBytesSet} from '../../base/utils/EnumerableBytesSet.sol';
import {StringUtils} from '../../base/utils/StringUtils.sol';
import {
  Lockable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

/**
 * @title Register and track all the pools deployed
 */
contract SynthereumRegistry is ISynthereumRegistry, Lockable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableBytesSet for EnumerableBytesSet.BytesSet;
  using StringUtils for string;
  using StringUtils for bytes32;

  //----------------------------------------
  // Storage
  //----------------------------------------

  string public registryType;

  ISynthereumFinder public synthereumFinder;

  mapping(string => mapping(IERC20 => mapping(uint8 => EnumerableSet.AddressSet)))
    private symbolToElements;

  EnumerableBytesSet.BytesSet private syntheticTokens;

  EnumerableSet.AddressSet private collaterals;

  EnumerableSet.UintSet private versions;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the SynthereumRegistry contract
   * @param _registryType Type of registry
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(string memory _registryType, ISynthereumFinder _synthereumFinder)
    public
  {
    synthereumFinder = _synthereumFinder;
    registryType = _registryType;
  }

  /**
   * @notice Allow the deployer to register an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken
   * @param collateralToken Collateral ERC20 token of the element deployed
   * @param version Version of the element deployed
   * @param element Address of the element deployed
   */
  function register(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external override nonReentrant {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    symbolToElements[syntheticTokenSymbol][collateralToken][version].add(
      element
    );
    syntheticTokens.add(syntheticTokenSymbol.stringToBytes32());
    collaterals.add(address(collateralToken));
    versions.add(version);
  }

  /**
   * @notice Returns if a particular element exists or not
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @param element Contract of the element to check
   * @return isElementDeployed Returns true if a particular element exists, otherwise false
   */
  function isDeployed(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external view override returns (bool isElementDeployed) {
    isElementDeployed = symbolToElements[syntheticTokenSymbol][collateralToken][
      version
    ]
      .contains(element);
  }

  /**
   * @notice Returns all the elements with partcular symbol, collateral and version
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @return List of all elements
   */
  function getElements(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version
  ) external view override returns (address[] memory) {
    EnumerableSet.AddressSet storage elementSet =
      symbolToElements[syntheticTokenSymbol][collateralToken][version];
    uint256 numberOfElements = elementSet.length();
    address[] memory elements = new address[](numberOfElements);
    for (uint256 j = 0; j < numberOfElements; j++) {
      elements[j] = elementSet.at(j);
    }
    return elements;
  }

  /**
   * @notice Returns all the synthetic token symbol used
   * @return List of all synthetic token symbol
   */
  function getSyntheticTokens()
    external
    view
    override
    returns (string[] memory)
  {
    uint256 numberOfSynthTokens = syntheticTokens.length();
    string[] memory synthTokens = new string[](numberOfSynthTokens);
    for (uint256 j = 0; j < numberOfSynthTokens; j++) {
      synthTokens[j] = syntheticTokens.at(j).bytes32ToString();
    }
    return synthTokens;
  }

  /**
   * @notice Returns all the versions used
   * @return List of all versions
   */
  function getVersions() external view override returns (uint8[] memory) {
    uint256 numberOfVersions = versions.length();
    uint8[] memory actualVersions = new uint8[](numberOfVersions);
    for (uint256 j = 0; j < numberOfVersions; j++) {
      actualVersions[j] = uint8(versions.at(j));
    }
    return actualVersions;
  }

  /**
   * @notice Returns all the collaterals used
   * @return List of all collaterals
   */
  function getCollaterals() external view override returns (address[] memory) {
    uint256 numberOfCollaterals = collaterals.length();
    address[] memory collateralAddresses = new address[](numberOfCollaterals);
    for (uint256 j = 0; j < numberOfCollaterals; j++) {
      collateralAddresses[j] = collaterals.at(j);
    }
    return collateralAddresses;
  }
}

