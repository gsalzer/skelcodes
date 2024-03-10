pragma solidity ^0.5.0;

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
contract Context {
	// Empty internal constructor, to prevent people from mistakenly deploying
	// an instance of this contract, which should be used via inheritance.
	constructor () internal { }
	// solhint-disable-previous-line no-empty-blocks

    /**
     * @dev return msg.sender
     * @return msg.sender
     */
	function _msgSender()
        internal
        view
        returns (address payable)
    {
		return msg.sender;
	}

    /**
     * @dev return msg.value
     * @return msg.value
     */
	function _msgValue()
        internal
        view
        returns (uint)
    {
		return msg.value;
	}

    /**
     * @dev return tx.origin
     * @return tx.origin
     */
	function _txOrigin()
        internal
        view
        returns (address)
    {
		return tx.origin;
	}
}
