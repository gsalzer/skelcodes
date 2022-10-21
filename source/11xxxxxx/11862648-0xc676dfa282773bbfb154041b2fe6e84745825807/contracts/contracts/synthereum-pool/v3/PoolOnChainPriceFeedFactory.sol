// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../versioning/interfaces/IFinder.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {SynthereumPoolOnChainPriceFeed} from './PoolOnChainPriceFeed.sol';
import {SynthereumInterfaces} from '../../versioning/Constants.sol';
import {
  IDeploymentSignature
} from '../../versioning/interfaces/IDeploymentSignature.sol';
import {
  SynthereumPoolOnChainPriceFeedCreator
} from './PoolOnChainPriceFeedCreator.sol';

contract SynthereumPoolOnChainPriceFeedFactory is
  SynthereumPoolOnChainPriceFeedCreator,
  IDeploymentSignature
{
  //----------------------------------------
  // State variables
  //----------------------------------------

  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Set synthereum finder
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(address _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createPool.selector;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @notice Only Synthereum deployer can deploy a pool
   * @param derivative The perpetual derivative
   * @param finder The Synthereum finder
   * @param version Synthereum version
   * @param roles The addresses of admin, maintainer, liquidity provider and validator
   * @param isContractAllowed Enable or disable the option to accept meta-tx only by an EOA for security reason
   * @param startingCollateralization Collateralization ratio to use before a global one is set
   * @param fee The fee structure
   * @return poolDeployed Pool contract deployed
   */
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPoolOnChainPriceFeed.Roles memory roles,
    bool isContractAllowed,
    uint256 startingCollateralization,
    ISynthereumPoolOnChainPriceFeed.Fee memory fee
  ) public override returns (SynthereumPoolOnChainPriceFeed poolDeployed) {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    poolDeployed = super.createPool(
      derivative,
      finder,
      version,
      roles,
      isContractAllowed,
      startingCollateralization,
      fee
    );
  }
}

