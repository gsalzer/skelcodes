// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../../external/barnbridge/BarnInterface.sol";
import "../../external/barnbridge/BarnRewardsInterface.sol";
import "../PrizePool.sol";

/// @title Prize Pool for Barn Bridge $BOND token
contract BarnPrizePool is PrizePool {
    using SafeMathUpgradeable for uint256;

    event BarnPrizePoolInitialized(address indexed barn);
    event SplitReserveWithdrawal(
        address indexed reserveFeeCollectorBarn,
        address indexed reserveFeeCollectorPoolTogether,
        uint256 amount
    );

    /// @notice Interface for the barn
    BarnInterface public barn;

    /// @notice Interface for the barn rewards
    BarnRewardsInterface public rewards;

    /// @notice $BOND token
    IERC20Upgradeable public bond;

    /// @notice Address to collect accrued reserve fees for Barn
    address public reserveFeeCollectorBarn;

    /// @notice Address to collect accrued reserve fees for PoolTogether
    address public reserveFeeCollectorPoolTogether;

    /// @notice Initializes the Prize Pool and Yield Service with the required contract connections
    /// @param _controlledTokens Array of addresses for the Ticket and Sponsorship Tokens controlled by the Prize Pool
    /// @param _maxExitFeeMantissa The maximum exit fee size, relative to the withdrawal amount
    /// @param _maxTimelockDuration The maximum length of time the withdraw timelock could be
    /// @param _barn Address of the barn
    /// @param _reserveFeeCollectorBarn The address which will collect fees for Barn side
    /// @param _reserveFeeCollectorPoolTogether The address which will collect fees for Pool Together side
    function initialize(
        RegistryInterface _reserveRegistry,
        ControlledTokenInterface[] memory _controlledTokens,
        uint256 _maxExitFeeMantissa,
        uint256 _maxTimelockDuration,
        BarnInterface _barn,
        BarnRewardsInterface _rewards,
        IERC20Upgradeable _bond,
        address _reserveFeeCollectorBarn,
        address _reserveFeeCollectorPoolTogether
    ) public initializer {
    PrizePool.initialize(
            _reserveRegistry,
            _controlledTokens,
            _maxExitFeeMantissa,
            _maxTimelockDuration
        );
        barn = _barn;
        rewards = _rewards;
        bond = _bond;
        reserveFeeCollectorBarn = _reserveFeeCollectorBarn;
        reserveFeeCollectorPoolTogether = _reserveFeeCollectorPoolTogether;

        emit BarnPrizePoolInitialized(address(barn));
    }

    /// @dev Gets the balance of the underlying assets held by the Yield Service
    /// @return The underlying balance of asset tokens
    function _balance() internal override returns (uint256) {
        uint256 balance = barn.balanceOf(address(this));
        uint256 total = balance.add(owedReward());
        return total;
    }

    /// @dev Allows a user to supply asset tokens in exchange for yield-bearing tokens
    /// to be held in escrow by the Yield Service
    function _supply(uint256 amount) internal override {
        IERC20Upgradeable bondToken = _token();
        bondToken.approve(address(barn), amount);
        barn.deposit(amount);
    }

    /// @dev The external token cannot be yDai or Dai
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken)
        internal
        view
        override
        returns (bool)
    {
        return _externalToken != address(bond);
    }

    /// @dev Allows a user to redeem yield-bearing tokens in exchange for the underlying
    /// asset tokens held in escrow by the Yield Service
    /// @param amount The amount of underlying tokens to be redeemed
    /// @return The actual amount of tokens transferred
    function _redeem(uint256 amount) internal override returns (uint256) {
        require(_balance() >= amount, "BarnPrizePool/insuff-liquidity");
        IERC20Upgradeable token = _token();

        uint256 diff = 0;
        uint256 amountToClaim = owedReward();

        /// Check if there is anything to claim from the rewards
        if (amountToClaim > 0) {
            rewards.claim();
        }

        uint256 currentBalance = token.balanceOf(address(this));

        /// If current bond balance is enough, deposit the difference back to Barn
        if (currentBalance > amount) {
            diff = currentBalance.sub(amount);
            token.approve(address(barn), diff);
            barn.deposit(diff);
        }

        /// If current bond balance is not enough, try to withdraw the difference from Barn
        if (currentBalance < amount) {
            diff = amount.sub(currentBalance);
            barn.withdraw(diff);
        }

        uint256 postBalance = token.balanceOf(address(this));

        require(postBalance == amount, "BarnPrizePool/insuff-liquidity");
        return amount;
    }

    /// @dev Gets the underlying asset token used by the Yield Service
    /// @return A reference to the interface of the underling asset token
    function _token() internal view override returns (IERC20Upgradeable) {
        return IERC20Upgradeable(bond);
    }

    /// @dev Gets the up to date award generated by the Yield Service
    /// @return The amount of the award
    function owedReward() public view returns (uint256) {
        uint256 owed = rewards.owed(address(this));
        uint256 multiplier = rewards.currentMultiplier().sub(rewards.userMultiplier(address(this)));
        uint256 pendingReward = barn.balanceOf(address(this)).mul(multiplier).div(10 ** 18);

        return owed.add(pendingReward);
    }

    function withdrawSplitReserve() external onlyReserve returns (uint256) {
        uint256 amount = reserveTotalSupply;
        reserveTotalSupply = 0;
        uint256 redeemed = _redeem(amount);

        uint256 ptReserveAmount = redeemed.div(2);
        uint256 barnReserveAmount = redeemed.sub(ptReserveAmount);
        
        _token().safeTransfer(
            address(reserveFeeCollectorPoolTogether),
            ptReserveAmount
        );

        _token().safeTransfer(
            address(reserveFeeCollectorBarn),
            barnReserveAmount
        );

        emit SplitReserveWithdrawal(reserveFeeCollectorBarn, reserveFeeCollectorPoolTogether, amount);
        
        return redeemed;
    }
}

