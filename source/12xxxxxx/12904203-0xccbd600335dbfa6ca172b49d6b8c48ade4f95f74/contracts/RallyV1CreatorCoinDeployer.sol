// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./RallyV1CreatorCoin.sol";

/// @title A contract capable of deploying Creator Coins
/// @dev This is used to avoid having constructor arguments in the creator coin contract, which results in the init code hash
/// of the coin being constant allowing the CREATE2 address of the coin to be cheaply computed on-chain
contract RallyV1CreatorCoinDeployer {
  struct Parameters {
    address factory;
    bytes32 pricingCurveIdHash;
    string sidechainPricingCurveId;
    string name;
    string symbol;
    uint8 decimals;
  }

  /// @notice Get the parameters to be used in constructing the coin, set transiently during coin creation.
  /// @dev Called by the coin constructor to fetch the parameters of the coin
  /// Returns pricingCurveIdHash The bytes32 hash of the sidechainPricingCurveId string
  /// Returns sidechainPricingCurveId The pricingCurveId as a string from rally sidechain
  /// Returns name creator coin name
  /// Returns smybol creator coin symbol
  Parameters public parameters;

  /// @dev Deploys a coin with the given parameters by transiently setting the parameters storage slot and then
  /// clearing it after deploying the coin.
  /// @param pricingCurveIdHash The bytes32 hash of the sidechainPricingCurveId string
  /// @param sidechainPricingCurveId The pricingCurveId as a string from rally sidechain
  /// @param name creator coin name
  /// @param symbol creator coin symbol
  function deploy(
    address factory,
    bytes32 pricingCurveIdHash,
    string memory sidechainPricingCurveId,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal returns (address mainnetCreatorCoinAddress) {
    parameters = Parameters({
      factory: factory,
      pricingCurveIdHash: pricingCurveIdHash,
      sidechainPricingCurveId: sidechainPricingCurveId,
      name: name,
      symbol: symbol,
      decimals: decimals
    });

    mainnetCreatorCoinAddress = address(
      new RallyV1CreatorCoin{ salt: pricingCurveIdHash }()
    );
    delete parameters;
  }
}

