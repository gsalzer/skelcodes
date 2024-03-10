// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LiquidityNexusBase is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public governance;

    constructor() {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "only governance");
        _;
    }

    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "null governance");
        governance = _governance;
    }

    /**
     * Only the owner is supposed to deposit USDC into this contract.
     */
    function depositCapital(uint256 amount) public onlyOwner {
        if (amount > 0) {
            IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function depositAllCapital() external onlyOwner {
        depositCapital(IERC20(USDC).balanceOf(msg.sender));
    }

    /**
     * The owner can withdraw the unused USDC capital that they had deposited earlier.
     */
    function withdrawFreeCapital() public onlyOwner {
        uint256 balance = IERC20(USDC).balanceOf(address(this));
        if (balance > 0) {
            IERC20(USDC).safeTransfer(msg.sender, balance);
        }
    }

    /**
     * Pause will only prevent new ETH deposits (addLiquidity). Existing depositors will still
     * be able to removeLiquidity even when paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Owner can only salvage unrelated tokens that were sent by mistake.
     */
    function salvage(address[] memory tokens_) external onlyOwner {
        for (uint256 i = 0; i < tokens_.length; i++) {
            address token = tokens_[i];
            require(isSalvagable(token), "not salvagable");
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).safeTransfer(msg.sender, balance);
            }
        }
    }

    function isSalvagable(address token) internal virtual returns (bool) {
        return token != WETH && token != USDC;
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks
}

