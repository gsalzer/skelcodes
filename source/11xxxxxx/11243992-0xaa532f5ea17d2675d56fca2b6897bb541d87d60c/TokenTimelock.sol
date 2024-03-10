pragma solidity >=0.4.22 <0.8.0;

import "./SafeFarmOrDie.sol";

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time.
 */
contract TokenTimelock {
    using SafeFarmOrDie for IFarmOrDie;

    IFarmOrDie private _token;

    address private _beneficiary;

    uint256 private _releaseTime;

    constructor (IFarmOrDie token, address beneficiary, uint256 releaseTime) public {
        require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
    }

    function token() public view returns (IFarmOrDie) {
        return _token;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    function release() public {
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.safeTransfer(_beneficiary, amount);
    }
}
