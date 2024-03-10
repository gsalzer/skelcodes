// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { ERC1155Holder } from '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';
import { IERC20, SafeERC20 } from '../../0xerc1155/utils/SafeERC20.sol';
import { SafeMath } from '../../0xerc1155/utils/SafeMath.sol';

import '../cfolio/interfaces/ICFolioItemHandler.sol';
import '../cfolio/interfaces/ISFTEvaluator.sol';
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../polygon/interfaces/IRootTunnel.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import '../../interfaces/curve/CurveDepositInterface4.sol';

interface ISFTEvaluatorOld {
  /**
   * @dev Returns the reward in 1e6 factor notation (1e6 = 100%)
   */
  function rewardRate(uint256 sftTokenId) external view returns (uint32);

  /**
   * @dev Returns the cFolioItemType of a given cFolioItem tokenId
   */
  function getCFolioItemType(uint256 tokenId) external view returns (uint256);
}

interface IWOWSERC1155Old {
  function tokenIdToAddress(uint256 tokenId) external view returns (address);

  function getTokenData(uint256 tokenId)
    external
    view
    returns (uint64 mintTimestamp, uint8 level);

  function burn(
    address account,
    uint256 tokenId,
    uint256 value
  ) external;

  function burnBatch(
    address account,
    uint256[] calldata tokenIds,
    uint256[] calldata values
  ) external;
}

interface IWOWSCryptofolioOld {
  function _tradefloors(uint256 index) external view returns (address);

  function getCryptofolio(address tradefloor)
    external
    view
    returns (uint256[] memory tokenIds, uint256 idsLength);
}

interface IBoosterOld {
  function migrateInitialize(address cfolio)
    external
    returns (uint256 poolState);

  function migrateDeletePool(uint256 poolState, address cfolio)
    external
    returns (bytes memory data);

  function claimRewards(uint256 sftTokenId, bool reLock) external;
}

interface IMinterOld {
  function claimSFTRewards(uint256 sftTokenId, uint256 lockPeriod) external;
}

/**
 * @notice Migration from v1 -> v2 which processes:
 * - remove investment from cfis on old contract (either into the account
 *   or for yCrv optional into this contract to withdraw later to USDC and
 *   distribute to wallets)
 * - mint cfolio in new sft contract
 * - bridge cfolio and all cfis to polygon if cfolios are existent
 *   or if booster has a reward timelock running
 * - burn old cfolio + cfis in old contract
 */

