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


contract BAEXReferral is LinkedToStableCoins, BAEXonIssue {
    address payable baex;
    
    string public name;
    uint256 public referral_percent1;
    uint256 public referral_percent2;
    uint256 public referral_percent3;
    uint256 public referral_percent4;
    uint256 public referral_percent5;
    
    mapping (address => address) partners;
    mapping (address => uint256) referral_balance;
    
    constructor() public {
		name = "BAEX Partners Program";
		owner = msg.sender;
		// Default referral percents is 
		//  2%      level 1
		//  1.5%    level 2
		//  0.5%    level 3
		referral_percent1 = 20 * fmk / 1000;
		referral_percent2 = 15 * fmk / 1000;
		referral_percent3 = 5 * fmk / 1000;
		referral_percent4 = 0;
		referral_percent5 = 0;
		
		usdtContract = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
		daiContract = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
		baex = 0x50089b34B86Dba296A69C27ffaa60123573F1f89;
    }
    
    function balanceOf(address _sender) public view returns (uint256 balance) {
		return referral_balance[_sender];
	}
    
    /**
    * @dev When someone issues BAEX tokens, referral % the USDT or DAI amount will be transferred from
	* @dev the BAEXReferral smart-contract to his referral partners.
    * @dev Read more about referral program at https://baex.com/#referral
    */
    function onIssueTokens(address _issuer, address _partner, uint256 _tokens_to_issue, uint256 _issue_price, uint256 _asset_amount) public override returns(uint256) {
        require( msg.sender == baex, "BAEXReferral: Only token contract can call it" );
        address partner1 = partners[_issuer];
        if ( partner1 == address(0) ) {
            if ( _partner == address(0) ) return 0;
            partners[_issuer] = _partner;
            partner1 = _partner;
        }
        uint256 assets_to_trans1 = (_tokens_to_issue*_issue_price/fmk) * referral_percent1 / fmk;
        uint256 assets_to_trans2 = (_tokens_to_issue*_issue_price/fmk) * referral_percent2 / fmk;
        uint256 assets_to_trans3 = (_tokens_to_issue*_issue_price/fmk) * referral_percent3 / fmk;
        uint256 assets_to_trans4 = (_tokens_to_issue*_issue_price/fmk) * referral_percent4 / fmk;
        uint256 assets_to_trans5 = (_tokens_to_issue*_issue_price/fmk) * referral_percent5 / fmk;
        if (assets_to_trans1 + assets_to_trans2 + assets_to_trans3 + assets_to_trans4 + assets_to_trans5 == 0) return 0;
        uint256 assets_to_trans = 0;
        
        if (assets_to_trans1 > 0) {
            referral_balance[partner1] = referral_balance[partner1] + assets_to_trans1;
            assets_to_trans = assets_to_trans + assets_to_trans1;
        }
        address partner2 = partners[partner1];
        if ( partner2 != address(0) ) {
            if (assets_to_trans2 > 0) {
                referral_balance[partner2] = referral_balance[partner2] + assets_to_trans2;
                assets_to_trans = assets_to_trans + assets_to_trans2;
            }
            address partner3 = partners[partner2];
            if ( partner3 != address(0) ) {
                if (assets_to_trans3 > 0) {
                    referral_balance[partner3] = referral_balance[partner3] + assets_to_trans3;
                    assets_to_trans = assets_to_trans + assets_to_trans3;
                }
                address partner4 = partners[partner3];
                if ( partner4 != address(0) ) {
                    if (assets_to_trans4 > 0) {
                        referral_balance[partner4] = referral_balance[partner4] + assets_to_trans4;
                        assets_to_trans = assets_to_trans + assets_to_trans4;
                    }
                    address partner5 = partners[partner4];
                    if ( partner5 != address(0) ) {
                        if (assets_to_trans5 > 0) {
                            referral_balance[partner5] = referral_balance[partner5] + assets_to_trans5;
                            assets_to_trans = assets_to_trans + assets_to_trans5;
                        }
                    }
                }
            }
        }
        return assets_to_trans;
    }
    
    function setReferralPercent(uint256 _referral_percent1,uint256 _referral_percent2,uint256 _referral_percent3,uint256 _referral_percent4,uint256 _referral_percent5) public onlyOwner() {
		referral_percent1 = _referral_percent1;
		referral_percent2 = _referral_percent2;
		referral_percent3 = _referral_percent3;
		referral_percent4 = _referral_percent4;
		referral_percent5 = _referral_percent5;
	}
    
    function setTokenAddress(address _token_address) public onlyOwner {
	    baex = payable(_token_address);
	}
	
	/**
    * @dev If the referral partner sends any amount of ETH to the contract, he/she will receive ETH back
	* @dev and receive earned balance of USDT or DAI in the BAEX referral program.
    * @dev Read more about referral program at https://baex.com/#referral
    */
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
	    
	    if (referral_balance[msg.sender]>0) {
	        uint256 ref_eth_to_trans = referral_balance[msg.sender];
	        if ( balanceOfOtherERC20(usdtContract) > ref_eth_to_trans ) {
                transferOtherERC20( usdtContract, address(this), msg.sender, ref_eth_to_trans );
                referral_balance[msg.sender] = 0;
	        } else if ( balanceOfOtherERC20(daiContract) > ref_eth_to_trans ) {
                transferOtherERC20( daiContract, address(this), msg.sender, ref_eth_to_trans );
                referral_balance[msg.sender] = 0;
            }
	    }
	}
	/*------------------*/
	
	/**
    * @dev This function can transfer any of the wrongs sent ERC20 tokens to the contract
	*/
	function transferWrongSendedERC20FromContract(address _contract) public {
	    require( _contract != address(this) && _contract != address(daiContract) && _contract != address(usdtContract), "BAEXReferral: Transfer of BAEX token is forbiden");
	    require( msg.sender == super_owner, "Your are not super owner");
	    IERC20(_contract).transfer( super_owner, IERC20(_contract).balanceOf(address(this)) );
	}
}
/* END of: BAEXReferral - referral program smart-contract */

// SPDX-License-Identifier: UNLICENSED
