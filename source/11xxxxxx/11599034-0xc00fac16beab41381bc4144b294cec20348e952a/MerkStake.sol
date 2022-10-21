pragma solidity ^0.5.0;

import "./MerkCoin.sol";
//import "./SafeMath.sol";
//import "./SafeERC20.sol";


/**
 * @title MerkStake
 * MerkStake is a token stake contract that will allow daily minting
 * to beneficiary, and allow beneficiary to extract the tokens after a given release time.
 */
contract MerkStake /*is TokenTimelock*/ {

    //using SafeMath for uint256;
    //using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    MerkCoin private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // amount will be release each success call
    uint256 private _releaseAmount;

    // timestamp when token release is enabled
    uint32 private _releaseTime;

    // last given release at (timestamp)
    uint32 private _lastReleaseTime;


    constructor (MerkCoin token, address beneficiary, uint256 releaseAmount, uint32 releaseTime) public {
        // solhint-disable-next-line not-rely-on-time
        //require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");

        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
        _releaseAmount = releaseAmount;
        _lastReleaseTime = _releaseTime;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (MerkCoin) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time since then the tokens can be released.
     */
    function releaseTime() public view returns (uint32) {
        return _releaseTime;
    }

    /**
     * @return amount of token can be released a time.
     */
    function releaseAmount() public view returns (uint256) {
        return _releaseAmount;
    }

    /**
     * @return last released time.
     */
    function lastReleaseTime() public view returns (uint32) {
        return _lastReleaseTime;
    }

    /**
     * @return balance of the stake.
     */
    function balance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary base on release rate (5%) / week (7 days).
     */
    function release() public returns (bool) {
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "MerkStake: no tokens to release");

        // solhint-disable-next-line not-rely-on-time
        uint lastBlockTime = block.timestamp;

        require(lastBlockTime >= _releaseTime, "MerkStake: current time is before release time");

        // only able to release after each 7-days (7 * 24* 3600 = 604,800)
        uint32 nowReleaseTime = _lastReleaseTime + 604800;
        require(lastBlockTime >= nowReleaseTime, "MerkStake: token is only able to release each week (7 days)");

        // calculate number of tokens to release
        uint256 releasableAmount = (amount > _releaseAmount) ? _releaseAmount : amount;

        // transfer token to beneficiary address
        _token.transfer(_beneficiary, releasableAmount);

        // save release time
        _lastReleaseTime = nowReleaseTime;

        return true;
    }
}
