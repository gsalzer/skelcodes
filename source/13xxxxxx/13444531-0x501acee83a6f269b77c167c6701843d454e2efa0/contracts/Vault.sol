// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Governable.sol";
import "./interface/IRegistry.sol";
import "./interface/IPolicyManager.sol";
import "./interface/IRiskManager.sol";
import "./interface/IVault.sol";

/**
 * @title Vault
 * @author solace.fi
 * @notice The risk-backing capital pool.
 *
 * [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) can deposit **ETH** or **WETH** into the `Vault` to mint shares. Shares are represented as **CP tokens** aka **SCP** and extend `ERC20`. [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) should use [`depositEth()`](#depositeth) or [`depositWeth()`](#depositweth), not regular **ETH** or **WETH** transfer.
 *
 * As [**Policyholders**](/docs/protocol/policy-holder) purchase coverage, premiums will flow into the capital pool and are split amongst the [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide). If a loss event occurs in an active policy, some funds will be used to payout the claim. These events will affect the price per share but not the number or distribution of shares.
 *
 * By minting shares of the `Vault`, [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) willingly accept the risk that the whole or a part of their funds may be used payout claims. A malicious [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) could detect a loss event and try to withdraw their funds before claims are paid out. To prevent this, the `Vault` uses a cooldown mechanic such that while the [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) is not in cooldown mode (default) they can mint, send, and receive **SCP** but not withdraw **ETH**. To withdraw their **ETH**, the [**capital provider**](/docs/user-guides/capital-provider/cp-role-guide) must [`startCooldown()`](#startcooldown), wait no less than [`cooldownMin()`](#cooldownmin) and no more than [`cooldownMax()`](#cooldownmax), then call [`withdrawEth()`](#withdraweth) or [`withdrawWeth()`](#withdrawweth). While in cooldown mode users cannot send or receive **SCP** and minting shares will take them out of cooldown.
 */
