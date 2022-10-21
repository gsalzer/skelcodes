pragma solidity ^0.5.16;

import "./Proxy.sol";
import "./StorageStateful.sol";

contract Entry is StorageStateful, Proxy {
    bool public isInitialized;

	event UpdateStorage(address indexed admin, address indexed storage_);

	constructor() public {
		Data storage_ = new Data(address(this));
		_installStorage(storage_);
	}

	function _installStorage(Data storage_) internal {
		_storage = storage_;
		emit UpdateStorage(msg.sender, address(storage_));
	}

	function initialize(address logic_) external onlyOwner {
	    require(!isInitialized, "Entry: has already initialized");
	    upgradeTo("0.0.1", logic_);
	    isInitialized = true;
	}
}

