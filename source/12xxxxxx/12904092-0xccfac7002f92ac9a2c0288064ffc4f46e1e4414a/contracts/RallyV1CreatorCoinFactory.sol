// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RallyV1CreatorCoinDeployer.sol";

/// @title Creator Coin V1 Factory
/// @notice Deploys and tracks the Creator Coin ERC20 contracts for bridging
/// individual coins from rally sidechain to ethereum mainnet
contract RallyV1CreatorCoinFactory is Ownable, RallyV1CreatorCoinDeployer {
  mapping(bytes32 => address) public getMainnetCreatorCoinAddress;
  address private _bridge;

  event CreatorCoinDeployed(
    bytes32 pricingCurveIdHash,
    address indexed mainnetCreatorCoinAddress,
    string sidechainPricingCurveId,
    string name,
    string symbol,
    uint8 decimals
  );

  function deployCreatorCoinWithDecimals(
    string memory sidechainPricingCurveId,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) external onlyOwner returns (address mainnetCreatorCoinAddress) {
    mainnetCreatorCoinAddress = _deployCreatorCoin(
      sidechainPricingCurveId,
      name,
      symbol,
      decimals
    );
  }

  function deployCreatorCoin(
    string memory sidechainPricingCurveId,
    string memory name,
    string memory symbol
  ) external onlyOwner returns (address mainnetCreatorCoinAddress) {
    mainnetCreatorCoinAddress = _deployCreatorCoin(
      sidechainPricingCurveId,
      name,
      symbol,
      6
    );
  }

  function _deployCreatorCoin(
    string memory sidechainPricingCurveId,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal returns (address mainnetCreatorCoinAddress) {
    bytes32 pricingCurveIdHash = keccak256(abi.encode(sidechainPricingCurveId));

    require(
      getMainnetCreatorCoinAddress[pricingCurveIdHash] == address(0),
      "already deployed"
    );

    mainnetCreatorCoinAddress = deploy(
      address(this),
      pricingCurveIdHash,
      sidechainPricingCurveId,
      name,
      symbol,
      decimals
    );

    getMainnetCreatorCoinAddress[
      pricingCurveIdHash
    ] = mainnetCreatorCoinAddress;
    emit CreatorCoinDeployed(
      pricingCurveIdHash,
      mainnetCreatorCoinAddress,
      sidechainPricingCurveId,
      name,
      symbol,
      decimals
    );
  }

  function getCreatorCoinFromSidechainPricingCurveId(
    string memory sidechainPricingCurveId
  ) external view returns (address mainnetCreatorCoinAddress) {
    bytes32 pricingCurveIdHash = keccak256(abi.encode(sidechainPricingCurveId));
    mainnetCreatorCoinAddress = getMainnetCreatorCoinAddress[
      pricingCurveIdHash
    ];
  }

  function setBridge(address newBridge) external onlyOwner {
    require(newBridge != address(0), "invalid bridge address");
    _bridge = newBridge;
  }

  function bridge() external view returns (address) {
    return _bridge;
  }
}

