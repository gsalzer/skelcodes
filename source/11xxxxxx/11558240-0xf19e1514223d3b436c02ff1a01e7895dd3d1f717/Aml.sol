// SPDX-License-Identifier: MIT
// Using: https://github.com/ethereum/EIPs/issues/1404

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

abstract contract Aml is ERC20, Ownable {

	mapping (address => bool) private _aml;

	event WhitelistedAddressAdded(address addr);

	event WhitelistedAddressRemoved(address addr);

	/**
	 * Checks that _to has aml record
	 */
	modifier notRestricted (address _to) {
		require(_aml[_to], "AML/KYC procedure required for this address");
		_;
	}

	function amlApprove(address _wallet)
	    public
	    onlyManager
	{
		if (!_aml[_wallet]) {
			_aml[_wallet] = true;
			WhitelistedAddressAdded(_wallet);
		}
	}

	function amlDecline(address _wallet)
	    public
	    onlyManager
	{
    	if (_aml[_wallet]) {
    		_aml[_wallet] = false;
    		WhitelistedAddressRemoved(_wallet);
    	}
    }

    function isAmlApproved()
        public
        view
        returns (bool)
    {
		return _aml[msg.sender];
    }
}
