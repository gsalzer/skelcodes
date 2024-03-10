pragma solidity ^0.5.10;

import "./ERC20Interface.sol";
import "./SafeMath.sol";

contract MoonFomo {

    using SafeMath for uint256;

    ERC20Interface MoondayToken;
    uint256 public roundCount;
    bool public killSwitch;
    uint256 public increment = 128100000;
    uint256 public initialPrice = 256200000000000;
    address payable public _owner;

    address payable public moonGoldHodlWallet = 0xd0caEeD5534C4f6DE09416060Cfac7f93d4e2478;
    address payable public moonCapitalHodlWallet = 0x2fe54E61a2AF6275d54e04B8952234Ee2F87d9fD;

    address payable public _dev1 = 0x4EFD33509c894A4D628a940cdcE10aBb4E2e1b94;
    address payable public _dev2 = 0x394c4CfB55B2638B8dC5A9521f755e38A499607a;

    struct RoundData{
      uint256 timer;
      uint256 ticketCount;
      uint256 userCount;
      uint256 jackpot;
      uint256 holderPool;
      mapping(address => uint256) ticketsOwned;
      mapping(address => uint256) claimList;
      mapping(address => uint256) reclaimed;
      mapping(uint256 => address) userRanks;
      bool ended;
    }

    mapping(uint256 => RoundData) public rounds;
    mapping(uint256 => uint256) public jackpotClaimed;

    event RoundStarted(uint256 round, uint256 endingTime);
    event TicketBought(address buyer, uint256 rankNumber, uint256 ticketAmount);
    event RoundEnded(uint256 round, uint256 jackpot, uint256 tickets);
    event TicketClaimed(uint256 round, address buyer, uint256 claimAmount);
    event DividendClaimed(uint256 round, address claimant, uint256 dividendAmount);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    constructor(address payable owner_, address payable _moonday) public {
      _owner = owner_;
      MoondayToken = ERC20Interface(_moonday);
    }

    /// Starts a round and adds transaction to jackpot
    /// @dev increments round count, initiates timer and loads jackpot
    function initRound(uint _amount) external payable onlyOwner {
      require(roundCount == 0 || rounds[roundCount].ended, "Previous Round Not Ended!");

      roundCount++;
      MoondayToken.transferFrom(msg.sender, address(this), _amount);
      rounds[roundCount].jackpot += _amount.mul(99).div(100);
      rounds[roundCount].timer = now + 10 hours;

      emit RoundStarted(roundCount, rounds[roundCount].timer);
    }

    /// Starts a round and adds transaction to jackpot
    /// @dev increments round count, initiates timer and loads jackpot
    function setPricing(uint256 _initialPrice, uint256 _increment) external onlyOwner {
      require(rounds[roundCount].timer < now, "Previous Round Not Ended!");

      initialPrice = _initialPrice;
      increment = _increment;
    }

    /// Calculate who is in which rank
    /// @dev calculates ticket owner
    /// @param _round the round to query
    /// @param _userIndex the ticket to query
    /// @return owner of ticket
    function getUserRank(uint256 _round, uint256 _userIndex) public view returns(address) {
      return rounds[_round].userRanks[_userIndex];
    }

    /// Calculate tickets owned by user
    /// @dev calculates tickets owned by user
    /// @param _round the round to query
    /// @param _user the user to query
    /// @return total tickets owned by user
    function getTicketsOwned(uint256 _round, address _user) public view returns(uint256) {
      return rounds[_round].ticketsOwned[_user];
    }

    /// Get ticket reimbursment amount by user
    /// @dev calculates returnable ticket cost to user
    /// @param _round the round to query
    /// @param _user the user to query
    /// @return ticket reimbursment amount for user
    function getClaimList(uint256 _round, address _user) public view returns(uint256) {
      return rounds[_round].claimList[_user];
    }

    /// Get dividends claimed user
    /// @dev calculates returnable ticket cost to user
    /// @param _round the round to query
    /// @param _user the user to query
    /// @return dividend claimed by user
    function getReclaim(uint256 _round, address _user) public view returns(uint256) {
      return rounds[_round].reclaimed[_user];
    }

    /// Calculate ticket cost
    /// @dev calculates ticket price based on current holder pool
    /// @return sumCost current cost of ticket
    function calcTicketCost(uint256 _amount) public view returns(uint256 sumCost) {
      uint256 a = (rounds[roundCount].ticketCount * increment);
      uint256 b = ((rounds[roundCount].ticketCount + _amount) * increment);

      sumCost = (initialPrice * _amount) + (a * _amount) + ((b - a) * _amount / 2);
    }

    /// Buy a ticket
    /// @dev purchases a ticket and distributes funds
    /// @return ticket index
    function buyTicket(uint256 _amount) external payable returns(uint256){
      require(rounds[roundCount].timer > now, "Round Ended!");

      uint256 ticketPrice = calcTicketCost(_amount);
      MoondayToken.transferFrom(msg.sender, address(this), ticketPrice);

      rounds[roundCount].jackpot += ticketPrice.div(10);
      rounds[roundCount].holderPool += ticketPrice.div(10);
      MoondayToken.transfer(moonGoldHodlWallet, ticketPrice.mul(9).div(100));
      MoondayToken.transfer(_owner, ticketPrice.mul(9).div(100));
      MoondayToken.transfer(_dev1, ticketPrice.div(100));
      MoondayToken.transfer(_dev2, ticketPrice.div(100));

      rounds[roundCount].ticketsOwned[msg.sender] += _amount;
      rounds[roundCount].claimList[msg.sender] += ticketPrice.sub(ticketPrice.mul(41).div(100));
      rounds[roundCount].userRanks[rounds[roundCount].userCount] = msg.sender;
      rounds[roundCount].userCount++;
      rounds[roundCount].ticketCount += _amount;

      if(!killSwitch){
        rounds[roundCount].timer += 4 * _amount;
      }
      emit TicketBought(msg.sender, rounds[roundCount].userCount, _amount);
      return rounds[roundCount].ticketCount;
    }

    /// Enable/Disable kill switch
    /// @dev toggles the kill switch, preventing additional time
    function toggleKill() external onlyOwner {
      killSwitch = !killSwitch;
    }

    /// End the current round
    /// @dev concludes round and pays owner
    function endRound() external {
      require(rounds[roundCount].timer < now, "Round Not Finished!");
      require(!rounds[roundCount].ended, "Round Already Ended!");

      uint256 totalClaim = rounds[roundCount].jackpot.mul(9).div(100);
      uint256 ticketLength = 51;
      if(rounds[roundCount].userCount < 51){
        ticketLength = rounds[roundCount].userCount;
      }

      totalClaim += rounds[roundCount].jackpot.mul(uint256(51).sub(ticketLength)).div(100);
      jackpotClaimed[roundCount] += totalClaim;
      MoondayToken.transfer(moonGoldHodlWallet, rounds[roundCount].jackpot.mul(2).div(10));
      MoondayToken.transfer(moonCapitalHodlWallet, rounds[roundCount].jackpot.mul(2).div(10));
      MoondayToken.transfer(_owner, totalClaim);

      rounds[roundCount].ended = true;
      emit RoundEnded(roundCount, rounds[roundCount].jackpot, rounds[roundCount].ticketCount);
    }

    /// Calculate total dividends for a round
    /// @param _round the round to query
    /// @param _ticketHolder the user to query
    /// @dev calculates dividends minus reinvested funds
    /// @return totalDividends total dividends
    function calcDividends(uint256 _round, address _ticketHolder) public view returns(uint256 totalDividends) {
      if(rounds[_round].ticketCount == 0){
        return 0;
      }
      totalDividends = rounds[_round].ticketsOwned[_ticketHolder].mul(rounds[_round].holderPool).div(rounds[_round].ticketCount);
      totalDividends = totalDividends.sub(rounds[_round].reclaimed[_ticketHolder]);
      return totalDividends;
    }

    /// Calculate total payout for a round
    /// @param _round the round to claim
    /// @param _ticketHolder the user to query
    /// @dev calculates jackpot earnings, dividends and ticket reimbursment
    /// @return totalClaim total claim
    function calcPayout(uint256 _round, address _ticketHolder) public view returns(uint256 totalClaim, uint256 jackpot) {
      if(rounds[_round].claimList[_ticketHolder] == 0){
        return (0, 0);
      }
      totalClaim = calcDividends(_round, _ticketHolder);
      uint256 percentageCount;
      uint256 ticketLength = 51;
      if(rounds[_round].userCount < 51){
        ticketLength = rounds[_round].userCount;
      }
      for(uint256 x = rounds[_round].userCount - ticketLength; x < rounds[_round].userCount; x++){
        if(rounds[_round].userRanks[x] == _ticketHolder){
          percentageCount++;
        }
      }
      jackpot = rounds[_round].jackpot.mul(percentageCount).div(100);
      totalClaim += jackpot;
      totalClaim += rounds[_round].claimList[_ticketHolder];
      return (totalClaim, jackpot);
    }

    /// Claim total dividends and winnings earned for a round
    /// @param _round the round to claim
    /// @dev calculates payout and pays user
    function claimPayout(uint256 _round) external {
      require(rounds[_round].timer < now, "Round Not Ended!");
      require(rounds[_round].claimList[msg.sender] > 0, "You Have Already Claimed!");

      (uint256 payout, uint256 jackpot) = calcPayout(_round, msg.sender);

      jackpotClaimed[_round] += jackpot;
      MoondayToken.transfer(msg.sender, payout);

      rounds[_round].claimList[msg.sender] = 0;

      emit TicketClaimed(_round, msg.sender, payout);
    }

    /// Claim total dividends in the current round
    /// @param _amount the amount to claim
    /// @dev calculates payout and pays user
    function claimDividends(uint256 _amount) external{
      require(calcDividends(roundCount, msg.sender) >= _amount, "Insufficient Dividends Available!");

      rounds[roundCount].reclaimed[msg.sender] += _amount;
      MoondayToken.transfer(msg.sender, _amount);

      emit DividendClaimed(roundCount, msg.sender, _amount);
    }

    /// Buy a ticket with dividends
    /// @dev purchases a ticket with dividends and distributes funds
    /// @return ticket index
    function reinvestDividends(uint256 _amount) external returns(uint256){
      uint256 ticketPrice = calcTicketCost(_amount);
      require(calcDividends(roundCount, msg.sender) >= ticketPrice, "Insufficient Dividends Available!");
      require(rounds[roundCount].timer > now, "Round Ended!");

      rounds[roundCount].jackpot += ticketPrice.div(10);
      rounds[roundCount].holderPool += ticketPrice.div(10);
      MoondayToken.transfer(moonGoldHodlWallet, ticketPrice.mul(9).div(100));
      MoondayToken.transfer(_owner, ticketPrice.mul(9).div(100));
      MoondayToken.transfer(_dev1, ticketPrice.div(100));
      MoondayToken.transfer(_dev2, ticketPrice.div(100));

      rounds[roundCount].reclaimed[msg.sender] += ticketPrice;
      rounds[roundCount].ticketsOwned[msg.sender] += _amount;
      rounds[roundCount].claimList[msg.sender] += ticketPrice.sub(ticketPrice.mul(41).div(100));
      rounds[roundCount].userRanks[rounds[roundCount].userCount] = msg.sender;
      rounds[roundCount].userCount++;
      rounds[roundCount].ticketCount += _amount;

      if(!killSwitch){
        rounds[roundCount].timer += 4 * _amount;
      }
      emit TicketBought(msg.sender, rounds[roundCount].userCount, _amount);
      return(rounds[roundCount].ticketCount);
    }

}

