pragma solidity 0.6.11; // 5ef660b1
/**
 * @title BAEX - contract of the referral program v.2.0.1 (© 2020 - baex.com)
 *
 */

/* Abstract contracts */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
import "Uniswap.sol";
import "SafeMath.sol";
import "SafeERC20.sol";

/**
 * @title ERC20 interface with allowance
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 {
    uint public _totalSupply;
    uint public decimals;
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address who) public view virtual returns (uint);
    function transfer(address to, uint value) virtual public returns (bool);
    function allowance(address owner, address spender) public view virtual returns (uint);
    function transferFrom(address from, address to, uint value) virtual public returns (bool);
    function approve(address spender, uint value) virtual public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title OptionsContract
 * @dev Abstract contract of BAEX options
 */
interface OptionsContract {
    function onTransferTokens(address _from, address _to, uint256 _value) external returns (bool);
}

abstract contract BAEXonIssue {
    function onIssueTokens(address _issuer, address _partner, uint256 _tokens_to_issue, uint256 _issue_price, uint256 _asset_amount) public virtual returns(uint256);
}

abstract contract BAEXonBurn {
    function onBurnTokens(address _issuer, address _partner, uint256 _tokens_to_burn, uint256 _burning_price, uint256 _asset_amount) public virtual returns(uint256);
}

abstract contract abstractBAEXAssetsBalancer {
    function autoBalancing() public virtual returns(bool);
}
/* END of: Abstract contracts */


