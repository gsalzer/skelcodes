// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IERC1155 } from '../../0xerc1155/interfaces/IERC1155.sol';
import { ERC1155Holder } from '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';
import { SafeMath } from '../../0xerc1155/utils/SafeMath.sol';
import { FxBaseRootTunnel } from '../../polygonFx/tunnel/FxBaseRootTunnel.sol';

import { IRootTunnel } from './interfaces/IRootTunnel.sol';

import { IRewardHandler } from '../investment/interfaces/IRewardHandler.sol';
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/TokenIds.sol';

contract WOWSERC1155RootTunnel is FxBaseRootTunnel, ERC1155Holder, IRootTunnel {
  using TokenIds for uint256;
  using SafeMath for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes32 private constant DEPOSIT = keccak256('DEPOSIT');
  bytes32 private constant DEPOSIT_BATCH = keccak256('DEPOSIT_BATCH');
  bytes32 private constant MIGRATE = keccak256('MIGRATE');
  bytes32 private constant MIGRATE_BATCH = keccak256('MIGRATE_BATCH');
  bytes32 private constant DISTRIBUTE = keccak256('DISTRIBUTE');
  bytes32 private constant WITHDRAW = keccak256('WITHDRAW');
  bytes32 private constant WITHDRAW_BATCH = keccak256('WITHDRAW_BATCH');
  bytes32 private constant MAP_TOKEN = keccak256('MAP_TOKEN');

  uint256 private constant CHAIN_ID = 1;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  IWOWSERC1155 private immutable rootToken_;
  address private immutable childToken_;

  address private immutable migrator_;
  address private immutable admin_;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  IRewardHandler public rewardHandler;

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(msg.sender == admin_, 'RT: Only admin');
    _;
  }

  modifier onlyRootToken() {
    require(msg.sender == address(rootToken_), 'RT: Only from root');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(
    address _checkpointManager,
    address _fxRoot,
    address _childTunnel,
    address _rootToken,
    address _childToken,
    address _migrator,
    address _admin
  ) FxBaseRootTunnel(_checkpointManager, _fxRoot, _childTunnel) {
    require(_rootToken != address(0), 'RT: Invalid root');
    require(_childToken != address(0), 'RT: Invalid child');

    rootToken_ = IWOWSERC1155(_rootToken);
    childToken_ = _childToken;
    migrator_ = _migrator;
    admin_ = _admin;
  }

  /**
   * @dev Called from proxy
   */
  function initialize(address _rewardHandler) external {
    require(address(rewardHandler) == address(0), 'RT: Initialized');

    rewardHandler = IRewardHandler(_rewardHandler);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155Received}
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override onlyRootToken returns (bytes4) {
    // Get cfolios
    bytes memory msgData;

    if (operator != migrator_) {
      require(tokenId.isBaseCard(), 'RT: Only basecard');
      msgData = _getTokenData('', tokenId);
    } else {
      msgData = data;
    }

    // DEPOSIT, encode(rootToken, depositor, user, id, extra data)
    bytes memory message = abi.encode(
      (operator == migrator_) ? MIGRATE : DEPOSIT,
      abi.encode(address(rootToken_), operator, from, tokenId, msgData)
    );
    _sendMessageToChild(message);

    // Call ancestor
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override onlyRootToken returns (bytes4) {
    bytes32 cmd = DEPOSIT_BATCH;
    bytes memory msgData = '';
    if (operator != migrator_) {
      msgData = '';
      for (uint256 i = 0; i < tokenIds.length; ++i) {
        require(tokenIds[i].isBaseCard(), 'RT: Only basecard');
        msgData = _getTokenData(msgData, tokenIds[i]);
      }
    } else {
      msgData = data;
      cmd = MIGRATE_BATCH;
    }

    // DEPOSIT_BATCH, encode(rootToken, depositor, user, ids, extra data)
    bytes memory message = abi.encode(
      cmd,
      abi.encode(address(rootToken_), operator, from, tokenIds, msgData)
    );
    _sendMessageToChild(message);

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  function mintCFolioItems(bytes memory data) external override {
    require(msg.sender == migrator_, 'RT: Forbidden (MC)');
    require(data.length > 32 && (data.length % 32) == 0, 'RT: Invalid length');

    uint256 numTypes = data.length / 32 - 1;
    uint256[] memory dummyTokenIds = new uint256[](numTypes);
    for (uint256 i = 0; i < numTypes; ++i) dummyTokenIds[i] = uint256(-1);

    // MIGRATE_BATCH, encode(rootToken, depositor, user, ids, extra data)
    bytes memory message = abi.encode(
      MIGRATE_BATCH,
      abi.encode(
        address(rootToken_),
        msg.sender,
        address(0), // recipient is in cfolioTypes
        dummyTokenIds,
        data
      )
    );
    _sendMessageToChild(message);
  }

  function setRewardHandler(address newRewardHandler) external onlyAdmin {
    require(newRewardHandler != address(0), 'RT: Zero address');

    rewardHandler = IRewardHandler(newRewardHandler);
  }

  /**
   * @dev Destruct implementation
   */
  function destructContract() external onlyAdmin {
    // slither-disable-next-line suicidal
    selfdestruct(payable(admin_));
  }

  /**
   * @dev One time MAP_TOKEN call
   */
  function mapToken() external onlyAdmin {
    // MAP_TOKEN, rootToken
    bytes memory message = abi.encode(MAP_TOKEN, abi.encode(rootToken_));
    _sendMessageToChild(message);
  }

  /**
   * @dev In case of failure, transfer tokenId back
   */
  function emergencyTransferToken(address to, uint256 tokenId)
    external
    onlyAdmin
  {
    rootToken_.safeTransferFrom(address(this), to, tokenId, 1, '');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal
  //////////////////////////////////////////////////////////////////////////////

  function _processMessageFromChild(bytes memory data) internal override {
    (bytes32 syncType, bytes memory syncData) = abi.decode(
      data,
      (bytes32, bytes)
    );

    if (syncType == WITHDRAW) {
      _syncWithdraw(syncData);
    } else if (syncType == WITHDRAW_BATCH) {
      _syncBatchWithdraw(syncData);
    } else {
      revert('RT: Invalid sync type');
    }
  }

  function _syncWithdraw(bytes memory syncData) internal {
    (
      address rootToken,
      address childToken,
      address user,
      uint256 tokenId,
      bytes memory data
    ) = abi.decode(syncData, (address, address, address, uint256, bytes));
    require(rootToken == address(rootToken_), 'RT: Invalid root');
    require(childToken == childToken_, 'RT: Invalid child');

    rootToken_.safeTransferFrom(address(this), user, tokenId, 1, data);
  }

  function _syncBatchWithdraw(bytes memory syncData) internal {
    (
      address rootToken,
      address childToken,
      address user,
      uint256[] memory tokenIds,
      bytes memory data
    ) = abi.decode(syncData, (address, address, address, uint256[], bytes));
    require(rootToken == address(rootToken_), 'RT: Invalid root');
    require(childToken == childToken_, 'RT: Invalid child');

    rootToken_.safeBatchTransferFrom(
      address(this),
      user,
      tokenIds,
      new uint256[](0),
      data
    );
  }

  function _syncDistribute(bytes memory syncData) internal {
    (address rootToken, address childToken, uint256 amount) = abi.decode(
      syncData,
      (address, address, uint256)
    );
    require(rootToken == address(rootToken_), 'RT: Invalid root');
    require(childToken == childToken_, 'RT: Invalid child');

    rewardHandler.distribute2(address(rewardHandler), amount, uint32(1e6));
  }

  function _getTokenData(bytes memory data, uint256 tokenId)
    private
    view
    returns (bytes memory)
  {
    (uint64 mintTimestamp, ) = rootToken_.getTokenData(tokenId);

    // Return timestamp + 0 cfolios + no booster lock
    return abi.encodePacked(data, uint256(mintTimestamp));
  }
}

