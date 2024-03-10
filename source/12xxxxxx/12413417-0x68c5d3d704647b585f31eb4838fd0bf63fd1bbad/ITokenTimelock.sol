// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC20.sol";

interface ITokenTimelock {

    struct TimelockData {
        bool locked;
        address benefactor;
        uint256 amount;
        uint256 releaseTime;
    }

    /**
     * @return the token address assigned to this time lock contract.
     */
    function token() external view returns (IERC20);

    /**
     * @param beneficiary - the address to lookup time lock data for
     * @return the beneficiary data of time locked tokens.
     */
    function timelockData(address beneficiary) external view returns (TimelockData memory);

    /**
     * set a token time lock 
     * @param beneficiary - the address to set time lock data for
     * @param amount - the amount of tokens to timelock
     * @param releaseTime - the timestamp to release the time lock
     */
    function setTimeLock(address beneficiary, uint256 amount, uint256 releaseTime) external;

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     * @param beneficiary - the address to release time lock for
     */
    function release(address beneficiary) external;

    // events
    event TimeLockSet(address indexed beneficiary, TimelockData newData);
    event Released(address indexed to, uint256 amount);
}
