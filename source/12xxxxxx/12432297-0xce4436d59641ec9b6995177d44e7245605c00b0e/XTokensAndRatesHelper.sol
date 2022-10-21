// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IMarginPoolAddressesProvider} from './IMarginPoolAddressesProvider.sol';
import {MarginPoolConfigurator} from './MarginPoolConfigurator.sol';
import {XToken} from './XToken.sol';
import {
  DefaultReserveInterestRateStrategy
} from './DefaultReserveInterestRateStrategy.sol';
import {Ownable} from './Ownable.sol';
import {StringLib} from './StringLib.sol';

contract XTokensAndRatesHelper is Ownable {
  address payable private pool;
  address private addressesProvider;
  address private poolConfigurator;
  event deployedContracts(address xToken, address strategy);

  constructor(
    address _addressesProvider,
    address _poolConfigurator
  ) public {
    addressesProvider = _addressesProvider;
    poolConfigurator = _poolConfigurator;
  }

 
  function initDeployment(
    address[] calldata assets,
    string[] calldata symbols,
    uint256[4][] calldata rates,
    uint8[] calldata decimals
  ) external onlyOwner {
    require(assets.length == symbols.length, 't Arrays not same length');
    require(rates.length == symbols.length, 'r Arrays not same length');
    for (uint256 i = 0; i < assets.length; i++) {
      emit deployedContracts(
        address(
          new XToken(
            addressesProvider,
            assets[i],
            StringLib.concat('Lever interest bearing ', symbols[i]),
            StringLib.concat('x', symbols[i]),
            decimals[i]
          )
        ),
        address(
          new DefaultReserveInterestRateStrategy(
            IMarginPoolAddressesProvider(addressesProvider),
            rates[i][0],
            rates[i][1],
            rates[i][2],
            rates[i][3]
          )
        )
      );
    }
  }

  function initReserve(
    address[] calldata variables,
    address[] calldata xTokens,
    address[] calldata strategies,
    uint8[] calldata reserveDecimals
  ) external onlyOwner {
    require(xTokens.length == variables.length);
    require(strategies.length == variables.length);
    require(reserveDecimals.length == variables.length);

    for (uint256 i = 0; i < variables.length; i++) {
      MarginPoolConfigurator(poolConfigurator).initReserve(
        xTokens[i],
        variables[i],
        reserveDecimals[i],
        strategies[i]
      );
    }
  }

  function configureReserves(
    address[] calldata assets,
    uint256[] calldata baseLTVs,
    uint256[] calldata liquidationThresholds,
    uint256[] calldata liquidationBonuses,
    uint256[] calldata reserveFactors
  ) external onlyOwner {
    require(baseLTVs.length == assets.length);
    require(liquidationThresholds.length == assets.length);
    require(liquidationBonuses.length == assets.length);
    require(reserveFactors.length == assets.length);

    MarginPoolConfigurator configurator = MarginPoolConfigurator(poolConfigurator);
    for (uint256 i = 0; i < assets.length; i++) {
      configurator.configureReserveAsCollateral(
        assets[i],
        baseLTVs[i],
        liquidationThresholds[i],
        liquidationBonuses[i]
      );

      configurator.setReserveFactor(assets[i], reserveFactors[i]);
    }
  }
}

