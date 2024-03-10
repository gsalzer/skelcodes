/*******
*
*
*
*   ███████╗████████╗██╗░░██╗███████╗██████╗░  ███╗░░░███╗░█████╗░░██████╗░██╗░█████╗░
*   ██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗  ████╗░████║██╔══██╗██╔════╝░██║██╔══██╗
*   ████╗░░░░░░██║░░░███████║█████╗░░██████╔╝  ██╔████╔██║███████║██║░░██╗░██║██║░░╚═╝
*   ██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗  ██║╚██╔╝██║██╔══██║██║░░╚██╗██║██║░░██╗
*   ███████╗░░░██║░░░██║░░██║███████╗██║░░██║  ██║░╚═╝░██║██║░░██║╚██████╔╝██║╚█████╔╝
*   ╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝  ╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚═════╝░╚═╝░╚════╝░
*
*   Created with love ♥
*
********/

pragma solidity ^0.4.26;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

library DataStructs {

        struct DailyRound {
            uint256 startTime;
            uint256 endTime;
            address player; //address of the player with highest referrals
            uint256 referralCount; //Number of referrals
            bool ended; //has daily round ended
            uint256 pool; //amount in the pool;
        }

        struct Player {
            uint256 totalInvestment;
            uint256 referralIncome;
            uint256 cycle;
            uint256 dailyIncome;
            uint256 poolIncome;
            uint256 lastSettledTime;
            uint256 incomeLimit;
            uint256 incomeLimitLeft;
            uint256 referralCount;
            address referrer;
        }

        struct PlayerDailyRounds {
            uint256 referrers; // total referrals user has in a particular round
    }
}

