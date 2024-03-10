// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

/// @title BaseTemplate
/// @author Stephane Gosselin (@thegostep)
contract BaseTemplate {
	/// @notice Modifier which only allows to be `DELEGATECALL`ed from within a constructor on initialization of the contract.
	modifier initializeTemplate() {
		// only allow function to be `DELEGATECALL`ed from within a constructor.
		uint32 codeSize;
		assembly {
			codeSize := extcodesize(address())
		}
		require(codeSize == 0, "must be called within contract constructor");
		_;
	}
}

