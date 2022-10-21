// SPDX-License-Identifier: MIT

/* Defiat 2020
* 
* This is the contract locking the UNISWAP liquidity
* UNISWAP liquidity token: 0xe2a1d215d03d7e9fa0ed66355c86678561e4940a
* Constructor has been initialized with 180 day of locking (see: timeLockDays in the code below)
* You can interact with the contract on Etherscan to check the _release time (linux timestamp)
* _releaseTime = 1614179400
* You can use an epoch converter to verify the release date is :
* Wednesday, February 24, 2021 3:10:00 PM [GMT Timezone]
* 
* How does this contract work?
* look at  the function release():
* it's the only function that has the _token.transfer method, thus that can send tokens.
* it requires the condiction require(block.timestamp >= _releaseTime)
* this ensures that this function, hence the token transfer can only be activated 
* after the _releaseTime.
* 
* As usual, any question feel free to reach out to us.
*/


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity ^0.6.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    constructor (IERC20 token, address beneficiary, uint256 timeLockDays) public {
        // solhint-disable-next-line not-rely-on-time
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = block.timestamp + (timeLockDays*24*3600);
        require(_releaseTime > block.timestamp, "ERRROR");
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }
    function canRelease() public view returns (bool) {
        if(_releaseTime < block.timestamp){return true;}
        else {return false;}
    }


    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.transfer(_beneficiary, amount);
    }
}

interface I_Defiat_Points {
    // 0x70c7d7856e1558210cfbf27b7f17853655752453
    function overrideDiscount(address _address, uint256 _newDiscount) external;
    //whitelist the Locking Contract at 100 (100%) discount
}
