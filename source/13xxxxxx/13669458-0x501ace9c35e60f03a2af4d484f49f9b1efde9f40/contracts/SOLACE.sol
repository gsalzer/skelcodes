// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./Governable.sol";
import "./interface/ISOLACE.sol";

/**
 * @title Solace Token (SOLACE)
 * @author solace.fi
 * @notice **Solace** tokens can be earned by depositing **Capital Provider** or **Liquidity Provider** tokens to the [`Master`](./Master) contract.
 * **SOLACE** can also be locked for a preset time in the `Locker` contract to recieve `veSOLACE` tokens.
 */
contract SOLACE is ISOLACE, ERC20Permit, Governable {
    using SafeERC20 for IERC20;
    using Address for address;

    // Minters
    mapping (address => bool) internal _minters;

    /**
     * @notice Constructs the Solace Token contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) ERC20("solace", "SOLACE") ERC20Permit("solace") Governable(governance_) { }

    /**
     * @notice Returns true if `account` is authorized to mint **SOLACE**.
     * @param account Account to query.
     * @return status True if `account` can mint, false otherwise.
     */
    function isMinter(address account) external view override returns (bool status) {
        return _minters[account];
    }

    /**
     * @notice Mints new **SOLACE** to the receiver account.
     * Can only be called by authorized minters.
     * @param account The receiver of new tokens.
     * @param amount The number of new tokens.
     */
    function mint(address account, uint256 amount) external override {
        // can only be called by authorized minters
        require(_minters[msg.sender], "!minter");
        // mint
        _mint(account, amount);
    }

    /**
     * @notice Burns **SOLACE** from msg.sender.
     * @param amount Amount to burn.
     */
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Adds a new minter.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param minter The new minter.
     */
    function addMinter(address minter) external onlyGovernance override {
        require(minter != address(0x0), "zero address");
        _minters[minter] = true;
        emit MinterAdded(minter);
    }

    /**
     * @notice Removes a minter.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param minter The minter to remove.
     */
    function removeMinter(address minter) external onlyGovernance override {
        _minters[minter] = false;
        emit MinterRemoved(minter);
    }
}