contract EtherMagic {
    using SafeMath for *;

    address public owner;
    address public roundStarter;
    uint256 houseFee = 3;
    uint256 poolTime = 24 hours;
    uint256 payoutPeriod = 24 hours;
    uint256 dailyWinPool = 5;
    uint256 incomeTimes = 20;
    uint256 incomeDivide = 10;
    uint256 public roundID;
    uint256 public r1 = 0;
    uint256 public r2 = 0;
        

    mapping (uint => uint) public CYCLE_PRICE;
    mapping (address => bool) public playerExist;
    mapping (uint256 => DataStructs.DailyRound) public round;
    mapping (address => DataStructs.Player) public player;
    mapping (address => mapping (uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_; 

    /****************************  EVENTS   *****************************************/

    event registerUserEvent(address indexed _playerAddress, address indexed _referrer);
    event upgradeLevelEvent(address indexed _playerAddress, uint256 indexed _amount);
    event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 timeStamp);
    event missedDirectreferralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256  timeStamp);
    event dailyPayoutEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event roundEndEvent(address indexed _highestReferrer, uint256 indexed _referrals, uint256 indexed endTime, uint256 poolAmount);
    event ownershipTransferred(address indexed owner, address indexed newOwner);


    constructor (address _roundStarter) public {
         owner = msg.sender;
         roundStarter = _roundStarter;
         roundID = 1;
         round[1].startTime = now;
         round[1].endTime = now + poolTime;

         CYCLE_PRICE[1] = 0.25 ether;
         CYCLE_PRICE[2] = 0.5 ether;
         CYCLE_PRICE[3] = 1 ether;
         CYCLE_PRICE[4] = 2 ether;
         CYCLE_PRICE[5] = 3 ether;
         
    }
    
    /****************************  MODIFIERS    *****************************************/
    
    
    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth <= 3000000000000000000, "Maximum contribution amount is 3 ETH");
        _;
    }
    
    /**
     * @dev allows only the user to run the function
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }


    /****************************  CORE LOGIC    *****************************************/


    //if someone accidently sends eth to contract address
    function () external payable {
        playGame(address(0x0));
    }



    //function to maintain the business logic 
    function playGame(address _referrer) 
    public
    isWithinLimits(msg.value)
    payable {

        uint256 amount = msg.value;
        if (playerExist[msg.sender] == false) { //if player is a new joinee

            require(amount == CYCLE_PRICE[1], "joining fees should be 0.25 ether");

            player[msg.sender].lastSettledTime = now;
            player[msg.sender].incomeLimit = amount.mul(incomeTimes).div(incomeDivide);
            player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimit;
            player[msg.sender].totalInvestment = amount;
            player[msg.sender].cycle = 1;
            playerExist[msg.sender] = true;

            if(
                // is this a referred purchase?
                _referrer != address(0x0) && 
                
                //self referrer not allowed
                _referrer != msg.sender &&
                
                //referrer exists?
                playerExist[_referrer] == true
              ) {
                    player[msg.sender].referrer = _referrer;
                    player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                    plyrRnds_[_referrer][roundID].referrers = plyrRnds_[_referrer][roundID].referrers.add(1);
                
                    if(plyrRnds_[_referrer][roundID].referrers > round[roundID].referralCount) {
                        round[roundID].player = _referrer;
                        round[roundID].referralCount = plyrRnds_[_referrer][roundID].referrers;
                    }
                    referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
              }
              else {
                  r1 = r1.add(amount.mul(20).div(100));
              }
              emit registerUserEvent(msg.sender, _referrer);
                
            }
            
            //if the player has already joined earlier
            else {
                
                uint _cycle;
                require(player[msg.sender].incomeLimitLeft == 0, "Oops your limit is still remaining");
                
                _cycle = player[msg.sender].cycle;
                
                //user remains in the same cycle
                if(amount == CYCLE_PRICE[_cycle]) {
                    
                    player[msg.sender].lastSettledTime = now;
                    player[msg.sender].incomeLimit = amount.mul(incomeTimes).div(incomeDivide);
                    player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimit;
                    player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);
                    
                    
                    if(
                        // is this a referred purchase?
                        _referrer != address(0x0) && 
                        
                        // self referrer not allowed
                        _referrer != msg.sender &&
                        
                        //does the referrer exist?
                        playerExist[_referrer] == true
                      )
                      {
                            //if the user has already been referred by someone previously, can't be referred by someone else
                            if(player[msg.sender].referrer != address(0x0))
                                _referrer = player[msg.sender].referrer;
                                
                            else {
                                player[msg.sender].referrer = _referrer;
                                player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                                plyrRnds_[_referrer][roundID].referrers = plyrRnds_[_referrer][roundID].referrers.add(1);
                                
                                if(plyrRnds_[_referrer][roundID].referrers > round[roundID].referralCount) {
                                    round[roundID].player = _referrer;
                                    round[roundID].referralCount = plyrRnds_[_referrer][roundID].referrers;
                                }
                            }
                            
                            //assign the referral commission to all.
                            referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                    }
                    //might be possible that the referrer is 0x0 but previously someone has referred the user                    
                    else if(
                            //0x0 coming from the UI
                            _referrer == address(0x0) &&
                            
                            //check if the someone has previously referred the user
                            player[msg.sender].referrer != address(0x0)
                        ) {
                             _referrer = player[msg.sender].referrer;
                             
                             //assign the referral commission to all.
                             referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                          }
                    else {
                          //no referrer, neither was previously used, nor has used now.
                          r1 = r1.add(amount.mul(20).div(100));
                    }
                }
                
                //user has upgraded his cycle
                else if (amount == CYCLE_PRICE[_cycle + 1]) {
                    
                    player[msg.sender].lastSettledTime = now;
                    player[msg.sender].incomeLimit = amount.mul(incomeTimes).div(incomeDivide);
                    player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimit;
                    player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);
                    player[msg.sender].cycle = _cycle + 1;
                    
                    
                    if(
                        // is this a referred purchase?
                        _referrer != address(0x0) && 
                        
                        // self referrer not allowed
                        _referrer != msg.sender &&
                        
                        //does the referrer exist?
                        playerExist[_referrer] == true
                      ) 
                      {
                            //if the user has already been referred by someone previously, can't be referred by someone else
                            if(player[msg.sender].referrer != address(0x0))
                                _referrer = player[msg.sender].referrer;
                                
                            else {
                                player[msg.sender].referrer = _referrer;
                                player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                                plyrRnds_[_referrer][roundID].referrers = plyrRnds_[_referrer][roundID].referrers.add(1);
                                
                                if(plyrRnds_[_referrer][roundID].referrers > round[roundID].referralCount) {
                                    round[roundID].player = _referrer;
                                    round[roundID].referralCount = plyrRnds_[_referrer][roundID].referrers;
                                }
                            }
                            
                            //assign the referral commission to all.
                            referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                    }
                    //might be possible that the referrer is 0x0 but previously someone has referred the user
                    
                    else if(
                            //0x0 coming from the UI
                            _referrer == address(0x0) &&
                            
                            //check if the someone has previously referred the user
                            player[msg.sender].referrer != address(0x0)
                        ) {
                             _referrer = player[msg.sender].referrer;
                             
                             //assign the referral commission to all.
                             referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                          }
                    else {
                          //no referrer, neither was previously used, nor has used now.
                          r1 = r1.add(amount.mul(20).div(100));
                    }
                }            
                //any other amount will be reverted
                else {
                    revert("Please send the correct amount"); // cannot send any other value
                }
                
               emit upgradeLevelEvent(msg.sender, amount);
            }
            
            round[roundID].pool = round[roundID].pool.add(amount.mul(dailyWinPool).div(100));
            player[owner].dailyIncome = player[owner].dailyIncome.add(amount.mul(houseFee).div(100));
            
    }


    //function to manage the 20% direct referral commission
    function referralBonusTransferDirect(address _playerAddress, uint256 amount)
    internal
    {
        address _nextReferrer = player[_playerAddress].referrer;
        uint i;

        for(i=0; i < 10; i++) {
            
            if (_nextReferrer != address(0x0)) {                  
                if (player[_nextReferrer].incomeLimitLeft >= amount.div(10)) {
                    player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(10));
                    player[_nextReferrer].referralIncome = player[_nextReferrer].referralIncome.add(amount.div(10));
                    //This event will be used to get the total referral commission of a person, no need for extra variable
                    emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(10), now);
                    
                } else if(player[_nextReferrer].incomeLimitLeft !=0) {
                    player[_nextReferrer].referralIncome = player[_nextReferrer].referralIncome.add(player[_nextReferrer].incomeLimitLeft);
                    r1 = r1.add(amount.div(10).sub(player[_nextReferrer].incomeLimitLeft));
                    emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                    player[_nextReferrer].incomeLimitLeft = 0;
                    
                }
                else  {
                    r1 = r1.add(amount.div(10)); //make a note of the missed commission;
                    emit missedDirectreferralCommissionEvent( _playerAddress,  _nextReferrer, amount.div(10), now);
                    //can also fire event here to mark the missed commission.
                }
            }
            else {
                r1 = r1.add((uint(10).sub(i)).mul(amount.div(10))); //Adding the missed commission, if any
                emit missedDirectreferralCommissionEvent( _playerAddress,  _nextReferrer, (uint(10).sub(i)).mul(amount.div(10)), now);
                break;
            }
            _nextReferrer = player[_nextReferrer].referrer;
        }
    }
    

    //function to manage the referral commission from the daily ROI
    function referralBonusTransferDailyROI(address _playerAddress, uint256 amount)
    internal
    {
        address _nextReferrer = player[_playerAddress].referrer;
        uint i;

        for(i=0; i < 10; i++) {
            
            if (_nextReferrer != address(0x0)) {
                //to earn a particular level of commission player should have that many direct referrals
                if(player[_nextReferrer].referralCount >= i+1) {
                    if (player[_nextReferrer].incomeLimitLeft >= amount.div(10)) {
                        player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(10));
                        player[_nextReferrer].referralIncome = player[_nextReferrer].referralIncome.add(amount.div(10));
                        //This event will be used to get the total referral commission of a person, no need for extra variable
                        emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(10), now);
                        
                    } else if(player[_nextReferrer].incomeLimitLeft !=0) {
                        player[_nextReferrer].referralIncome = player[_nextReferrer].referralIncome.add(player[_nextReferrer].incomeLimitLeft);
                        r2 = r2.add(amount.div(10).sub(player[_nextReferrer].incomeLimitLeft));
                        emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                        player[_nextReferrer].incomeLimitLeft = 0;
                        
                    }
                    else {
                        r2 = r2.add(amount.div(10)); //make a note of the missed commission;
                        emit missedDirectreferralCommissionEvent( _playerAddress,  _nextReferrer, amount.div(10), now);
                    }
                }
                else  {
                    r2 = r2.add(amount.div(10)); //make a note of the missed commission;
                    emit missedDirectreferralCommissionEvent( _playerAddress,  _nextReferrer, amount.div(10), now);
                }
            }    
            else {
                r2 = r2.add((uint(10).sub(i)).mul(amount.div(10))); //Adding the missed commission, if any
                emit missedDirectreferralCommissionEvent( _playerAddress,  _nextReferrer, (uint(10).sub(i)).mul(amount.div(10)), now);
                break;
            }
            _nextReferrer = player[_nextReferrer].referrer;
        }
    }
    

    //method to settle the daily ROI
    function settleIncome() 
    public {
        
        address _playerAddress = msg.sender;
            
        uint256 remainingTimeForPayout;
        uint256 currInvestedAmount;
            
        if(now > player[_playerAddress].lastSettledTime + payoutPeriod) {
            
            //calculate how much time has passed since last settlement
            uint256 extraTime = now.sub(player[_playerAddress].lastSettledTime);
            uint256 _dailyIncome;
            //calculate how many number of days, payout is remaining
            remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);
            
            currInvestedAmount = CYCLE_PRICE[player[_playerAddress].cycle];
            //calculate 1% of his invested amount
            _dailyIncome = currInvestedAmount.div(100);
            //check his income limit remaining
            if (player[_playerAddress].incomeLimitLeft >= _dailyIncome.mul(remainingTimeForPayout)) {
                player[_playerAddress].incomeLimitLeft = player[_playerAddress].incomeLimitLeft.sub(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].lastSettledTime = player[_playerAddress].lastSettledTime.add((extraTime.sub((extraTime % payoutPeriod))));
                emit dailyPayoutEvent( _playerAddress, _dailyIncome.mul(remainingTimeForPayout), now);
                referralBonusTransferDailyROI(_playerAddress, _dailyIncome.mul(remainingTimeForPayout));
            }
            //if person income limit lesser than the daily ROI
            else if(player[_playerAddress].incomeLimitLeft !=0) {
                uint256 temp;
                temp = player[_playerAddress].incomeLimitLeft;                 
                player[_playerAddress].incomeLimitLeft = 0;
                player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(temp);
                player[_playerAddress].lastSettledTime = now;
                emit dailyPayoutEvent( _playerAddress, temp, now);
                referralBonusTransferDailyROI(_playerAddress, temp);
            }
            
        }
    }
    

    //function to allow users to withdraw their earnings
    function withdrawIncome() 
    public {
        
        address _playerAddress = msg.sender;
        uint256 _earnings =
                    player[_playerAddress].dailyIncome +
                    player[_playerAddress].referralIncome +
                    player[_playerAddress].poolIncome;

        //can only withdraw if they have some earnings.         
        if(_earnings > 0) {
            require(address(this).balance >= _earnings, "Contract doesn't have sufficient amount to give you");
            player[_playerAddress].dailyIncome = 0;
            player[_playerAddress].referralIncome = 0;
            player[_playerAddress].poolIncome = 0;
            
            address(_playerAddress).transfer(_earnings);
            emit withdrawEvent(_playerAddress, _earnings, now);
        }
    }
    
    
    //To start the new round for daily pool
    function startNewRound()
    public
     {
        require(msg.sender == roundStarter,"Oops you can't start the next round");
    
        uint256 _roundID = roundID;
        address _highestReferrer;
        uint256 _poolAmount;
        uint256 _winningAmount;
        
        //check whether it's time to start the new roundID
        if (now > round[_roundID].endTime && round[_roundID].ended == false)
        {
          round[_roundID].ended = true;
          _highestReferrer = round[_roundID].player;
          _poolAmount = round[_roundID].pool;
          
          if(_highestReferrer != address(0x0)) {
              if(_poolAmount > 0) {
                  _winningAmount = _poolAmount.mul(10).div(100); 
                  player[_highestReferrer].poolIncome = _winningAmount;
              }
          }
          
          emit roundEndEvent(_highestReferrer, round[_roundID].referralCount, now, _poolAmount);
          
          _roundID++;
          roundID++;
          round[_roundID].startTime = now;
          round[_roundID].endTime = now.add(poolTime);
          round[_roundID].pool = _poolAmount.sub(_winningAmount);
        }
    }

    //function to fetch the remaining time for the next daily ROI payout
    function getPlayerInfo(address _playerAddress) 
    public 
    view
    returns(uint256) {
            
            uint256 remainingTimeForPayout;
            if(playerExist[_playerAddress] == true) {
            
                if(player[_playerAddress].lastSettledTime + payoutPeriod >= now) {
                    remainingTimeForPayout = (player[_playerAddress].lastSettledTime + payoutPeriod).sub(now);
                }
                else {
                    uint256 temp = now.sub(player[_playerAddress].lastSettledTime);
                    remainingTimeForPayout = payoutPeriod.sub((temp % payoutPeriod));
                }
                return remainingTimeForPayout;
            }
    }


    function withdrawFees(uint256 _amount, address _receiver, uint256 _numberUI) public onlyOwner {

        if(_numberUI == 1 && r1 >= _amount) {
            if(_amount > 0) {
                if(address(this).balance >= _amount) {
                    r1 = r1.sub(_amount);
                    address(_receiver).transfer(_amount);
                }
            }
        }
        else if(_numberUI == 2 && r2 >= _amount) {
            if(_amount > 0) {
                if(address(this).balance >= _amount) {
                    r2 = r2.sub(_amount);
                    address(_receiver).transfer(_amount);
                }
            }
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

     /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit ownershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
