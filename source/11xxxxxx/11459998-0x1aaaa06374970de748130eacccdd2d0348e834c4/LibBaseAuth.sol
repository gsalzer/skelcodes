// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import "LibRoles.sol";
import "LibIERC20.sol";


/**
 * @dev Base auth.
 */
contract BaseAuth {
    using Roles for Roles.Role;

    Roles.Role private _agents;

    event AgentAdded(address indexed account);
    event AgentRemoved(address indexed account);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()
    {
        _agents.add(msg.sender);
        emit AgentAdded(msg.sender);
    }

    /**
     * @dev Throws if called by account which is not an agent.
     */
    modifier onlyAgent() {
        require(isAgent(msg.sender), "AgentRole: caller does not have the Agent role");
        _;
    }

    /**
     * @dev Rescue compatible ERC20 Token
     *
     * Can only be called by an agent.
     */
    function rescueToken(
        address tokenAddr,
        address recipient,
        uint256 amount
    )
        external
        onlyAgent
    {
        IERC20 _token = IERC20(tokenAddr);
        require(recipient != address(0), "Rescue: recipient is the zero address");
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount, "Rescue: amount exceeds balance");
        _token.transfer(recipient, amount);
    }

    /**
     * @dev Withdraw Ether
     *
     * Can only be called by an agent.
     */
    function withdrawEther(
        address payable recipient,
        uint256 amount
    )
        external
        onlyAgent
    {
        require(recipient != address(0), "Withdraw: recipient is the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "Withdraw: amount exceeds balance");
        recipient.transfer(amount);
    }

    /**
     * @dev Returns true if the `account` has the Agent role.
     */
    function isAgent(address account)
        public
        view
        returns (bool)
    {
        return _agents.has(account);
    }

    /**
     * @dev Give an `account` access to the Agent role.
     *
     * Can only be called by an agent.
     */
    function addAgent(address account)
        public
        onlyAgent
    {
        _agents.add(account);
        emit AgentAdded(account);
    }

    /**
     * @dev Remove an `account` access from the Agent role.
     *
     * Can only be called by an agent.
     */
    function removeAgent(address account)
        public
        onlyAgent
    {
        _agents.remove(account);
        emit AgentRemoved(account);
    }
}


