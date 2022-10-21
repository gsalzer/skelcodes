// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
@title BadgerDAO Emission Control
@author jintao.eth
@notice Emission Control is the on chain source of truth for Badger Boost parameters.
The two parameters exposed by mission control: 
- Token Weight
- Boosted Emission Rate
The token weight determines the percentage contribution to native or non native balances.
The boosted emission rate determines the percentage of Badger that is emitted according to
boost versus a pro rata emission.
@dev All operations must be conducted by an emission control manager.
The deployer is the original manager and can add or remove managers as needed.
*/
contract EmissionControl is Ownable {
  event TokenWeightChanged(address indexed _token, uint256 indexed _weight);
  event TokenBoostedEmissionChanged(
    address indexed _vault,
    uint256 indexed _weight
  );

  uint256 public constant MAX_BPS = 10_000;
  mapping(address => bool) public manager;
  mapping(address => uint256) public tokenWeight;
  mapping(address => uint256) public boostedEmissionRate;

  modifier onlyManager() {
    require(manager[msg.sender], "!manager");
    _;
  }

  constructor(address _vault) {
    manager[msg.sender] = true;
    /// @dev bbadger vault
    tokenWeight[0x19D97D8fA813EE2f51aD4B4e04EA08bAf4DFfC28] = MAX_BPS;
    /// @dev bdigg vault
    tokenWeight[0x7e7E112A68d8D2E221E11047a72fFC1065c38e1a] = MAX_BPS;
    /// @dev uniswap badger-wbtc lp vault
    tokenWeight[0x235c9e24D3FB2FAFd58a2E49D454Fdcd2DBf7FF1] = 5_000;
    /// @dev sushiswap badger-wbtc lp vault
    tokenWeight[0x1862A18181346EBd9EdAf800804f89190DeF24a5] = 5_000;
    /// @dev uniswap digg-wbtc lp vault
    tokenWeight[0xC17078FDd324CC473F8175Dc5290fae5f2E84714] = 5_000;
    /// @dev sushiswap digg-wbtc lp vault
    tokenWeight[0x88128580ACdD9c04Ce47AFcE196875747bF2A9f6] = 5_000;
    transferOwnership(_vault);
  }

  /// @param _manager address to add as manager
  function addManager(address _manager) external onlyOwner {
    manager[_manager] = true;
  }

  /// @param _manager address to remove as manager
  function removeManager(address _manager) external onlyOwner {
    manager[_manager] = false;
  }

  /// @param _token token address to assign weight
  /// @param _weight weight in bps
  function setTokenWeight(address _token, uint256 _weight)
    external
    onlyManager
  {
    require(_weight <= MAX_BPS, "INVALID_WEIGHT");
    tokenWeight[_token] = _weight;
    emit TokenWeightChanged(_token, _weight);
  }

  /// @param _vault vault address to assign boosted emission rate
  /// @param _weight rate in bps
  function setBoostedEmission(address _vault, uint256 _weight)
    external
    onlyManager
  {
    require(_weight <= MAX_BPS, "INVALID_WEIGHT");
    boostedEmissionRate[_vault] = _weight;
    emit TokenBoostedEmissionChanged(_vault, _weight);
  }

  /// @param _vault vault address to look up pro rata emission rate
  /// @dev convenience function for exposing the opposite mapping
  function proRataEmissionRate(address _vault) external view returns (uint256) {
    return MAX_BPS - boostedEmissionRate[_vault];
  }
}

