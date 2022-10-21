// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./safemath.sol";
import "./erc20.sol";

interface Comp {
    function mint ( uint mintAmount ) external returns ( uint );
    function redeem(uint redeemTokens) external returns (uint);
    function exchangeRateStored() external view returns (uint);
}
interface Ful {
    function mint(address receiver, uint amount) external payable returns (uint mintAmount);
    function burn(address receiver, uint burnAmount) external returns (uint loanAmountPaid);
    function assetBalanceOf(address _owner) external view returns (uint balance);
}

interface Yfi {
	function deposit(uint _amount) external;
	function withdraw(uint _token) external;
	function getPricePerFullShare() external view returns (uint);
}
interface Aave {
    function deposit(address _reserve, uint _amount, uint16 _referralCode) external;
}
interface AToken {
    function redeem(uint amount) external;
}
interface LendingGateway {
    function getLendingPool() external view returns (address);
}
interface Mfinance {
    function getReferral(address _addr) external view returns(address);
    function setReferral(address _addr,address _referral) external returns(bool);
	function setExp(address _addr, uint _newExp) external;
	function referralOf(address _addr) external view returns(address);
	function getRefPool() external view returns(address);
	function getPrice() external view returns(uint);
}

interface Mfi {
   function cap() external view returns (uint);
   function mint(address account, uint amount) external;
}


abstract contract Lender{
	using SafeMath for uint;
	address internal btoken;
	address internal yfi;
	address internal comp;
	address internal aave;
	address internal ful;
	address internal aaveToken;
	uint private dToken;
	constructor () public {
		dToken = 3;
	}

	function _yfiBal() internal view returns (uint) {
		return IERC20(yfi).balanceOf(address(this));
	}
	function _yfiValue() internal view returns (uint) {
		uint b = _yfiBal();
		if (b > 0) {
		  b = b.mul(Yfi(yfi).getPricePerFullShare()).div(1e18);
		}
		return b;
	}
	function _yfiSup(uint _amt) internal {
		Yfi(yfi).deposit(_amt);
	}
	function _yfiWd(uint _amt) internal {
		Yfi(yfi).withdraw(_amt);
	}
	function _yfiWithdraw(uint _amt) internal {
		uint b = _yfiBal();
		uint bT = _yfiValue();
		require(bT >= _amt, "insufficient funds");
		uint amt = (b.mul(_amt)).div(bT).add(1);
		_yfiWd(amt);
	  }

	function _compBalance() internal view returns (uint) {
	  return IERC20(comp).balanceOf(address(this));
	}
	
	function _compVal() internal view returns (uint) {
		uint b = _compBalance();
		if (b > 0) {
			b = b.mul(Comp(comp).exchangeRateStored()).div(1e18);
		}
		return b;
	}
	function _compSup(uint _amt) internal {
		require(Comp(comp).mint(_amt) == 0, "Comp: supply failed");
	}
	function _compWd(uint _amt) internal {
		require(Comp(comp).redeem(_amt) == 0, "Comp: wd failed");
	}
	function _compWithdraw(uint _amt) internal {
		uint b = _compBalance();
		uint bT = _compVal();
		require(bT >= _amt, "insufficient funds");
		uint amt = (b.mul(_amt)).div(bT).add(1);
		_compWd(amt);
	  }

	function _fulBal() internal view returns (uint) {
		return IERC20(ful).balanceOf(address(this));
	}
	function _fulVal() internal view returns (uint) {
		uint b = _fulBal();
		if (b > 0) {
		  b = Ful(ful).assetBalanceOf(address(this));
		}
		return b;
	}
	function _fulSup(uint _amt) internal {
		require(Ful(ful).mint(address(this), _amt) > 0, "Ful: supply failed");
	}
	function _fulWd(uint _amt) internal {
		require(Ful(ful).burn(address(this), _amt) > 0, "Ful: wd failed");
	}
	function _fulWithdraw(uint _amt) internal {
		uint b = _fulBal();
		uint bT = _fulVal();
		require(bT >= _amt, "insufficient funds");
		uint amt = (b.mul(_amt)).div(bT).add(1);
		_fulWd(amt);
	}

	function getAave() private view returns (address) {
		return LendingGateway(aave).getLendingPool();
	}
	function _aaveBalVal() internal view returns (uint) {
		return IERC20(aaveToken).balanceOf(address(this));
	}
	function _aavSup(uint _amt) internal {
		Aave(getAave()).deposit(btoken, _amt, 0);
	}
	function _aaveWd(uint _amt) internal {
		AToken(aaveToken).redeem(_amt);
	}

}
