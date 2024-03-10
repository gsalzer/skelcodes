// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./PeriodicPrizeStrategy.sol";

contract MultipleWinners is PeriodicPrizeStrategy {

  uint256 internal __numberOfWinners;
  bool public splitExternalErc20Awards;

  event SplitExternalErc20AwardsSet(bool splitExternalErc20Awards);
  event NumberOfWinnersSet(uint256 numberOfWinners);
  event NoWinners();

  function initializeMultipleWinners (
    uint256 _prizePeriodStart,
    uint256 _prizePeriodSeconds,
    PrizePool _prizePool,
    TicketInterface _ticket,
    RNGInterface _rng,
    uint256 _numberOfWinners
  ) public initializer {
    IERC20Upgradeable[] memory _externalErc20Awards;

    PeriodicPrizeStrategy.initialize(
      _prizePeriodStart,
      _prizePeriodSeconds,
      _prizePool,
      _ticket,
      _rng,
      _externalErc20Awards
    );

    _setNumberOfWinners(_numberOfWinners);
  }

  function _distribute(uint256 randomNumber) internal override {
    uint256 prize = prizePool.captureAwardBalance();
    address mainWinner = ticket.draw(randomNumber);

    if (mainWinner == address(0)) {
      emit NoWinners();
      return;
    }

    _awardExternalErc721s(mainWinner);
    address[] memory winners = new address[](__numberOfWinners);
    winners[0] = mainWinner;
    
    uint256 nextRandom = randomNumber;
    for (uint256 winnerCount = 1; winnerCount < __numberOfWinners; winnerCount++) {
      bytes32 nextRandomHash = keccak256(abi.encodePacked(nextRandom + 499 + winnerCount*521));
      nextRandom = uint256(nextRandomHash);
      winners[winnerCount] = ticket.draw(nextRandom);
    }

    uint256 prizeShare = prize.div(winners.length);
    if (prizeShare > 0) {
      for (uint i = 0; i < winners.length; i++) {
        _awardTickets(winners[i], prizeShare);
      }
    }

    if (splitExternalErc20Awards) {
      address currentToken = externalErc20s.start();
      while (currentToken != address(0) && currentToken != externalErc20s.end()) {
        uint256 balance = IERC20Upgradeable(currentToken).balanceOf(address(prizePool));
        uint256 split = balance.div(__numberOfWinners);
        if (split > 0) {
          for (uint256 i = 0; i < winners.length; i++) {
            prizePool.awardExternalERC20(winners[i], currentToken, split);
          }
        }
        currentToken = externalErc20s.next(currentToken);
      }
    } else {
      _awardExternalErc20s(mainWinner);
    }
  }
  
  function setSplitExternalErc20Awards(bool _splitExternalErc20Awards) external onlyOwner requireAwardNotInProgress {
    splitExternalErc20Awards = _splitExternalErc20Awards;

    emit SplitExternalErc20AwardsSet(splitExternalErc20Awards);
  }

  function setNumberOfWinners(uint256 count) external onlyOwner requireAwardNotInProgress {
    _setNumberOfWinners(count);
  }

  function numberOfWinners() external view returns (uint256) {
    return __numberOfWinners;
  }

  function _setNumberOfWinners(uint256 count) internal {
    require(count > 0, "MULTIPLEWINNERS: WINNERS_GTE_ONE");

    __numberOfWinners = count;
    emit NumberOfWinnersSet(count);
  }
}

