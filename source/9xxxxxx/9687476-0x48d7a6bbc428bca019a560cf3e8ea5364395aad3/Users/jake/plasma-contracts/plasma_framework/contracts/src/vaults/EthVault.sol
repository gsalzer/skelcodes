pragma solidity 0.5.11;

import "./Vault.sol";
import "./verifiers/IEthDepositVerifier.sol";
import "../framework/PlasmaFramework.sol";
import "../utils/SafeEthTransfer.sol";

contract EthVault is Vault {
    event EthWithdrawn(
        address indexed receiver,
        uint256 amount
    );

    event WithdrawFailed(
        address indexed receiver,
        uint256 amount
    );

    event DepositCreated(
        address indexed depositor,
        uint256 indexed blknum,
        address indexed token,
        uint256 amount
    );

    uint256 public safeGasStipend;

    constructor(PlasmaFramework _framework, uint256 _safeGasStipend) public Vault(_framework) {
        safeGasStipend = _safeGasStipend;
    }

    /**
     * @notice Allows a user to deposit ETH into the contract
     * Once the deposit is recognized, the owner may transact on the OmiseGO Network
     * @param _depositTx RLP-encoded transaction to act as the deposit
     */
    function deposit(bytes calldata _depositTx) external payable {
        address depositVerifier = super.getEffectiveDepositVerifier();
        require(depositVerifier != address(0), "Deposit verifier has not been set");

        IEthDepositVerifier(depositVerifier).verify(_depositTx, msg.value, msg.sender);
        uint256 blknum = super.submitDepositBlock(_depositTx);

        emit DepositCreated(msg.sender, blknum, address(0), msg.value);
    }

    /**
    * @notice Withdraw ETH that has successfully exited from the OmiseGO Network
    * @dev We do not want to block exit queue if a transfer is unsuccessful, so we don't revert on transfer error.
    *      However, if there is not enough gas left for the safeGasStipend, then the EVM _will_ revert with an 'out of gas' error.
    *      If this happens, the user should retry with higher gas.
    * @param receiver Address of the recipient
    * @param amount The amount of ETH to transfer
    */
    function withdraw(address payable receiver, uint256 amount) external onlyFromNonQuarantinedExitGame {
        bool success = SafeEthTransfer.transferReturnResult(receiver, amount, safeGasStipend);
        if (success) {
            emit EthWithdrawn(receiver, amount);
        } else {
            emit WithdrawFailed(receiver, amount);
        }
    }
}

