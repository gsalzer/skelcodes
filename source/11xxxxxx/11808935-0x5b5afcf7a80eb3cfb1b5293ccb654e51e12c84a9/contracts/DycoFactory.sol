//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./helpers/Ownable.sol";
import "./helpers/CloneFactory.sol";
import "./interfaces/IDYCO.sol";


/// @title DYCO factory contract
/// @author DAOMAKER
/// @notice It is the main contract, which allows to create and manage DYCOs
/// @dev It should be listened by TheGraph, as it provides all data related to child DYCOs
contract DYCOFactory is CloneFactory, Ownable {
  address public burnValley;
  address public dycoContractTemplate;

  // DYCO address => operator
  mapping(address => address) public dycoOperators;
  // DYCO address => DYCO used token
  mapping(address => address) public dycoToken;

  event DycoPaused(address dyco);
  event DycoResumed(address dyco);
  event DycoExited(address dyco, address receiver);
  event WhitelistedUsersAdded(address dyco, address[] users, uint256[] amounts);
  event TokensClaimed(address dyco, address receiver, uint256 burned, uint256 received);
  event DycoCreated(
    address dyco,
    address operator,
    address token,
    uint256 tollFee,
    uint256[] distributionDelays,
    uint256[] distributionPercents,
    bool initialDistributionEnabled,
    bool isBurnableToken
  );

  modifier ifValidDyco(address dyco) {
    require(dycoOperators[dyco] != address(0), "ifValidDyco: Dyco does not exists!");
    _;
  }

  modifier onlyDycoOperator(address dyco) {
    require(dycoOperators[dyco] == msg.sender, "onlyDycoOperator: Access to this project declined!");
    _;
  }

  // ------------------
  // CONSTRUCTOR
  // ------------------

  /// @param _dycoContractTemplate Template of DYCO logic, which should be used for future clones
  /// @param _burnValley Smart contract, which will hold all burned tokens (if some tokens not support burn method)
  constructor(address _dycoContractTemplate, address _burnValley) {
    dycoContractTemplate = _dycoContractTemplate;
    burnValley = _burnValley;
  }

  // ------------------
  // OWNER PUBLIC METHODS
  // ------------------

  /// @dev If some bug found, owner can deploy a new template and upgrade it
  /// Interface of the upgraded DYCO template should be the same!
  function upgradeDycoTemplate(address newTemplate) external onlyOwner {
    dycoContractTemplate = newTemplate;
  }

  // ------------------
  // PUBLIC METHODS
  // ------------------

  /// @dev Clone and init a new DYCO project, available for everyone
  function cloneDyco(
    address _token,
    address _operator,
    uint256 _tollFee,
    uint256[] calldata _distributionDelays,
    uint256[] calldata _distributionPercents,
    bool _initialDistributionEnabled,
    bool _isBurnableToken
  ) external returns (address) {
    address dyco = createClone(dycoContractTemplate);
    IDYCO(dyco).init(
      _token,
      _operator,
      _tollFee,
      _distributionDelays,
      _distributionPercents,
      _initialDistributionEnabled,
      _isBurnableToken,
      burnValley
    );

    dycoOperators[dyco] = _operator;
    dycoToken[dyco] = _token;

    emit DycoCreated(dyco, _operator, _token, _tollFee, _distributionDelays, _distributionPercents, _initialDistributionEnabled, _isBurnableToken);
    return dyco;
  }

  // ------------------
  // OPERATORS PUBLIC METHODS
  // ------------------

  /// @dev Check on DYCO.sol > addWhitelistedUsers()
  function addWhitelistedUsers(
    address _dyco,
    address[] memory _users,
    uint256[] memory _amounts
  ) public onlyDycoOperator(_dyco) {
    IDYCO(_dyco).addWhitelistedUsers(_users, _amounts);

    emit WhitelistedUsersAdded(_dyco, _users, _amounts);
  }

  /// @dev Check on DYCO.sol > pause()
  function pause(address _dyco) public onlyDycoOperator(_dyco) {
    IDYCO(_dyco).pause();

    emit DycoPaused(_dyco);
  }

  /// @dev Check on DYCO.sol > unpause()
  function unpause(address _dyco) public onlyDycoOperator(_dyco) {
    IDYCO(_dyco).unpause();

    emit DycoResumed(_dyco);
  }

  /// @dev Check on DYCO.sol > emergencyExit()
  function emergencyExit(
    address _dyco,
    address _receiver
  ) public onlyDycoOperator(_dyco) {
    IDYCO(_dyco).emergencyExit(_receiver);

    emit DycoResumed(_dyco);
  }

  // ------------------
  // PUBLIC METHODS
  // ------------------

  /// @dev Check on DYCO.sol > claimTokens()
  function claimTokens(
    address _dyco,
    uint256 _amount
  ) public ifValidDyco(_dyco) returns (uint256, uint256) {
    (uint256 burnedTokens, uint256 transferredTokens) = IDYCO(_dyco).claimTokens(msg.sender, _amount);

    emit TokensClaimed(_dyco, msg.sender, burnedTokens, transferredTokens);
    return (
      burnedTokens,
      transferredTokens
    );
  }
}
