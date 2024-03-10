
pragma solidity ^0.4.24;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeMath64.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeERC20 for IERC20;

    uint64 constant internal SECONDS_PER_MONTH = 2628000;

    event TokensReleased(uint256 amount);
    event TokenVestingRevoked(uint256 amount);

    // beneficiary of tokens after they are released
    address private _beneficiary;
    // token being vested
    IERC20 private _token;

    uint64 private _cliff;
    uint64 private _start;
    uint64 private _vestingDuration;

    bool private _revocable;
    bool private _revoked;

    uint256 private _released;

    uint64[] private _monthTimestamps;
    uint256 private _tokensPerMonth;
    // struct MonthlyVestAmounts {
    //     uint timestamp;
    //     uint amount;
    // }

    // MonthlyVestAmounts[] private _vestings;

    /**
     * @dev Creates a vesting contract that vests its balance of the ERC20 token declared to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param token address of the token of the tokens being vested
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param vestingDuration duration in seconds of the total period in which the tokens will vest
     * @param revocable whether the vesting is revocable or not
     */
    constructor (address beneficiary, IERC20 token, uint64 start, uint64 cliffDuration, uint64 vestingDuration, bool revocable, uint256 totalTokens) public {
        require(beneficiary != address(0));
        require(token != address(0));
        require(cliffDuration < vestingDuration);
        require(start > 0);
        require(vestingDuration > 0);
        require(start.add(vestingDuration) > block.timestamp);
        _beneficiary = beneficiary;
        _token = token;
        _revocable = revocable;
        _vestingDuration = vestingDuration;
        _cliff = start.add(cliffDuration);
        _start = start;

        uint64 totalReleasingTime = vestingDuration.sub(cliffDuration);
        require(totalReleasingTime.mod(SECONDS_PER_MONTH) == 0);
        uint64 releasingMonths = totalReleasingTime.div(SECONDS_PER_MONTH);
        require(totalTokens.mod(releasingMonths) == 0);
        _tokensPerMonth = totalTokens.div(releasingMonths);
    
        for (uint64 month = 0; month < releasingMonths; month++) {
            uint64 monthTimestamp = uint64(start.add(cliffDuration).add(month.mul(SECONDS_PER_MONTH)).add(SECONDS_PER_MONTH));
            _monthTimestamps.push(monthTimestamp);
        }
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }
    /**
     * @return the address of the token vested.
     */
    function token() public view returns (address) {
        return _token;
    }
    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }
    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }
    /**
     * @return the duration of the token vesting.
     */
    function vestingDuration() public view returns (uint256) {
        return _vestingDuration;
    }
    /**
     * @return the amount of months to vest.
     */
    function monthsToVest() public view returns (uint256) {
        return _monthTimestamps.length;
    }
    /**
     * @return the amount of tokens vested.
     */
    function amountVested() public view returns (uint256) {
        uint256 vested = 0;

        for (uint256 month = 0; month < _monthTimestamps.length; month++) {
            uint256 monthlyVestTimestamp = _monthTimestamps[month];
            if (monthlyVestTimestamp > 0 && block.timestamp >= monthlyVestTimestamp) {
                vested = vested.add(_tokensPerMonth);
            }
        }

        return vested;
    }
    /**
     * @return true if the vesting is revocable.
     */
    function revocable() public view returns (bool) {
        return _revocable;
    }
    /**
     * @return the amount of the token released.
     */
    function released() public view returns (uint256) {
        return _released;
    }
    /**
     * @return true if the token is revoked.
     */
    function revoked() public view returns (bool) {
        return _revoked;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        require(block.timestamp > _cliff, "Cliff hasnt started yet.");
        uint256 amountToSend = 0;

        for (uint256 month = 0; month < _monthTimestamps.length; month++) {
            uint256 monthlyVestTimestamp = _monthTimestamps[month];
            if (monthlyVestTimestamp > 0) {
                if (block.timestamp >= monthlyVestTimestamp) {
                    _monthTimestamps[month] = 0;
                    amountToSend = amountToSend.add(_tokensPerMonth);
                } else {
                    break;
                }
            }
        }

        require(amountToSend > 0, "No tokens to release");

        _released += amountToSend;
        _token.safeTransfer(_beneficiary, amountToSend);
        emit TokensReleased(amountToSend);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     */
    function revoke() public onlyOwner {
        require(_revocable, "This vest cannot be revoked");
        require(!_revoked, "This vest has already been revoked");

        _revoked = true;
        uint256 amountToSend = 0;
        for (uint256 month = 0; month < _monthTimestamps.length; month++) {
            uint256 monthlyVestTimestamp = _monthTimestamps[month];
            if (block.timestamp <= monthlyVestTimestamp) {
                _monthTimestamps[month] = 0;
                amountToSend = amountToSend.add(_tokensPerMonth);
            }
        }

        require(amountToSend > 0, "No tokens to revoke");

        _token.safeTransfer(owner(), amountToSend);
        emit TokenVestingRevoked(amountToSend);
    }
}
