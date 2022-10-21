pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./ManagerRole.sol";
import "./Detailed.sol";
import "./StarsToken.sol";
import "./ReentrancyGuard.sol";
import "./PausableCrowdsale.sol";

contract StarsSwap is PausableCrowdsale, ManagerRole {
    using SafeMath for uint256;

    // Count ETH transfer to player
    mapping(address => uint256) private _wagers;

    event TokensReleased(address beneficiary, uint256 amount);
    event TokensWithdrawn(address beneficiary, uint256 amount);
    event TokensTransfered(address beneficiary, uint256 amount);
    event VestingToggled(bool vested);

    struct TimelockData {
        // Stage opening time
        uint256 time;
        // Rates to unlock for crowdsale stages
        uint256[2] rates;
    }

    struct StageData {
        // Total number of supply tokens on certain stage
        uint256 supply;
        // Max amount of tokens to be contributed
        uint256 cap;
        // How many token units a buyer gets per TRX
        uint256 rate;
        // Tokens amount purchased by the buyer
        mapping (address => uint256) balances;
        // Tokens amount released by the buyer
        mapping (address => uint256) released;
    }

    // The last time of the token release by the buyer.
    mapping (address => uint256) private _times;

    // The vesting schedule
    TimelockData[] private _calendar;

    // The crowdsale stages
    StageData[] private _stages;

    // A current crowdsale stage
    uint256 private _currentStage = 0;

    // Lock/Unlock by vesting period
    bool private _vested = true;

    constructor(address payable wallet, IERC20 token) public Crowdsale(wallet, token) {
        _stages.push(StageData({
        supply: 0,
        cap: 1000000 * (10 ** 18),
        rate: 57150000000000
        }));

        _stages.push(StageData({
        supply: 0,
        cap: 1750000 * (10 ** 18),
        rate: 83330000000000
        }));

        _calendar.push(TimelockData({ time: uint256(1602504000), rates: [uint256(70), 70] }));
        _calendar.push(TimelockData({ time: uint256(1603713600), rates: [uint256(30), 30] }));
        // _calendar.push(TimelockData({ time: uint256(1836205675), rates: [uint256(0), 70] }));
        // _calendar.push(TimelockData({ time: uint256(1836205675), rates: [uint256(0), 30] }));
    }

    /**
    * @return the name of the token.
    */
    function name() public view virtual returns (string memory) {
        return ERC20Detailed(address(token())).name();
    }

    /**
    * @return the symbol of the token.
    */
    function symbol() public view virtual returns (string memory) {
        return ERC20Detailed(address(token())).symbol();
    }

    /**
    * @return the number of decimals of the token.
    */
    function decimals() public view virtual returns (uint8) {
        return ERC20Detailed(address(token())).decimals();
    }

    /**
    * @return uint256 representing current block timestamp as seconds since unix epoch
    */
    function timestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
    * @dev Returns true if the contract is lock by vesting logic, and false otherwise.
    */
    function vested() public view virtual returns (bool) {
        return _vested;
    }

    /**
    * @return the last time of the token release.
    */
    function timeOf(address owner) public view virtual returns (uint256) {
        return _times[owner];
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view virtual returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 0; i < _stages.length; i++) {
        balance = balance.add(_stages[i].balances[owner]);
        }
        return balance;
    }

    /**
    * @dev Gets the released token amount of the specified address.
    * @param owner The address to query the release of.
    * @return uint256 representing the amount released by the passed address.
    */
    function releasedOf(address owner) public view virtual returns (uint256) {
        uint256 release = 0;
        for (uint256 i = 0; i < _stages.length; i++) {
        release = release.add(_stages[i].released[owner]);
        }
        return release;
    }

    /**
    * @dev Gets the balance of the specified address at a certain stage.
    * @param id The stage identifier
    * @param owner The address to query the balance of.
    * @return uint256 representing the amount owned by the passed address.
    */
    function balanceOfStage(uint256 id, address owner) public view virtual returns (uint256) {
        return _stages[id].balances[owner];
    }

    /**
    * @dev Gets the release of the specified address at a certain stage.
    * @param id The stage identifier
    * @param owner The address to query the release of.
    * @return uint256 representing the amount released by the passed address.
    */
    function releasedOfStage(uint256 id, address owner) public view virtual returns (uint256) {
        return _stages[id].released[owner];
    }

    /**
    * @return uint256 representing the calender length.
    */
    function getCalendarLength() public view virtual returns (uint256) {
        return _calendar.length;
    }

    /**
    * @dev Gets the calendar certain stage data.
    * @param id The stage identifier
    * @return (uint256 time, uint256[2]) Stage start time and rates
    */
    function getCalendar(uint256 id) public view virtual returns (uint256, uint256[2] memory) {
        TimelockData memory timelock = _calendar[id];
        return (timelock.time, timelock.rates);
    }

    /**
    * @dev Gets the stage data by identifier
    * @return (uint256, uint256, uint256) total supply, stage cap & stage rate
    */
    function getStage(uint256 id) public view virtual returns (uint256, uint256, uint256) {
        StageData memory stage = _stages[id];
        return (stage.supply, stage.cap, stage.rate);
    }

    /**
    * @dev Gets the current crowdsale stage identifier
    * @return uint256 representing stage identifier
    */
    function getCurrentStage() public view virtual returns (uint256) {
        return _currentStage;
    }

    /**
    * @dev Set next crowdsale stage
    * @param stage The next stage identifier
    */
    function setCurrentStage(uint256 stage) public virtual onlyManager returns (bool) {
        require(stage < _stages.length, "TronStarsCrowdsale: new stage is greater than stages count");
        _currentStage = stage;
        return true;
    }

    /**
    * @dev Lock/Unlock vesting period
    * @param value Locked by vesting period if true
    */
    function toggleVesting(bool value) public virtual onlyManager {
        _vested = value;
        emit VestingToggled(value);
    }
    /**
    * @dev Transfer token for a specified addresses.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transferTokens(address to, uint256 value) public virtual onlyManager returns (bool) {
        uint256 totalSupply = 0;
        for (uint256 i = 0; i < _stages.length; i++) {
        totalSupply = totalSupply.add(_stages[i].supply);
        }

        uint256 balance = token().balanceOf(address(this));

        require(to != address(0), "TronStarsCrowdsale: transfer to the zero address");
        require(balance.sub(value) >= totalSupply, "TronStarsCrowdsale: transfer to much tokens");

        emit TokensTransfered(to, value);

        return token().transfer(to, value);
    }

    /**
    * @dev Calculates the amount that has already vested but hasn't been released yet.
    * @param beneficiary Whose tokens will be vested
    */
    function releasableAmount(address beneficiary) public view virtual returns (uint256) {
        TimelockData memory timelock;
        uint256[2] memory rates = [uint256(0),  0];
        for (uint256 i = 0; i < _calendar.length; i++) {
            timelock = _calendar[i];
            if (block.timestamp > timelock.time) {
            if (timelock.time > _times[beneficiary]) {
                rates[0] = rates[0].add(timelock.rates[0]);
                rates[1] = rates[1].add(timelock.rates[1]);
            }
            } else {
            break;
            }
        }

        uint256 amount = 0;
        uint256 available = 0;
        uint256 unreleased = 0;
        for (uint256 i = 0; i < _stages.length; i++) {
        unreleased = _stages[i].balances[beneficiary].sub(_stages[i].released[beneficiary]);
        if (rates[i] > 0 && unreleased > 0) {
            available = _stages[i].balances[beneficiary].mul(rates[i]).div(100);
            amount = amount.add(available);
        }
        }

        return amount;
    }

    /**
    * @dev Withraw tokens after crowdsale ends.
    * @param beneficiary Whose tokens will be withdrawn.
    */
    function withdrawTokens(address beneficiary) public virtual {
        require(!_vested, "TronStarsCrowdsale: locked by vesting period");

        uint256 balance = balanceOf(beneficiary);
        uint256 released = releasedOf(beneficiary);

        uint256 amount = balance.sub(released);

        require(amount > 0, "TronStarsCrowdsale: beneficiary is not due any tokens");

        for (uint256 i = 0; i < _stages.length; i++) {
        _stages[i].released[beneficiary] = _stages[i].balances[beneficiary];
        }

        _deliverTokens(beneficiary, amount);

        emit TokensWithdrawn(beneficiary, amount);
    }

    /**
    * @dev Release tokens after crowdsale ends.
    * @param beneficiary Whose tokens will be withdrawn.
    */
    function releaseTokens(address beneficiary) public virtual {
        TimelockData memory timelock;
        uint256[2] memory rates = [uint256(0),  0];
        for (uint256 i = 0; i < _calendar.length; i++) {
            timelock = _calendar[i];
            if (block.timestamp >= timelock.time) {
            if (timelock.time > _times[beneficiary]) {
                rates[0] = rates[0].add(timelock.rates[0]);
                rates[1] = rates[1].add(timelock.rates[1]);
            }
            } else {
            break;
            }
        }

        uint256 amount = 0;
        uint256 available = 0;
        uint256 unreleased = 0;
        for (uint256 i = 0; i < _stages.length; i++) {
        unreleased = _stages[i].balances[beneficiary].sub(_stages[i].released[beneficiary]);
        if (rates[i] > 0 && unreleased > 0) {
            available = _stages[i].balances[beneficiary].mul(rates[i]).div(100);

            _stages[i].released[beneficiary] = _stages[i].released[beneficiary].add(available);
            amount = amount.add(available);

            require(_stages[i].released[beneficiary] <= _stages[i].balances[beneficiary], "TronStarsCrowdsale: purchase amount exceeded");
        }
        }

        require(amount > 0, "TronStarsCrowdsale: beneficiary is not due any tokens");

        _times[beneficiary] = block.timestamp;
        _deliverTokens(beneficiary, amount);

        emit TokensReleased(beneficiary, amount);
    }

    /**
    * @dev Override to extend the way in which TRX is converted to tokens.
    * @param weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 weiAmount) internal view virtual override(Crowdsale) returns (uint256) {
        /* return weiAmount.mul(_stages[_currentStage].rate).div(1000000); */
        return (weiAmount.mul(1000000000000000000).div(_stages[_currentStage].rate)).div(2);
    }

    /**
    * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
    * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
    * `_deliverTokens` was called later).
    * @param beneficiary Token purchaser
    * @param tokenAmount Amount of tokens purchased
    */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal virtual override(Crowdsale) {
        StageData storage stage = _stages[_currentStage];

        require(stage.supply.add(tokenAmount) <= stage.cap, "TronStarsCrowdsale: stage cap exceeded");

        stage.supply = stage.supply.add(tokenAmount);

        mapping(address => uint256) storage balances = stage.balances;
        balances[beneficiary] = balances[beneficiary].add(tokenAmount);
    }

    /**
    * @dev Add stage for crowdsale.
    * @param supply Сount supply token.
    * @param cap The maximum number of tokens available for sale at this stage.
    * @param rate wei price per token unit.
    */
    function addStage(uint256 supply, uint256 cap, uint256 rate) public virtual onlyManager returns (bool) {
        require(cap > 0, 'StarsSwap: Cap must be greater than zero');
        require(rate > 0, 'StarsSwap: Rate must be greater than zero');
        
        _stages.push(StageData({
            supply: supply,
            cap: cap,
            rate: rate
        }));
        
        return true;
    }
    
    /**
    * @dev Add calendar unlock token.
    * @param time Time unlock token.
    * @param ratesFirst Share of unlocking at this stage.
    * @param ratesSecond Share of unlocking at this stage.
    */
    function addCalendar(uint256 time, uint256 ratesFirst, uint256 ratesSecond) public virtual onlyManager returns (bool) {
        require(time > 0, 'StarsSwap: Time must be greater than zero');

        _calendar.push(TimelockData({
            time: time,
            rates: [ratesFirst, ratesSecond]
        }));
        
        return true;
    }
    
    /**
    * @dev Change stage buy token.
    * @param id Id changes stage.
    * @param supply Сount supply token.
    * @param cap The maximum number of tokens available for sale at this stage.
    * @param rate wei price per token unit.
    */
    function changeStage(uint8 id, uint256 supply, uint256 cap, uint256 rate) public virtual onlyManager returns (bool) {
        _stages[id].supply = supply;
        _stages[id].cap = cap;
        _stages[id].rate = rate;
        
        return true;
    }
    
    /**
    * @dev Change calendar payouts.
    * @param id Id changes calendar.
    * @param rateFirst Share of unlocking at this stage.
    * @param rateSecond Share of unlocking at this stage.
    */
    function changeCalendar(uint8 id, uint256 time, uint256 rateFirst, uint256 rateSecond) public virtual onlyManager returns (bool) {
        _calendar[id].time = time;
        _calendar[id].rates[0] = rateFirst;
        _calendar[id].rates[1] = rateSecond;
        
        return true;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public virtual onlyManager whenNotPaused returns (bool) {
        Pausable._pause();
        return true;
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public virtual onlyManager whenPaused returns (bool) {
        Pausable._unpause();
        return true;
    }
}
