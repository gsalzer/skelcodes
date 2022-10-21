// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./matic/IRootChainManager.sol";
import "./matic/IERC20ChildToken.sol";

/// @title PolygonTokenHarvester
/// @author Alex T
/// @notice Assists with moving any given token from the child chain to the root chain. Made for Polygon
/// @dev It needs to be deployed at the same address on both chains. Uses CREATE2 on deploy to achieve that
contract PolygonTokenHarvester is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    bool private _onRootChain;

    address public rootChainManager;
    mapping(address => uint256) public lastWithdraw;
    uint256 public withdrawCooldown;

    /// @notice Logs a transfer of tokens to owner
    /// @dev Emitted when transferToOwner is called
    /// @param caller Address that called transferToOwner
    /// @param owner Address that the funds have been transferred to
    /// @param token Address of the transferred token
    /// @param amount The amount of tokens that were sent to the child chain
    event TransferToOwner(address indexed caller, address indexed owner, address indexed token, uint256 amount);

    /// @notice Logs a withdrawal being made on the root chain
    /// @dev Emitted when withdrawOnRoot is called
    /// @param caller Address that called withdrawOnRoot
    event WithdrawOnRoot(address indexed caller);

    /// @notice Logs withdrawal being made on the child chain
    /// @dev Emitted when withdrawOnChild is called
    /// @param caller Address that called withdrawOnChild
    /// @param token Address of the withdrawn token
    /// @param amount The amount of tokens that were withdrawn
    event WithdrawOnChild(address indexed caller, address indexed token, uint256 amount);

    /// @notice PolygonTokenHarvester initializer
    /// @dev Needs to be called after deployment. Get addresses from https://github.com/maticnetwork/static/tree/master/network
    /// @param _withdrawCooldown Number of blocks needed between withdrawals
    /// @param _rootChainManager Address of Polygon rootChainManager. Set to zero address on child chain
    function initialize(uint256 _withdrawCooldown, address _rootChainManager) public initializer {
        __Ownable_init();

        if (_rootChainManager != address(0)) {
            _onRootChain = true;
            rootChainManager = _rootChainManager;
        } else {
            _onRootChain = false;
        }

        withdrawCooldown = _withdrawCooldown;
     }

    /// @notice Allows the call only on the root chain
    /// @dev Checks is based on rootChainManager being set
    modifier onlyOnRoot {
        require(
            _onRootChain == true,
            "Harvester: should only be called on root chain"
        );
        _;
    }

    /// @notice Allows the call only on the child chain
    /// @dev Checks is based on rootChainManager being not set
    modifier onlyOnChild {
        require(
            _onRootChain == false,
            "Harvester: should only be called on child chain"
        );
        _;
    }

    /// @notice Sets the minimum number of blocks that must pass between withdrawals
    /// @dev This limit is set to not spam the withdrawal process with lots of small withdrawals
    /// @param _withdrawCooldown Number of blocks needed between withdrawals
    function setWithdrawCooldown(uint256 _withdrawCooldown) public onlyOwner onlyOnChild {
        withdrawCooldown = _withdrawCooldown;
    }

    // Root Chain Related Functions

    /// @notice Withdraws to itself exited funds from Polygon
    /// @dev Forwards the exit call to the Polygon rootChainManager
    /// @param _data Exit payload created with the Matic SDK
    /// @return Bytes return of the rootChainManager exit call
    function withdrawOnRoot(bytes memory _data) public onlyOnRoot returns (bytes memory) {
        emit WithdrawOnRoot(_msgSender());
        (bool success, bytes memory returnData) = rootChainManager.call(_data);
        require(success, string(returnData));

        return returnData;
    }

    /// @notice Transfers full balance of token to owner
    /// @dev Use this after withdrawOnRoot to transfer what you have exited from Polygon to owner
    /// @param _token Address of token to transfer
    function transferToOwner(address _token) public onlyOnRoot {
        require(_token != address(0), "Harvester: token address must be specified");

        IERC20 erc20 = IERC20(_token);

        address to = owner();

        uint256 amount = erc20.balanceOf(address(this));

        emit TransferToOwner(_msgSender(), to, _token, amount);
        erc20.safeTransfer(to, amount);
    }

    /// @notice Exit funds from polygon and transfer to owner
    /// @dev Calls withdrawOnRoot then transferToOwner
    /// @param _data Exit payload created with the Matic SDK
    /// @param _token Address of token to transfer
    function withdrawAndTransferToOwner(bytes memory _data, address _token) public onlyOnRoot returns (bytes memory) {
        bytes memory returnData =  withdrawOnRoot(_data);
        transferToOwner(_token);

        return returnData;
    }

    // Child Chain Related Functions

    /// @notice Withdraws full token balance from the child chain
    /// @dev Emits WithdrawOnChild on succesful withdraw and burn
    /// @param _childToken Address of token to withdraw
    function withdrawOnChild(address _childToken) public onlyOnChild {
        require(_childToken != address(0), "Harvester: child token address must be specified");

        // if cooldown has not passed, we just skip it
        if (block.number < lastWithdraw[_childToken] + withdrawCooldown) {
            return;
        }
        lastWithdraw[_childToken] = block.number;

        IERC20ChildToken erc20 = IERC20ChildToken(_childToken);

        uint256 amount = erc20.balanceOf(address(this));

        emit WithdrawOnChild(_msgSender(), _childToken, amount);
        erc20.withdraw(amount);
    }
}

