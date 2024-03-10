pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./ManagerRole.sol";
import "./Pausable.sol";
import "./IERC20.sol";

contract Stake is Pausable, ManagerRole {
    using SafeMath for uint256;
    
    struct StakeData {
        // Start time staking
        uint256 time;
        // Count token staking
        uint256 amount;
        // Start staking
        uint256 startStake;
        // End staking
        uint256 endStake;
        // Interval staking
        uint256 intervalStake;
        // Growth rate
        uint256 rate;
    }

    // Token stake interval
    uint256 private _intervalStake = 5 minutes;
    // Start of token stake
    uint256 private _startStake = block.timestamp;
    // Staking percentage received
    uint256 private _rate = 83000000000000000;

    // Address token staking
    address private _token;
    
    // Data all betters who are staking
    mapping(address => StakeData[]) public _betters;
    
    constructor(address token) public {
        _token = token;
    }
    
    /**
     * @dev Function staking tokens
     * @param better The address who is staking.
     * @param amount The amount of tokens to stake.
     * @return A boolean that indicates if the operation was successful.
     */
    function stake(address better, uint256 amount) public virtual whenNotPaused returns(bool) {
        require(better != address(0), "Stake: Zero token address");
        require(amount != 0, "Stake: The number of tokens transferred is not = 0");
        require(_startStake < block.timestamp, "Stake: Staking not started yet");
        
        uint256 endStake = _startStake.add(_intervalStake);
        
        if (endStake.add(_intervalStake) < block.timestamp) {
            _startStake = _startStake.add(_intervalStake);
            endStake = _startStake.add(_intervalStake);

            return stake(better, amount);
        }
        
        if (endStake < block.timestamp) {
            _startStake = _startStake.add(_intervalStake);
            endStake = _startStake.add(_intervalStake);
        }
        
        IERC20 token = IERC20(_token);
        
        token.transferFrom(msg.sender, address(this), amount);
        
        _betters[better].push(StakeData({
            time: block.timestamp,
            amount: amount,
            startStake: _startStake,
            endStake: endStake,
            intervalStake: _intervalStake,
            rate: _rate
        }));
        
        return true;
    }
    
    /**
     * @dev Function unstaking tokens
     * @param better The address who is unstaking.
     * @return A boolean that indicates if the operation was successful.
     */
    function unstake(address better) public virtual returns(bool) {
        require(better != address(0), "Stake: Zero token address");

        uint256 hoursFreeze = 0;
        uint256 interestRate = 0;
        uint256 betterAmount = 0;
        
        for(uint256 i = 0; i < _betters[better].length; i++) {
            if (_betters[better][i].endStake < block.timestamp && _betters[better][i].time != 0) {
                betterAmount = betterAmount.add(_betters[better][i].amount);
                hoursFreeze = _betters[better][i].endStake.sub(_betters[better][i].time).div(60); // 3600 hours
                interestRate = (_betters[better][i].amount.mul(_betters[better][i].rate).div(100000000000000000000)).mul(hoursFreeze);
                betterAmount = betterAmount.add(interestRate);
                
                delete _betters[better][i];
            }
        }
        
        require(betterAmount != 0, "Stake: The number of tokens transferred is not = 0");
        
        IERC20 token = IERC20(_token);
        token.transfer(better, betterAmount);
        
        return true;
    }
    
    /**
     * @dev Get precent earn player which stake tokrens
     * @param better The address who is unstaking.
     */
    function getPrecentEarn(address better) public view returns (uint256 profit) {
        uint256 hoursFreeze = 0;
        uint256 interestRate = 0;
        
        for(uint256 i = 0; i < _betters[better].length; i++) {
            if (_betters[better][i].endStake < block.timestamp && _betters[better][i].time != 0) {
                hoursFreeze = _betters[better][i].endStake.sub(_betters[better][i].time).div(60); // !!!!!!!!!!!!!!!!!!3600
                interestRate = (_betters[better][i].amount.mul(_betters[better][i].rate).div(100000000000000000000)).mul(hoursFreeze);
            }
        }
        
        return interestRate;
    }

    /**
     * @dev Internal function for transfer tokens with contract to recipient
     * @param recipient The address recipient tokens.
     * @param amount Amount token for sending recipient.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferToken(address recipient, uint256 amount) public virtual onlyManager returns(bool) {
        IERC20 token = IERC20(_token);
        token.transfer(recipient, amount);
        
        return true;
    }
    
    /**
     * @dev Set address token contract for staking
     * @param token Contract address token.
     * @return A boolean that indicates if the operation was successful.
     */
    function setToken(address token) public virtual onlyManager returns (bool) {
        _token = token;
        return true;
    }
    
    /**
     * @dev Set interval stake token
     * @param interval New interval staking.
     * @return A boolean that indicates if the operation was successful.
     */
    function setIntervalStake(uint256 interval) public virtual onlyManager returns (bool) {
        _intervalStake = interval;
        return true;
    }
    
    /**
     * @dev Set start new staking
     * @param start new timestamp start staking.
     * @return A boolean that indicates if the operation was successful.
     */
    function setStartStaking(uint256 start) public virtual onlyManager returns (bool) {
        _startStake = start;
        return true;
    }
    
    /**
     * @dev Set start new staking
     * @param rate new timestamp start staking.
     * @return A boolean that indicates if the operation was successful.
     */
    function setRate(uint256 rate) public virtual onlyManager returns (bool) {
        _rate = rate;
        return true;
    }
    
    /**
     * @dev Get address token staking
     * @return Address token contract.
     */
    function getToken() public view virtual returns(address) {
        return _token;
    }
    
    /**
     * @dev Get interval unstaking
     * @return Interval staking.
     */
    function getIntervalUnstake() public view virtual returns(uint256) {
        return _intervalStake;
    }
    
    /**
     * @dev Get start staking
     * @return A Number Start staking.
     */
    function getStartStake() public view virtual returns(uint256) {
        return _startStake;
    }
    
    /**
     * @dev Get betters collection length
     * @param owner Owner all collections rates.
     * @return Length rates owners.
     */
    function getBettersLength(address owner) public view virtual returns (uint256) {
        return _betters[owner].length;
    }
    
    /**
     * @dev Get better collection by id
     * @param owner Owner collection.
     * @param id Identifier collection.
     */
    function getBetter(address owner, uint256 id) public view virtual returns (uint256 time, uint256 amount, uint256 startStake, uint256 endStake, uint256 intervalStake, uint256 rate) {
        return (
            _betters[owner][id].time,
            _betters[owner][id].amount,
            _betters[owner][id].startStake,
            _betters[owner][id].endStake,
            _betters[owner][id].intervalStake,
            _betters[owner][id].rate
            );
    }

    /**
     * @dev Get current timestamp block
     * @return Current timestamp in unit format.
     */
    function timestamp() public view virtual returns(uint256) {
        return block.timestamp;
    }
}
