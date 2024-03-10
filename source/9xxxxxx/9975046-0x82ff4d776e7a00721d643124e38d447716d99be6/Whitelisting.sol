pragma solidity ^0.5.4;

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

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// Copyright (C) 2020 LimeChain - Blockchain & DLT Solutions <https://limechain.tech>



/**
 * @title Operator
 * @dev Simple ownable Operator contract that stores operators.
 */
contract Operator is Ownable {
    // The operators storage
    mapping(address => bool) private operators;

    event OperatorModified(
        address indexed executor,
        address indexed operator,
        bool status
    );

    /**
     * @dev Enables/Disables an operator.
     * @param _operator The target operator.
     * @param _status Set to true to enable an operator.
     */
    function setOperator(address _operator, bool _status) public onlyOwner {
        require(
            _operator != address(0),
            "Operator: operator is the zero address"
        );
        operators[_operator] = _status;
        emit OperatorModified(msg.sender, _operator, _status);
    }

    /**
     * @dev Checks if an operator is enabled/disabled.
     * @param _operator The target operator.
     */
    function isOperator(address _operator) public view returns (bool) {
        return operators[_operator];
    }
}
// Copyright (C) 2020 LimeChain - Blockchain & DLT Solutions <https://limechain.tech>


/**
 * @title Whitelisting
 * @dev Manages whitelisting of accounts (EOA or contracts).
 */
contract Whitelisting is Operator {
    // The whitelisted accounts storage
    mapping(address => bool) private whitelisted;

    event WhitelistedStatusModified(
        address indexed executor,
        address[] user,
        bool status
    );

    /**
     * @dev Throws if the sender is neither operator nor owner.
     */
    modifier onlyAuthorized() {
        require(
            isOperator(msg.sender) || msg.sender == owner(),
            "Whitelisting: the caller is not whitelistOperator or owner"
        );
        _;
    }

    /**
     * @dev Adds/Removes whitelisted accounts.
     * @param _users The target accounts.
     * @param _isWhitelisted Set to true to whitelist accounts.
     */
    function setWhitelisted(address[] memory _users, bool _isWhitelisted)
        public
        onlyAuthorized
    {
        for (uint256 i = 0; i < _users.length; i++) {
            require(
                _users[i] != address(0),
                "Whitelisting: user is the zero address"
            );
            whitelisted[_users[i]] = _isWhitelisted;
        }
        emit WhitelistedStatusModified(msg.sender, _users, _isWhitelisted);
    }

    /**
     * @dev Checks if an account is whitelisted.
     * @param _user The target account.
     */
    function isWhitelisted(address _user) public view returns (bool) {
        return whitelisted[_user];
    }
}

