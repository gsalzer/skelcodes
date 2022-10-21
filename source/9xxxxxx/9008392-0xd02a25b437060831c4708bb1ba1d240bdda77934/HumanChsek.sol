pragma solidity ^0.5.11;

import './Context.sol';

/**
 * @title HumanChsek
 * @dev This Provide check address is contract
 */
contract HumanChsek is Context {

    /**
     * @dev modifier to scope access to a Contract (uses tx.origin and msg.sender)
     */
	modifier isHuman() {
		require(_msgSender() == _txOrigin(), "HumanChsek: sorry, humans only");
		_;
	}

}

