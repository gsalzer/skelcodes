// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./matic/IRootChainManager.sol";

/// @title PolygonCommunityVault
/// @author Alex T
/// @notice Assists with moving a specified token from the root chain to the child chain. Made for Polygon
/// @dev It needs to be deployed at the same address on both chains. Uses CREATE2 on deploy to achieve that
contract PolygonCommunityVault is OwnableUpgradeable {
    IRootChainManager internal rootChainManager;
    address internal erc20Predicate;

    address public token;

    /// @notice Notifies of allowance being set
    /// @dev Emitted when setAlowance is called
    /// @param caller Address that called setAllowance
    /// @param spender Address that the allowance has been set for
    /// @param amount The amount of tokens that spender can spend
    event SetAllowance(address indexed caller, address indexed spender, uint256 amount);
    
    /// @notice Notifies of a transfer to the child chain being made
    /// @dev Emitted when transferToChild is called
    /// @param caller Address that called transferToChild
    /// @param token Address of the transferred token
    /// @param amount The amount of tokens that were sent to the child chain
    event TransferToChild(address indexed caller, address indexed token,  uint256 amount);

    /// @notice PolygonCommunityVault initializer
    /// @dev Needs to be called after deployment. Get addresses from https://github.com/maticnetwork/static/tree/master/network
    /// @param _token The address of the ERC20 that the vault will manipulate/own
    /// @param _rootChainManager Polygon root network chain manager. Zero address for child deployment
    /// @param _erc20Predicate Polygon ERC20 Predicate. Zero address for child deployment
    function initialize(address _token, address _rootChainManager, address _erc20Predicate) public initializer {
        require(_token != address(0), "Vault: a valid token address must be provided");

        __Ownable_init();

        token = _token;

        if (_rootChainManager != address(0)) {
            require(_erc20Predicate != address(0), "Vault: erc20Predicate must not be 0x0");

            erc20Predicate = _erc20Predicate;
            rootChainManager = IRootChainManager(_rootChainManager);
        }
    }

    /// @notice Sets Allowance for specified contract for the managed token
    /// @dev Emits SetAllowance on allowance being successfully set
    /// @param _spender Address that is allowed to spend the funds
    /// @param _amount How much cand the address spend
    function setAllowance(address _spender, uint256 _amount) public onlyOwner {
        IERC20(token).approve(_spender, _amount);

        emit SetAllowance(msg.sender, _spender, _amount);
    }

    /// @notice Transfers full balance of managed token through the Polygon Bridge
    /// @dev Emits TransferToChild on funds being sucessfuly deposited
    function transferToChild() public { // onlyOnRoot , maybe onlyOwner
        require(erc20Predicate != address(0), "Vault: transfer to child chain is disabled");

        IERC20 erc20 = IERC20(token);

        uint256 amount = erc20.balanceOf(address(this));
        erc20.approve(erc20Predicate, amount);
        rootChainManager.depositFor(address(this), token, abi.encode(amount));

        emit TransferToChild(msg.sender, token, amount);
    }

}

