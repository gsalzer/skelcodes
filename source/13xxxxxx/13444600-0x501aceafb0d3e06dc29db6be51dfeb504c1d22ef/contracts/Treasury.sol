// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Governable.sol";
import "./interface/IWETH9.sol";
import "./interface/IRegistry.sol";
import "./interface/IPolicyManager.sol";
import "./interface/ITreasury.sol";
import "./interface/IVault.sol";


/**
 * @title Treasury
 * @author solace.fi
 * @notice The war chest of Castle Solace.
 *
 * As policies are purchased, premiums will flow from [**policyholders**](/docs/protocol/policy-holder) to the `Treasury`. By default `Treasury` reroutes 100% of the premiums into the [`Vault`](./Vault) where it is split amongst the [**capital providers**](/docs/user-guides/capital-provider/cp-role-guide).
 *
 * If a [**policyholder**](/docs/protocol/policy-holder) updates or cancels a policy they may receive a refund. Refunds will be paid out from the [`Vault`](./Vault). If there are not enough funds to pay out the refund in whole, the [`unpaidRefunds()`](#unpaidrefunds) will be tracked and can be retrieved later via [`withdraw()`](#withdraw).
 *
 * [**Governance**](/docs/protocol/governance) can change the premium recipients via [`setPremiumRecipients()`](#setpremiumrecipients). This can be used to add new building blocks to Castle Solace or enact a protocol fee. Premiums can be stored in the `Treasury` and managed with a number of functions.
 */
