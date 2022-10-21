// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import "./CryptoPunksInterface.sol";
import "./GachaSetting.sol";
import "./GachaState.sol";

contract PunkGacha is GachaSetting, GachaState, KeeperCompatibleInterface, VRFConsumerBase {
  CryptoPunksInterface private _cryptopunks;
  uint16 private _cryptopunksTotalSupply = 10000;

  uint256 private _withdrawableBalance;
  uint256 private _randomness;

  enum RoundStatus {
    OPEN,
    DRAW,
    CLOSE
  }

  struct Round {
    uint256 minValue;
    uint200 id;
    uint16 punkIndex;
    RoundStatus status;
  }

  Round public currentRound;

  event RoundClose(uint200 indexed roundId, address indexed winner, uint16 punkIndex);
  event PlayerBet(uint200 indexed roundId, address indexed player, uint96 amount);
  event PlayerRefund(uint200 indexed roundId, address indexed player, uint96 amount);

  constructor(
    address vrfCoordinator, // Chainlink VRF Coordinator address
    address link, // LINK token address
    bytes32 keyHash, // Public key against which randomness is generated
    uint256 fee, // Fee required to fulfill a VRF request, in wei
    address cryptopunks // CryptoPunks contract address
  ) VRFConsumerBase(vrfCoordinator, link) {
    setKeyHash(keyHash);
    setFee(fee);
    _cryptopunks = CryptoPunksInterface(cryptopunks);
    currentRound.status = RoundStatus.CLOSE;
  }

  function bet() external payable {
    require(currentRound.status == RoundStatus.OPEN, "round not open");
    require(msg.value >= minimumBetValue, "bet too less");
    require(msg.value < (1 << 96), "bet too much");

    emit PlayerBet(currentRound.id, msg.sender, uint96(msg.value));
    _stake(Chip(msg.sender, uint96(msg.value)));
  }

  function refund(uint256[] calldata chipIndexes) external {
    require(currentRound.status != RoundStatus.DRAW, "round is drawing");

    address payable sender = payable(msg.sender);
    uint256 refundAmount = _refund(msg.sender, chipIndexes);
    require(refundAmount > 0, "nothing to refund");
    sender.transfer(refundAmount);
    emit PlayerRefund(currentRound.id, msg.sender, uint96(refundAmount));
  }

  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    if (currentRound.status == RoundStatus.OPEN) {
      if (_checkMaintainSegment(0)) {
        return (true, checkData);
      }
      (bool isForSale, , , uint256 minValue, address onlySellTo) = _cryptopunks.punksOfferedForSale(
        currentRound.punkIndex
      );
      if (
        minValue > currentRound.minValue ||
        !isForSale ||
        (onlySellTo != address(0) && onlySellTo != address(this))
      ) {
        return (true, checkData);
      }
      if (
        totalAmount >= (currentRound.minValue * (1000 + serviceFeeThousandth)) / 1000 &&
        LINK.balanceOf(address(this)) >= _fee
      ) {
        return (true, checkData);
      }
      return (false, checkData);
    }
    if (currentRound.status == RoundStatus.DRAW) {
      return (_randomness != 0, checkData);
    }
    return (false, checkData);
  }

  // NOTE: can be called by anyone
  function performUpkeep(bytes calldata) external override {
    if (currentRound.status == RoundStatus.OPEN) {
      if (_checkMaintainSegment(0)) {
        _performMaintainSegment();
        return;
      }
      (bool isForSale, , , uint256 minValue, address onlySellTo) = _cryptopunks.punksOfferedForSale(
        currentRound.punkIndex
      );
      if (
        minValue > currentRound.minValue ||
        !isForSale ||
        (onlySellTo != address(0) && onlySellTo != address(this))
      ) {
        emit RoundClose(currentRound.id, address(0), currentRound.punkIndex);
        currentRound.status = RoundStatus.CLOSE;
        return;
      }
      if (
        totalAmount >= (currentRound.minValue * (1000 + serviceFeeThousandth)) / 1000 &&
        LINK.balanceOf(address(this)) >= _fee
      ) {
        _cryptopunks.buyPunk{value: minValue}(currentRound.punkIndex);
        _withdrawableBalance += totalAmount - minValue;
        requestRandomness(_keyHash, _fee);
        currentRound.status = RoundStatus.DRAW;
        return;
      }
      revert("not enough LINK or ETH");
    }
    if (currentRound.status == RoundStatus.DRAW) {
      require(_randomness != 0, "randomness not fulfilled");
      address winner = _pick(_randomness);
      delete _randomness;
      require(winner != address(0), "cannot pick winner");
      _cryptopunks.offerPunkForSaleToAddress(currentRound.punkIndex, 0, winner);
      emit RoundClose(currentRound.id, winner, currentRound.punkIndex);
      currentRound.status = RoundStatus.CLOSE;
      _reset();
      return;
    }
    revert("unknown status");
  }

  // NOTE: max 200,000 gas
  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    require(currentRound.status == RoundStatus.DRAW, "round not drawing");
    _randomness = randomness;
  }

  function nextRound(uint256 _punkIndex) external {
    require(!isPaused, "is paused");
    require(currentRound.status == RoundStatus.CLOSE, "round not close");
    require(_punkIndex < _cryptopunksTotalSupply, "invalid punk index");
    require(
      msg.sender == owner() || msg.sender == _cryptopunks.punkIndexToAddress(_punkIndex),
      "no permission"
    );
    (bool isForSale, , , uint256 minValue, address onlySellTo) = _cryptopunks.punksOfferedForSale(
      _punkIndex
    );
    require(
      isForSale && (onlySellTo == address(0) || onlySellTo == address(this)),
      "punk not for sale"
    );
    require(minValue <= maximumPunkValue, "punk too expensive");

    currentRound = Round(minValue, currentRound.id + 1, uint16(_punkIndex), RoundStatus.OPEN);
  }

  function withdrawLink() external onlyOwner {
    require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "unable to withdraw LINK");
  }

  function withdraw() external onlyOwner {
    require(currentRound.status == RoundStatus.CLOSE, "round not close");
    address payable _owner = payable(owner());
    _owner.transfer(_withdrawableBalance);
  }

  function destory() external onlyOwner {
    selfdestruct(payable(owner()));
  }
}

