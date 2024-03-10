/**
 *Submitted for verification at Etherscan.io on 2020-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import './unilock.sol';
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

/**
 * @dev Collection of functions related to the address type
 */

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */



contract uniLockFactory is uniLock {
    address[] public campaigns;
    address public toFee;
    uint public fee;
    address factory_owner;
    address public unl_address;
    address public uni_router;
    uint balance_required;
    uint active = 1;
    
    constructor(address _UNL,uint min_balance,uint _fee,address _uniRouter) public {
        factory_owner = msg.sender;
        toFee = msg.sender;
        unl_address = _UNL;
        balance_required = min_balance;
        fee = _fee;
        uni_router = _uniRouter;
    }
    modifier only_factory_Owner(){
        require(factory_owner == msg.sender,'You are not the owner');
        _;
    }
    //   1 ETH = 1 XYZ (_pool_rate = 1e18) <=> 1 ETH = 10 XYZ (_pool_rate = 1e19) <=> XYZ (decimals = 18)
    function createCampaign(uint _softCap,uint _hardCap,uint _start_date,uint _end_date,uint _rate,uint _min_allowed,uint _max_allowed,address _token,uint _pool_rate,uint _lock_duration) public returns (address campaign_address){
     require(IERC20(address(unl_address)).balanceOf(msg.sender) >= uint(balance_required),"You don't have the minimum UNL tokens required to launch a campaign");
     require(active==1,'Factory is not active');
     require(_softCap < _hardCap,"Error :  soft cap can't be higher than hard cap" );
     require(_start_date < _end_date ,"Error :  start date can't be higher than end date " );
     require(block.timestamp < _end_date ,"Error :  end date can't be higher than current date ");
     require(_min_allowed < _hardCap,"Error :  minimum allowed can't be higher than hard cap " );
     require(_rate != 0,"rate can't be null");
     bytes memory bytecode = type(uniLock).creationCode;
     bytes32 salt = keccak256(abi.encodePacked(_token, msg.sender));
     assembly {
            campaign_address := create2(0, add(bytecode, 32), mload(bytecode), salt)
     }
     uniLock(campaign_address).initilaize(_softCap,_hardCap,_start_date,_end_date,_rate,_min_allowed,_max_allowed,_token,msg.sender,_pool_rate,_lock_duration);
     campaigns.push(campaign_address);
     require(transferToCampaign(_hardCap,_rate,_pool_rate,_token,campaign_address),"unable to transfer funds");
    }
    function transferToCampaign(uint _hardCap,uint _rate, uint _pool_rate,address _token,address _campaign_address) internal returns(bool){

     require(IERC20(address(_token)).transferFrom(msg.sender,address(_campaign_address),(_hardCap.mul(_rate).div(1e18)).add(_hardCap.mul(_pool_rate).div(1e18))),"unable to transfer token amount to the campaign");
     return true;
    }
   function changeConfig(uint _fee,address _to,uint _balance_required,address _uni_router,address _unl_address) public only_factory_Owner returns(uint){
        fee = _fee;
        toFee = _to;
        balance_required = _balance_required;
        uni_router = _uni_router;
        unl_address = _unl_address;
    }

   function trigger() public only_factory_Owner returns(uint){
        active = active == 1 ? 0 : 1;
    } 

 
    
 


    
}