contract MigrateToV2 is ERC1155Holder {
  using SafeERC20 for IERC20;
  using TokenIds for uint256;
  using SafeMath for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // CONSTANTS
  //////////////////////////////////////////////////////////////////////////////

  bytes32 public constant SFT_MINTER = 'SFT_MINTER';
  bytes32 public constant SFT_HOLDER = 'SFT_HOLDER';
  bytes32 public constant CFOLIOITEM_BRIDGE_PROXY = 'CFOLIOITEM_BRIDGE_PROXY';
  bytes32 public constant CURVE_Y_TOKEN = 'CURVE_Y_TOKEN';
  bytes32 public constant CURVE_Y_DEPOSIT = 'CURVE_Y_DEPOSIT';

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  IWOWSERC1155Old private immutable _sftContractOld;
  ISFTEvaluatorOld private immutable _sftEvaluatorOld;
  address private immutable _cfiBridgeOld;
  IBoosterOld private immutable _boosterOld;
  IMinterOld private immutable _sftMinterOld;

  IERC20 private immutable _yCrvToken;
  ICurveFiDeposit4 private immutable _curveYDeposit;

  IWOWSERC1155 private immutable _sftContract;
  address private immutable _admin;
  IERC20 private immutable _uniV2LPToken;
  ISFTEvaluator private immutable _sftEvaluator;
  IERC20 private immutable _wowsToken;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // If we have cfolios or booster lock, we need to bridge to polygon
  IRootTunnel public rootTunnel;

  struct BulkSlot {
    uint256 amount;
    uint256 partId;
  }

  address[] public bulkParticipants;
  mapping(address => BulkSlot) public bulkLookup;

  uint256 releaseBlock = 13377140;

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'M: Only admin');
    _;
  }

  modifier onlyOldSftContract() {
    require(msg.sender == address(_sftContractOld), 'M: Only sftContractOld');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////
  constructor(IAddressRegistry regOld, IAddressRegistry reg) {
    _admin = reg.getRegistryEntry(AddressBook.ADMIN_ACCOUNT);
    _sftContract = IWOWSERC1155(
      reg.getRegistryEntry(AddressBook.SFT_HOLDER_PROXY)
    );
    _uniV2LPToken = IERC20(reg.getRegistryEntry(AddressBook.UNISWAP_V2_PAIR));
    _sftEvaluator = ISFTEvaluator(
      reg.getRegistryEntry(AddressBook.SFT_EVALUATOR_PROXY)
    );
    _wowsToken = IERC20(reg.getRegistryEntry(AddressBook.WOWS_TOKEN));

    _sftContractOld = IWOWSERC1155Old(regOld.getRegistryEntry(SFT_HOLDER));
    _sftEvaluatorOld = ISFTEvaluatorOld(
      regOld.getRegistryEntry(AddressBook.SFT_EVALUATOR_PROXY)
    );
    _cfiBridgeOld = regOld.getRegistryEntry(CFOLIOITEM_BRIDGE_PROXY);
    _boosterOld = IBoosterOld(
      regOld.getRegistryEntry(AddressBook.WOWS_BOOSTER_PROXY)
    );
    _sftMinterOld = IMinterOld(regOld.getRegistryEntry(SFT_MINTER));

    _yCrvToken = IERC20(regOld.getRegistryEntry(CURVE_Y_TOKEN));
    _curveYDeposit = ICurveFiDeposit4(regOld.getRegistryEntry(CURVE_Y_DEPOSIT));
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
  ) public override onlyOldSftContract returns (bytes4) {
    bool yCrvBulkWithdraw = data.length >= 32
      ? abi.decode(data, (bool))
      : false;
    require(amount == 1, 'M: Invalid amount');

    uint256[] memory oneTokenIds = new uint256[](1);
    oneTokenIds[0] = tokenId;

    _processTokenId(from, oneTokenIds, yCrvBulkWithdraw);

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
  ) public override onlyOldSftContract returns (bytes4) {
    require(tokenIds.length == amounts.length, 'M: Invalid length');

    bool yCrvBulkWithdraw = data.length >= 32
      ? abi.decode(data, (bool))
      : false;

    uint256[] memory oneTokenIds = new uint256[](1);

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      require(amounts[i] == 1, 'M: Invalid amount');

      oneTokenIds[0] = tokenIds[0];

      _processTokenId(from, oneTokenIds, yCrvBulkWithdraw);
    }

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Bulk SC swap
  //////////////////////////////////////////////////////////////////////////////

  function distributeStable() external {
    require(block.number >= releaseBlock, 'M: Not open');
    releaseBlock = uint256(-1);

    uint256 amountY = _yCrvToken.balanceOf(address(this));
    require(amountY > 0, 'M: Empty');

    _yCrvToken.safeApprove(address(_curveYDeposit), amountY);

    IERC20 tetherToken = IERC20(_curveYDeposit.underlying_coins(2));
    _curveYDeposit.remove_liquidity_one_coin(amountY, 2, 0, true);

    // Now we have USDT in our contract: distribute to users
    uint256 availableUSDT = tetherToken.balanceOf(address(this));
    uint256 totalUSDT = availableUSDT;

    require(totalUSDT > 0, 'M: Empty S');

    for (uint256 i = 0; i < bulkParticipants.length; ++i) {
      uint256 amount = totalUSDT
        .mul(bulkLookup[bulkParticipants[i]].amount)
        .div(amountY);
      if (amount > availableUSDT) amount = availableUSDT;
      availableUSDT.sub(amount);
      if (amount > 0) {
        tetherToken.safeTransfer(bulkParticipants[i], amount);
      }
      delete (bulkLookup[bulkParticipants[i]]);
    }
    delete (bulkParticipants);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Maintanance
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the Root Tunnel which is deployed after Migrate
   */
  function setRootTunnel(address rootTunnel_) external onlyAdmin {
    require(rootTunnel_ != address(0), 'M: Zero address');

    rootTunnel = IRootTunnel(rootTunnel_);
  }

  /**
   * @dev Destruct implementation
   */
  function destructContract() external onlyAdmin {
    // slither-disable-next-line suicidal
    selfdestruct(payable(_admin));
  }

  /**
   * @dev Start a new bulk stable withdraw period
   */
  function setReleaseBlock(uint256 newReleaseBlock) external onlyAdmin {
    releaseBlock = newReleaseBlock;
  }

  //////////////////////////////////////////////////////////////////////////////
  // INTERNAL IMPLEMENTATION
  //////////////////////////////////////////////////////////////////////////////

  function _processTokenId(
    address from,
    uint256[] memory oneTokenIds,
    bool yCrvBulk
  ) private {
    (bytes memory migrateData, bool needBridge) = _processMigration(
      from,
      oneTokenIds[0],
      yCrvBulk
    );
    // Investment should be pulled out of old contract, burn old cfolio
    _sftContractOld.burn(address(this), oneTokenIds[0], 1);

    if (oneTokenIds[0].isBaseCard()) {
      if (needBridge) {
        migrateData = abi.encodePacked(migrateData, uint256(from));
        _sftContract.mintBatch(address(rootTunnel), oneTokenIds, migrateData);
      } else {
        _sftContract.mintBatch(from, oneTokenIds, migrateData);
        _sftEvaluator.setRewardRate(oneTokenIds[0], false);
      }
    } else {
      rootTunnel.mintCFolioItems(migrateData);
    }
  }

  function _processMigration(
    address from,
    uint256 tokenId,
    bool yCrvBulk
  ) private returns (bytes memory result, bool needBridge) {
    needBridge = false;
    if (tokenId.isBaseCard()) {
      address cfolio = _sftContractOld.tokenIdToAddress(tokenId);

      (uint64 mintTimestamp, ) = _sftContractOld.getTokenData(tokenId);
      (uint256[] memory tokenIds, uint256 idsLength) = IWOWSCryptofolioOld(
        cfolio
      ).getCryptofolio(_cfiBridgeOld);

      result = abi.encodePacked(uint256(mintTimestamp), idsLength);
      needBridge = idsLength > 0;

      for (uint256 i = 0; i < idsLength; ++i) {
        uint256 cfiType = _sftEvaluatorOld.getCFolioItemType(tokenIds[i]);
        _removeInvestment(from, tokenId, tokenIds[i], cfiType, yCrvBulk);
        result = abi.encodePacked(result, cfiType);
      }

      // Booster Pool
      uint256 poolState = _boosterOld.migrateInitialize(cfolio);

      if ((poolState & 1) != 0) {
        // Acive booster pool, claim rewards into it
        _sftMinterOld.claimSFTRewards(tokenId, 1);
      } else {
        // No active booster Pool, claim everything into users wallet
        uint256 balance = _wowsToken.balanceOf(address(this));
        _sftMinterOld.claimSFTRewards(tokenId, 0);
        if ((poolState & 2) != 0) {
          _boosterOld.claimRewards(tokenId, false);
        }
        balance = _wowsToken.balanceOf(address(this)).sub(balance);
        if (balance > 0) {
          _wowsToken.safeTransfer(from, balance);
        }
      }
      result = abi.encodePacked(result, poolState & 1);

      bytes memory poolData = _boosterOld.migrateDeletePool(poolState, cfolio);
      if ((poolState & 1) != 0) {
        // We have an active booster pool -> bridge
        result = abi.encodePacked(result, poolData);
        needBridge = true;
      }
    } else {
      uint256 cfiType = _sftEvaluatorOld.getCFolioItemType(tokenId);
      _removeInvestment(from, uint256(-1), tokenId, cfiType, yCrvBulk);
      result = abi.encodePacked(cfiType);
    }
  }

  function _removeInvestment(
    address from,
    uint256 baseTokenId,
    uint256 tokenId,
    uint256 cfiType,
    bool yCrvBulk
  ) private {
    address cfolioItem = _sftContractOld.tokenIdToAddress(tokenId);
    require(cfolioItem != address(0), 'M: Invalid cfi');
    address handler = IWOWSCryptofolioOld(cfolioItem)._tradefloors(0);

    uint256[] memory amounts = ICFolioItemHandler(handler).getAmounts(
      cfolioItem
    );

    if (cfiType >= 16) {
      // yearn
      require(amounts.length == 5, 'M: SC wrong');
      if (amounts[4] > 0) {
        amounts[0] = amounts[1] = amounts[2] = amounts[3] = 0;
        ICFolioItemHandler(handler).withdraw(baseTokenId, tokenId, amounts);
        if (yCrvBulk) {
          if (bulkLookup[from].amount == 0) {
            bulkLookup[from].partId = bulkParticipants.length;
            bulkParticipants.push(from);
          }
          bulkLookup[from].amount.add(amounts[4]);
        } else {
          _yCrvToken.safeTransfer(from, amounts[4]);
        }
      }
    } else {
      // LP token
      require(amounts.length == 1, 'M: LP wrong');
      if (amounts[0] > 0) {
        ICFolioItemHandler(handler).withdraw(baseTokenId, tokenId, amounts);
        _uniV2LPToken.safeTransfer(from, amounts[0]);
      }
    }
  }
} // Contract