contract Vault is ERC20Permit, IVault, ReentrancyGuard, Governable {
    using SafeERC20 for IERC20;
    using Address for address;

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // pauses deposits
    bool internal _paused;

    // WETH
    IWETH9 internal _weth;

    /// Registry of protocol contract addresses
    IRegistry internal _registry;

    // capital providers must wait some time in this range in order to withdraw
    // used to prevent withdraw before claim payout
    /// @notice The minimum amount of time a user must wait to withdraw funds.
    uint40 internal _cooldownMin = 7 days;

    /// @notice The maximum amount of time a user must wait to withdraw funds.
    uint40 internal _cooldownMax = 35 days;

    // The timestamp that a depositor's cooldown started.
    mapping(address => uint40) internal _cooldownStart;

    // Returns true if the destination is authorized to request ETH.
    mapping(address => bool) internal _isRequestor;

    /**
     * Constructs the Vault.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ Address of the [`Registry`](./Registry) contract.
     */
    constructor (address governance_, address registry_) ERC20("Solace CP Token", "SCP") ERC20Permit("Solace CP Token") Governable(governance_) {
        // set registry
        require(registry_ != address(0x0), "zero address registry");
        _registry = IRegistry(registry_);
        // set weth
        address weth_ = _registry.weth();
        require(weth_ != address(0x0), "zero address weth");
        _weth = IWETH9(payable(weth_));
    }

    /***************************************
    CAPITAL PROVIDER FUNCTIONS
    ***************************************/

    /**
     * @notice Allows a user to deposit **ETH** into the `Vault`(becoming a [**Capital Provider**](/docs/user-guides/capital-provider/cp-role-guide)).
     * Shares of the `Vault` (CP tokens) are minted to caller.
     * It is called when `Vault` receives **ETH**.
     * It issues the amount of token share respected to the deposit to the `recipient`.
     * Reverts if `Vault` is paused.
     * @return shares The number of shares minted.
     */
    function depositEth() external payable override nonReentrant returns (uint256 shares) {
        // mint
        return _deposit(msg.value);
    }

    /**
     * @notice Allows a user to deposit **WETH** into the `Vault`(becoming a [**Capital Provider**](/docs/user-guides/capital-provider/cp-role-guide)).
     * Shares of the Vault (CP tokens) are minted to caller.
     * It issues the amount of token share respected to the deposit to the `recipient`.
     * Reverts if `Vault` is in paused.
     * @param amount Amount of weth to deposit.
     * @return shares The number of shares minted.
     */
    function depositWeth(uint256 amount) external override nonReentrant returns (uint256 shares) {
        // pull weth
        SafeERC20.safeTransferFrom(_weth, msg.sender, address(this), amount);
        // mint
        return _deposit(amount);
    }

    /**
     * @notice Starts the **cooldown** period for the user.
     */
    function startCooldown() external override {
        _cooldownStart[msg.sender] = uint40(block.timestamp);
        emit CooldownStarted(msg.sender);
    }

    /**
     * @notice Stops the **cooldown** period for the user.
     */
    function stopCooldown() external override {
        _cooldownStart[msg.sender] = 0;
        emit CooldownStopped(msg.sender);
    }

    /**
     * @notice Allows a user to redeem shares for **ETH**.
     * Burns **SCP** and transfers **ETH** to the [**Capital Provider**](/docs/user-guides/capital-provider/cp-role-guide).
     * @param shares Amount of shares to redeem.
     * @return value The amount in **ETH** that the shares where redeemed for.
     */
    function withdrawEth(uint256 shares) external override nonReentrant returns (uint256 value) {
        value = _withdraw(shares);
        // unwrap weth
        if(value > address(this).balance) {
            _weth.withdraw(value - address(this).balance);
        }
        // transfer eth
        Address.sendValue(payable(msg.sender), value);
        emit WithdrawalMade(msg.sender, value);
        return value;
    }

    /**
     * @notice Allows a user to redeem shares for **WETH**.
     * Burns **SCP** tokens and transfers **WETH** to the [**Capital Provider**](/docs/user-guides/capital-provider/cp-role-guide).
     * @param shares amount of shares to redeem.
     * @return value The amount in **WETH** that the shares where redeemed for.
     */
    function withdrawWeth(uint256 shares) external override nonReentrant returns (uint256 value) {
        value = _withdraw(shares);
        // wrap eth
        uint256 balance = _weth.balanceOf(address(this));
        if(value > balance) {
            _weth.deposit{value: value - balance}();
        }
        // transfer weth
        SafeERC20.safeTransfer(_weth, msg.sender, value);
        emit WithdrawalMade(msg.sender, value);
        return value;
    }

    /***************************************
    CAPITAL PROVIDER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The price of one **SCP**.
     * @return price The price in **ETH**.
     */
    function pricePerShare() external view override returns (uint256 price) {
        return (totalSupply() == 0 || _totalAssets() == 0)
            ? 1 ether
            : ((1 ether * _totalAssets()) / totalSupply());
    }

    /**
     * @notice Returns the maximum redeemable shares by the `user` such that `Vault` does not go under **MCR**(Minimum Capital Requirement). May be less than their balance.
     * @param user The address of user to check.
     * @return shares The max redeemable shares by the user.
     */
    function maxRedeemableShares(address user) external view override returns (uint256 shares) {
        uint256 userBalance = balanceOf(user);
        uint256 vaultBalanceAfterWithdraw = _totalAssets() - _shareValue(userBalance);
        // if user's CP token balance takes Vault `totalAssets` below MCR,
        //... return the difference between totalAsset and MCR (in # shares)
        uint256 mcr = IRiskManager(_registry.riskManager()).minCapitalRequirement();
        if (vaultBalanceAfterWithdraw < mcr) {
            uint256 diff = _totalAssets() - mcr;
            return _sharesForAmount(_shareValue(diff));
        } else {
            // else, user can withdraw up to their balance of CP tokens
            return userBalance;
        }
    }

    /**
     * @notice Returns the total quantity of all assets held by the `Vault`.
     * @return assets The total assets under control of this vault.
    */
    function totalAssets() external view override returns (uint256 assets) {
        return _totalAssets();
    }

    /// @notice The minimum amount of time a user must wait to withdraw funds.
    function cooldownMin() external view override returns (uint40) {
        return _cooldownMin;
    }

    /// @notice The maximum amount of time a user must wait to withdraw funds.
    function cooldownMax() external view override returns (uint40) {
        return _cooldownMax;
    }

    /**
     * @notice The timestamp that a depositor's cooldown started.
     * @param user The depositor.
     * @return start The timestamp in seconds.
     */
    function cooldownStart(address user) external view override returns (uint40) {
        return _cooldownStart[user];
    }

    /**
     * @notice Returns true if the user is allowed to receive or send vault shares.
     * @param user User to query.
     * return status True if can transfer.
     */
    function canTransfer(address user) external view override returns (bool status) {
        uint40 start = _cooldownStart[user];
        uint40 elapsed = uint40(block.timestamp) - start;
        // cooldown timer not started or
        // past withdrawable period
        return start == 0 || elapsed >= _cooldownMax;
    }

    /**
     * @notice Returns true if the user is allowed to withdraw vault shares.
     * @param user User to query.
     * return status True if can withdraw.
     */
    function canWithdraw(address user) public view override returns (bool status) {
        // validate cooldown
        uint40 elapsed = uint40(block.timestamp) - _cooldownStart[user];
        // cooldownMin <= elapsed <= cooldownMax
        return _cooldownMin <= elapsed && elapsed <= _cooldownMax;
    }

    /// @notice Returns true if the vault is paused.
    function paused() external view override returns (bool paused_) {
        return _paused;
    }

    /***************************************
    REQUESTOR FUNCTIONS
    ***************************************/

    /**
     * @notice Sends **ETH** to other users or contracts. The users or contracts should be authorized requestors.
     * Can only be called by authorized `requestors`.
     * @param amount The amount of **ETH** wanted.
     */
    function requestEth(uint256 amount) external override nonReentrant {
        require(_isRequestor[msg.sender], "!requestor");
        // unwrap some WETH to make ETH available for claims payout
        if(amount > address(this).balance) {
            uint256 wanted = amount - address(this).balance;
            uint256 withdrawAmount = Math.min(_weth.balanceOf(address(this)), wanted);
            _weth.withdraw(withdrawAmount);
        }
        // transfer funds
        uint256 transferAmount = Math.min(amount, address(this).balance);
        Address.sendValue(payable(msg.sender), transferAmount);
        emit FundsSent(transferAmount);
    }

    /**
     * @notice Returns true if the destination is authorized to request **ETH**.
     * @param dst Account to check requestability.
     * @return status True if requestor, false if not.
     */
    function isRequestor(address dst) external view override returns (bool status) {
        return _isRequestor[dst];
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Pauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * While paused:
     * 1. No users may deposit into the Vault.
     * 2. Withdrawls can bypass cooldown.
     * 3. Only Governance may unpause.
    */
    function pause() external override onlyGovernance {
        _paused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function unpause() external override onlyGovernance {
        _paused = false;
        emit Unpaused();
    }

    /**
     * @notice Sets the `minimum` and `maximum` amount of time in seconds that a user must wait to withdraw funds.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param cooldownMin_ Minimum time in seconds.
     * @param cooldownMax_ Maximum time in seconds.
     */
    function setCooldownWindow(uint40 cooldownMin_, uint40 cooldownMax_) external override onlyGovernance {
        require(cooldownMin_ <= cooldownMax_, "invalid window");
        _cooldownMin = cooldownMin_;
        _cooldownMax = cooldownMax_;
        emit CooldownWindowSet(cooldownMin_, cooldownMax_);
    }

    /**
     * @notice Adds requesting rights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param requestor The requestor to grant rights.
     */
    function addRequestor(address requestor) external override onlyGovernance {
        require(requestor != address(0x0), "zero address requestor");
        _isRequestor[requestor] = true;
        emit RequestorAdded(requestor);
    }

    /**
     * @notice Removes requesting rights.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param requestor The requestor to revoke rights.
     */
    function removeRequestor(address requestor) external override onlyGovernance {
        require(requestor != address(0x0), "zero address requestor");
        _isRequestor[requestor] = false;
        emit RequestorRemoved(requestor);
    }

    /***************************************
    INTERNAL FUNCTIONS
    ***************************************/

    /**
     * @notice Handles minting of tokens during deposit.
     * Called by [`depositEth()`](#depositeth) and [`depositWeth()`](#depositweth).
     * @param amount Amount of **ETH** or **WETH** deposited.
     * @return tokens The number of shares minted.
     */
    function _deposit(uint256 amount) internal returns (uint256) {
        require(!_paused, "cannot deposit while paused");
        // stop cooldown
        if(_cooldownStart[msg.sender] != 0) _cooldownStart[msg.sender] = 0;
        // calculate and mint shares
        uint256 ts = totalSupply();
        uint256 ta = _totalAssets() - amount;
        uint256 shares = (ts == 0 || ta == 0)
          ? amount
          : (amount * ts / ta);
        _mint(msg.sender, shares);
        emit DepositMade(msg.sender, amount, shares);
        return shares;
    }

    /**
     * @notice Handles burning of shares during withdraw.
     * Called by [`withdrawEth()`](#withdraweth) and [`withdrawWeth()`](#withdrawweth).
     * @param shares amount of shares to redeem.
     * @return value The amount in **ETH** that the shares where redeemed for.
     */
    function _withdraw(uint256 shares) internal returns (uint256) {
        // validate shares to withdraw
        require(shares <= balanceOf(msg.sender), "insufficient scp balance");
        uint256 value = _shareValue(shares);
        // bypass some checks while paused
        if(!_paused) {
            // Stop withdrawal if process brings the Vault's `totalAssets` value below minimum capital requirement
            uint256 mcr = IRiskManager(_registry.riskManager()).minCapitalRequirement();
            require(_totalAssets() - value >= mcr, "insufficient assets");
            // validate cooldown
            require(canWithdraw(msg.sender), "not in cooldown window");
        }
        // burn shares
        _burn(msg.sender, shares);
        return value;
    }

    /***************************************
    INTERNAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Internal function that returns quantity of all assets under control of this `Vault`.
     * Called by **totalAssets()** function.
     * @return totalAssets The total assets under control of this vault.
     */
    function _totalAssets() internal view returns (uint256) {
        return _weth.balanceOf(address(this)) + address(this).balance;
    }

    /**
     * @notice Internal function that determines the current value of given shares.
     * @param shares The amount of shares to calculate value for.
     * @return value The amount of value for given shares.
     */
    function _shareValue(uint256 shares) internal view returns (uint256) {
        return (totalSupply() == 0)
            ? 0
            : ((shares * _totalAssets()) / totalSupply());
    }

    /**
     * @notice Internal function that determines how many shares for given amount of token would receive.
     * @param amount of tokens to calculate number of shares for.
     * @return shares The amount of shares(tokens) for given amount.
     */
    function _sharesForAmount(uint256 amount) internal view returns (uint256) {
        return (_totalAssets() > 0)
            ? ((amount * totalSupply()) / _totalAssets())
            : 0;
    }

    /**
     * @notice Internal function that is called before token transfer in order to apply some security check.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // only care about user->user transfers
        // mint and burn are validated in deposit and withdraw
        if(from != address(0x0) && to != address(0x0)) {
            // bypass check while deposits are paused
            // worded differently, easier withdraws
            if(!_paused) {
                uint40 cdm = _cooldownMax;
                uint40 start1 = _cooldownStart[from];
                uint40 start2 = _cooldownStart[to];
                uint40 timestamp = uint40(block.timestamp);
                uint40 elapsed1 = timestamp - start1;
                uint40 elapsed2 = timestamp - start2;
                require(
                    (start1 == 0 || elapsed1 >= cdm) &&
                    (start2 == 0 || elapsed2 >= cdm),
                    "cannot transfer during cooldown"
                );
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive *ETH*.
     * Does _not_ mint shares.
     */
    receive () external payable override { }

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     * Does _not_ mint shares.
     */
    fallback () external payable override { }
}

