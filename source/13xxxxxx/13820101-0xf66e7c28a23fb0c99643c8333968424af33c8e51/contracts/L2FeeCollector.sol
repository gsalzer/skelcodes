// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC20Token.sol";
import "./IVesperPool.sol";

// Contract to migrate ERC20 asset from polygon to ethereum mainnet.
// This is permissionless contrat. onlyOwner is needed to set fee collector.
contract L2FeeCollector is Context {
    using SafeERC20 for IERC20;

    // With create2, deployer is not owner so need to hard code owner address as Vesper Deployer.    
    address public owner = 0xB5AbDABE50b5193d4dB92a16011792B22bA3Ef51;
    address public feeCollector;

    modifier onlyOwner() {
        require(owner == _msgSender(), "not-owner");
        _;
    }

    constructor() {}

    /**
     * @notice Withdraw full token amount. This function is called on Polygon chain.
     * @param _token ERC20 Token address to withdraw
     */
    function withdraw(address _token) public {
        require(_token != address(0), "_token-is-null");
        uint256 _amount = IERC20Token(_token).balanceOf(address(this));
        IERC20Token(_token).withdraw(_amount);
    }

    /**
     * @notice Withdraw VToken full amount. This function is called on Polygon chain.
     * @param _vToken VesperPool address to unwrap and withdraw
     */
    function unwrapVTokenAndWithdraw(address _vToken) external {
        require(_vToken != address(0), "_vToken-is-null");
        IVesperPool vPool = IVesperPool(_vToken);
        uint256 _vTokenAmount = vPool.balanceOf(address(this));
        if (_vTokenAmount > 0) {
            // unwrap
            vPool.withdraw(_vTokenAmount);
        }
        // Withdraw to send to Polygon Bridge
        withdraw(address(vPool.token()));
    }

    /**
     * @dev Transfer given ERC20 token to feeCollector. This is called on eth chain.
     * @param _fromToken Token address to sweep
     */
    function sweepERC20(address _fromToken) external {
        require(_fromToken != address(0), "invalid-token");
        require(feeCollector != address(0), "fee-collector-not-set");
        uint256 _balance = IERC20(_fromToken).balanceOf(address(this));
        if (_balance > 0) {
            IERC20(_fromToken).safeTransfer(feeCollector, _balance);
        }
    }

    /**
     * @dev Set feeCollector. This is called on eth chain.
     * @param _feeCollector Fee collector address on eth chain
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "zero-fee-collector");
        require(_feeCollector != feeCollector, "fee-collector-not-changed");
        feeCollector = _feeCollector;
    }
}

