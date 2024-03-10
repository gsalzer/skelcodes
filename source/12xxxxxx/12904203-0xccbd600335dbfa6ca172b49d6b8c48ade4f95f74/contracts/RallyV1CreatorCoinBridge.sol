// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RallyV1CreatorCoin.sol";
import "./RallyV1CreatorCoinFactory.sol";

/// @title Creator Coin V1 Bridge
/// @notice The main user interaction contract for moving Creator Coins
/// between rally sidechain and etherum mainnet
contract RallyV1CreatorCoinBridge is AccessControl {
  /// @dev The contract address of the Rally V1 Creator Coin factory for
  /// looking up contract addresses of CreatorCoins
  address public immutable factory;

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");

  event CreatorCoinBridgedToSideChain(
    address indexed mainnetCoinAddress,
    string sidechainPricingCurveId,
    address mainnetSender,
    string sidechainRecipientId,
    uint256 amount
  );

  event CreatorCoinBridgedToMainnet(
    address indexed mainnetCoinAddress,
    string sidechainPricingCurveId,
    string sidechainSenderId,
    address mainnetRecipient,
    uint256 amount
  );

  /// @dev A modifier which checks that the caller has the minter role.
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "only minter");
    _;
  }

  constructor(address _factory) {
    factory = _factory;

    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
  }

  function getCreatorCoinFromSidechainPricingCurveId(
    string memory sidechainPricingCurveId
  ) public view returns (RallyV1CreatorCoin mainnetCreatorCoin) {
    address mainnetCoinAddress =
      RallyV1CreatorCoinFactory(factory)
        .getCreatorCoinFromSidechainPricingCurveId(sidechainPricingCurveId);

    require(mainnetCoinAddress != address(0), "coin not deployed");

    mainnetCreatorCoin = RallyV1CreatorCoin(mainnetCoinAddress);
  }

  function bridgeToSidechain(
    string memory sidechainPricingCurveId,
    string memory sidechainRecipientId,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    RallyV1CreatorCoin creatorCoin =
      getCreatorCoinFromSidechainPricingCurveId(sidechainPricingCurveId);
    creatorCoin.permit(msg.sender, address(this), amount, deadline, v, r, s);
    creatorCoin.burnFrom(msg.sender, amount);

    emit CreatorCoinBridgedToSideChain(
      address(creatorCoin),
      sidechainPricingCurveId,
      msg.sender,
      sidechainRecipientId,
      amount
    );
  }

  function bridgeToMainnet(
    string memory sidechainPricingCurveId,
    string memory sidechainSenderId,
    address mainnetRecipient,
    uint256 amount,
    uint256 updatedCurrentSidechainSupply
  ) external onlyMinter {
    RallyV1CreatorCoin creatorCoin =
      getCreatorCoinFromSidechainPricingCurveId(sidechainPricingCurveId);
    creatorCoin.mint(mainnetRecipient, amount);

    creatorCoin.updateCurrentSidechainSupply(updatedCurrentSidechainSupply);

    emit CreatorCoinBridgedToMainnet(
      address(creatorCoin),
      sidechainPricingCurveId,
      sidechainSenderId,
      mainnetRecipient,
      amount
    );
  }
}