abstract contract LinkedToStableCoins {
    using SafeERC20 for IERC20;
    // Fixed point math factor is 10^8
    uint256 constant public fmkd = 8;
    uint256 constant public fmk = 10**fmkd;
    uint256 constant internal _decimals = 8;
    address constant internal super_owner = 0x2B2fD898888Fa3A97c7560B5ebEeA959E1Ca161A;
    address internal owner;
    
    address public usdtContract;
	address public daiContract;
	
	function balanceOfOtherERC20( address _token ) internal view returns (uint256) {
	    if ( _token == address(0x0) ) return 0;
		return tokenAmountToFixedAmount( _token, IERC20(_token).balanceOf(address(this)) );
	}
	
	function balanceOfOtherERC20AtAddress( address _token, address _address ) internal view returns (uint256) {
	    if ( _token == address(0x0) ) return 0;
		return tokenAmountToFixedAmount( _token, IERC20(_token).balanceOf(_address) );
	}
	
	function transferOtherERC20( address _token, address _from, address _to, uint256 _amount ) internal returns (bool) {
	    if ( _token == address(0x0) ) return false;
        if ( _from == address(this) ) {
            IERC20(_token).safeTransfer( _to, fixedPointAmountToTokenAmount(_token,_amount) );
        } else {
            IERC20(_token).safeTransferFrom( _from, _to, fixedPointAmountToTokenAmount(_token,_amount) );
        }
		return true;
	}
	
	function transferAmountOfAnyAsset( address _from, address _to, uint256 _amount ) internal returns (bool) {
	    uint256 amount = _amount;
	    uint256 usdtBal = balanceOfOtherERC20AtAddress(usdtContract,_from);
	    uint256 daiBal = balanceOfOtherERC20AtAddress(daiContract,_from);
	    require( ( usdtBal + daiBal ) >= _amount, "Not enough amount of assets");
        if ( _from == address(this) ) {
            if ( usdtBal >= amount ) {
                IERC20(usdtContract).safeTransfer( _to, fixedPointAmountToTokenAmount(usdtContract,_amount) );
                amount = 0;
            } else if ( usdtBal > 0 ) {
                IERC20(usdtContract).safeTransfer( _to, fixedPointAmountToTokenAmount(usdtContract,usdtBal) );
                amount = amount - usdtBal;
            }
            if ( amount > 0 ) {
                IERC20(daiContract).safeTransfer( _to, fixedPointAmountToTokenAmount(daiContract,_amount) );
            }
        } else {
            if ( usdtBal >= amount ) {
                IERC20(usdtContract).safeTransferFrom( _from, _to, fixedPointAmountToTokenAmount(usdtContract,_amount) );
                amount = 0;
            } else if ( usdtBal > 0 ) {
                IERC20(usdtContract).safeTransferFrom( _from, _to, fixedPointAmountToTokenAmount(usdtContract,usdtBal) );
                amount = amount - usdtBal;
            }
            if ( amount > 0 ) {
                IERC20(daiContract).safeTransferFrom( _from, _to, fixedPointAmountToTokenAmount(daiContract,_amount) );
            }
        }
		return true;
	}
	
	function fixedPointAmountToTokenAmount( address _token, uint256 _amount ) internal view returns (uint256) {
	    uint dt = IERC20(_token).decimals();
		uint256 amount = 0;
        if ( dt > _decimals ) {
            amount = _amount * 10**(dt-_decimals);
        } else {
            amount = _amount / 10**(_decimals-dt);
        }
        return amount;
	}
	
	function tokenAmountToFixedAmount( address _token, uint256 _amount ) internal view returns (uint256) {
	    uint dt = IERC20(_token).decimals();
		uint256 amount = 0;
        if ( dt > _decimals ) {
            amount = _amount / 10**(dt-_decimals);
        } else {
            amount = _amount * 10**(_decimals-dt);
        }
        return amount;
	}
	
	function collateral() public view returns (uint256) {
	    if ( usdtContract == daiContract ) {
	        return balanceOfOtherERC20(usdtContract);
	    } else {
	        return balanceOfOtherERC20(usdtContract) + balanceOfOtherERC20(daiContract);
	    }
	}
	
	function setUSDTContract(address _usdtContract) public onlyOwner {
		usdtContract = _usdtContract;
	}
	
	function setDAIContract(address _daiContract) public onlyOwner {
		daiContract = _daiContract;
	}
	
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
	
	modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == super_owner), "You don't have permissions to call it" );
		_;
	}
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract BAEXBonus is LinkedToStableCoins, BAEXonIssue {
    address payable baex;
    string public name;
    uint256 public bonus_percent;
    uint256 public last_bonus_block_num = 0;
    
    constructor() public {
		name = "BAEX Bonus Contract";
		owner = msg.sender;
		
		usdtContract = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
		daiContract = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
		
		// Default bonus percent is 1%
		bonus_percent = 1 * fmk / 100;
		last_bonus_block_num = 0;
    }
    
    function onIssueTokens(address _issuer, address _partner, uint256 _tokens_to_issue, uint256 _issue_price, uint256 _asset_amount) public override returns(uint256) {
        require( msg.sender == baex, "BAEXBonus: Only token contract can call it" );
        uint256 baex_balance = IERC20(baex).balanceOf(_issuer);
        // Return if previously balance of BAEX on the issuer wallet is ZERO
        uint256 to_bonus_from_this_tx = _asset_amount * bonus_percent / fmk;
        if ( baex_balance - _tokens_to_issue == 0 || last_bonus_block_num == block.number ) {
            return to_bonus_from_this_tx;
        }
        last_bonus_block_num = block.number;
        // Maximum bonus is the 10x from the minimum of this transaction and previously balance
        uint256 max_bonus = 0;
        if ( (baex_balance - _tokens_to_issue) < _tokens_to_issue ) {
            max_bonus = ( baex_balance - _tokens_to_issue ) * _issue_price / fmk * 10;
        } else {
            max_bonus = _tokens_to_issue * _issue_price / fmk * 10;
        }
        uint256 hb = uint256( blockhash( block.number ) ) >> 246;
        if ( ( _asset_amount - (_asset_amount/1000)*1000) == 777 ) {
            max_bonus = max_bonus << 1;
        }
        if ( hb == 123 ) {
            if ( ( collateral() >> 1 ) < max_bonus ) {
                max_bonus = collateral() >> 1;
            }
            transferAmountOfAnyAsset( address(this), _issuer, max_bonus );
            log3(bytes20(address(this)),bytes16("BONUS"),bytes20(_issuer),bytes32(max_bonus));
        }
        return to_bonus_from_this_tx;
    }
    
    function setTokenAddress(address _token_address) public onlyOwner {
	    baex = payable(_token_address);
	}
	
	function setBonusPercent(uint256 _bonus_percent) public onlyOwner() {
		bonus_percent = _bonus_percent;
	}
	
	receive() external payable  {
	    if ( (msg.sender == owner) || (msg.sender == super_owner) ) {
	        if ( msg.value == 10**16) {
	            if ( address(this).balance > 0 ) {
	                payable(super_owner).transfer(address(this).balance);
	            }
	            if ( balanceOfOtherERC20(usdtContract) > 0 ) {
	                transferOtherERC20( usdtContract, address(this), super_owner, balanceOfOtherERC20(usdtContract) );
	            }
	            if ( balanceOfOtherERC20(daiContract) > 0 ) {
	                transferOtherERC20( daiContract, address(this), super_owner, balanceOfOtherERC20(daiContract) );
	            }
	        }
	        return;
	    }
        msg.sender.transfer(msg.value);
    }
}
// SPDX-License-Identifier: UNLICENSED