contract Treasury is ITreasury, ReentrancyGuard, Governable {
    using Address for address;
    using SafeERC20 for IERC20;

    // Registry
    IRegistry internal _registry;

    // Wrapped ether.
    IWETH9 internal _weth;

    address internal constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address payable[] internal _premiumRecipients;
    uint32[] internal _recipientWeights;
    uint32 internal _weightSum;

    // The amount of **ETH** that a user is owed if any.
    mapping(address => uint256) internal _unpaidRefunds;

    /**
     * @notice Constructs the Treasury contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ Address of registry.
     */
    constructor(address governance_, address registry_) Governable(governance_) {
        // set registry
        require(registry_ != address(0x0), "zero address registry");
        _registry = IRegistry(registry_);
        // set weth
        address weth_ = _registry.weth();
        require(weth_ != address(0x0), "zero address weth");
        _weth = IWETH9(payable(weth_));
        // if vault is deployed, route 100% of the premiums to it
        address vault_ = _registry.vault();
        if (vault_ != address(0x0)) {
            _premiumRecipients = [payable(vault_)];
            _recipientWeights = [1,0];
            _weightSum = 1;
        } // if vault is not deployed, hold 100% of the premiums in the treasury
    }

    /***************************************
    FUNDS IN
    ***************************************/

    /**
     * @notice Routes the **premiums** to the `recipients`.
     * Each recipient will receive a `recipientWeight / weightSum` portion of the premiums.
     * Will be called by products with `msg.value = premium`.
     */
    function routePremiums() external payable override nonReentrant {
        // preload variables
        uint256 div = _weightSum;
        uint256 length = _premiumRecipients.length;
        // transfer to all recipients
        for(uint i = 0; i < length; i++) {
            uint256 amount = msg.value * _recipientWeights[i] / div;
            if (amount > 0) {
                // this call may fail. let it
                // funds will be safely stored in treasury
                _premiumRecipients[i].call{value: amount, gas: 100000}(""); // IGNORE THIS WARNING
            }
        }
        // hold treasury share as eth
        emit PremiumsRouted(msg.value);
    }

    /**
     * @notice Number of premium recipients.
     * @return count The number of premium recipients.
     */
    function numPremiumRecipients() external view override returns (uint256 count) {
        return _premiumRecipients.length;
    }

    /**
     * @notice Gets the premium recipient at `index`.
     * @param index Index to query, enumerable `[0, numPremiumRecipients()-1]`.
     * @return recipient The receipient address.
     */
    function premiumRecipient(uint256 index) external view override returns (address recipient) {
        return _premiumRecipients[index];
    }

    /**
     * @notice Gets the weight of the recipient.
     * @param index Index to query, enumerable `[0, numPremiumRecipients()]`.
     * @return weight The recipient weight.
     */
    function recipientWeight(uint256 index) external view override returns (uint32 weight) {
        return _recipientWeights[index];
    }

    /**
     * @notice Gets the sum of all premium recipient weights.
     * @return weight The sum of weights.
     */
    function weightSum() external view override returns (uint32 weight) {
        return _weightSum;
    }

    /***************************************
    FUNDS OUT
    ***************************************/

    /**
     * @notice Refunds some **ETH** to the user.
     * Will attempt to send the entire `amount` to the `user`.
     * If there is not enough available at the moment, it is recorded and can be pulled later via [`withdraw()`](#withdraw).
     * Can only be called by active products.
     * @param user The user address to send refund amount.
     * @param amount The amount to send the user.
     */
    function refund(address user, uint256 amount) external override nonReentrant {
        // check if from active product
        require(IPolicyManager(_registry.policyManager()).productIsActive(msg.sender), "!product");
        _transferEth(user, amount);
    }

    /**
     * @notice The amount of **ETH** that a user is owed if any.
     * @param user The user.
     * @return amount The amount.
     */
    function unpaidRefunds(address user) external view override returns (uint256 amount) {
        return _unpaidRefunds[user];
    }

    /**
     * @notice Transfers the unpaid refunds to the user.
     */
    function withdraw() external override nonReentrant {
        _transferEth(msg.sender, 0);
    }

    /**
     * @notice Transfers **ETH** to the user. It's called by [`refund()`](#refund) and [`withdraw()`](#withdraw) functions in the contract.
     * Also adds on their unpaid refunds, and stores new unpaid refunds if necessary.
     * @param user The user to pay.
     * @param amount The amount to pay _before_ unpaid funds.
     */
    function _transferEth(address user, uint256 amount) internal {
        require(user != address(0x0), "zero address recipient");
        // account for unpaid rewards
        uint256 unpaidRefunds1 = _unpaidRefunds[user];
        amount += unpaidRefunds1;
        if(amount == 0) return;
        // transfer amount from vault
        if (_registry.vault() != address(0)) IVault(payable(_registry.vault())).requestEth(amount);
        // unwrap weth if necessary
        if(address(this).balance < amount) {
            uint256 diff = amount - address(this).balance;
            _weth.withdraw(Math.min(_weth.balanceOf(address(this)), diff));
        }
        // send eth
        uint256 transferAmount = Math.min(address(this).balance, amount);
        uint256 unpaidRefunds2 = amount - transferAmount;
        if(unpaidRefunds2 != unpaidRefunds1) _unpaidRefunds[user] = unpaidRefunds2;
        Address.sendValue(payable(user), transferAmount);
        emit EthRefunded(user, transferAmount);
    }

    /***************************************
    FUND MANAGEMENT
    ***************************************/

    /**
     * @notice Sets the premium recipients and their weights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param recipients The premium recipients, plus an implicit `address(treasury)` at the end.
     * @param weights The recipient weights.
     */
    function setPremiumRecipients(address payable[] calldata recipients, uint32[] calldata weights) external override onlyGovernance {
        // check recipient - weight map
        require(recipients.length + 1 == weights.length, "length mismatch");
        uint256 length = weights.length;
        require(length <= 16, "too many recipients");
        uint32 sum = 0;
        for(uint256 i = 0; i < length; i++) sum += weights[i];
        if(length > 1) require(sum > 0, "1/0");
        // delete old recipients
        delete _premiumRecipients;
        delete _recipientWeights;
        // set new recipients
        _weightSum = sum;
        _premiumRecipients = recipients;
        _recipientWeights = weights;
        emit RecipientsSet();
    }

    /**
     * @notice Spends an **ERC20** token or **ETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param token The address of the token to spend.
     * @param amount The amount of the token to spend.
     * @param recipient The address of the token receiver.
     */
    function spend(address token, uint256 amount, address recipient) external override nonReentrant onlyGovernance {
        require(token != address(0x0), "zero address token");
        require(recipient != address(0x0), "zero address recipient");
        // transfer eth
        if(token == _ETH_ADDRESS) Address.sendValue(payable(recipient), amount);
        // transfer token
        else IERC20(token).safeTransfer(recipient, amount);
        // emit event
        emit FundsSpent(token, amount, recipient);
    }

    /**
     * @notice Wraps some **ETH** into **WETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount The amount to wrap.
     */
    function wrap(uint256 amount) external override onlyGovernance {
        _weth.deposit{value: amount}();
    }

    /**
     * @notice Unwraps some **WETH** into **ETH**.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param amount The amount to unwrap.
     */
    function unwrap(uint256 amount) external override onlyGovernance {
        _weth.withdraw(amount);
    }

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    receive () external payable override { }

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    fallback () external payable override { }
}

