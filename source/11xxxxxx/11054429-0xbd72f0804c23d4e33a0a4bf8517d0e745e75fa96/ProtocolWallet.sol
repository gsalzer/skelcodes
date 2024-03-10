// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./IProtocolWallet.sol";
import "./WithClaimableMigrationOwnership.sol";
import "./WithClaimableFunctionalOwnership.sol";

contract ProtocolWallet is IProtocolWallet, WithClaimableMigrationOwnership, WithClaimableFunctionalOwnership {
    using SafeMath for uint256;

    IERC20 public token;
    address public client;
    uint256 public lastWithdrawal;
    uint256 maxAnnualRate;

    constructor(IERC20 _token, address _client, uint256 _maxAnnualRate) public {
        token = _token;
        client = _client;
        lastWithdrawal = now;

        setMaxAnnualRate(_maxAnnualRate);
    }

    modifier onlyClient() {
        require(msg.sender == client, "caller is not the wallet client");

        _;
    }

    /*
    * External functions
    */

    /// @dev Returns the address of the underlying staked token.
    /// @return balance IERC20 The address of the token.
    function getBalance() public override view returns (uint256 balance) {
        return token.balanceOf(address(this));
    }

    /// @dev Transfers the given amount of orbs tokens form the sender to this contract an update the pool.
    function topUp(uint256 amount) external override {
        emit FundsAddedToPool(amount, getBalance() + amount);
        require(token.transferFrom(msg.sender, address(this), amount), "ProtocolWallet::topUp - insufficient allowance");
    }

    /// @dev withdraws from the pool to a spender, limited by the pool's MaxRate.
    /// A maximum of MaxRate x time period since the last Orbs transfer may be transferred out.
    function withdraw(uint256 amount) external override onlyClient {
        uint duration = now - lastWithdrawal;
        uint maxAmount = duration.mul(maxAnnualRate).div(365 * 24 * 60 * 60);
        require(amount <= maxAmount, "ProtocolWallet::withdraw - requested amount is larger than allowed by rate");

        lastWithdrawal = now;
        if (amount > 0) {
            require(token.transfer(msg.sender, amount), "ProtocolWallet::withdraw - transfer failed");
        }
    }

    /*
    * Governance functions
    */

    /// @dev Sets a new transfer rate for the Orbs pool.
    function setMaxAnnualRate(uint256 _annualRate) public override onlyMigrationOwner {
        maxAnnualRate = _annualRate;
        emit MaxAnnualRateSet(_annualRate);
    }

    function getMaxAnnualRate() external override view returns (uint256) {
        return maxAnnualRate;
    }

    /// @dev Sets a new transfer rate for the Orbs pool.
    function resetOutstandingTokens(uint256 startTime) external override onlyMigrationOwner { //TODO add test
        lastWithdrawal = startTime;
        emit OutstandingTokensReset(startTime);
    }

    /// @dev transfer the entire pool's balance to a new wallet.
    function emergencyWithdraw() external override onlyMigrationOwner {
        emit EmergencyWithdrawal(msg.sender);
        require(token.transfer(msg.sender, getBalance()), "ProtocolWallet::emergencyWithdraw - transfer failed");
    }

    /// @dev sets the address of the new contract
    function setClient(address _client) external override onlyFunctionalOwner {
        client = _client;
        emit ClientSet(_client);
    }
}

