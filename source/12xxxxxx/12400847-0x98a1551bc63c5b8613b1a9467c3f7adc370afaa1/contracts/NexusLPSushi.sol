// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./RebalancingStrategy1.sol";

/**
 * This contract is part of Orbs Liquidity Nexus protocol. It is a thin wrapper over
 * Sushi LP token and represents liquidity added to the Sushi ETH/USDC pair.
 *
 * The purpose of Liquidity Nexus is to allow single-sided ETH-only farming on SushiSwap.
 * In regular Sushi LP, users add liquidity of both USDC and ETH in equal values. Nexus
 * LP allows users to add liquidity in ETH only, without needing any USDC.
 *
 * So where does the USDC come from? USDC is sourced separately from Orbs Liquidity
 * Nexus and originates from CeFi. This large pool of USDC is deployed in advance and is
 * waiting in the contract until ETH is added. Once ETH is added by users, it is paired
 * with part of the available USDC to generate regular Sushi LP. When liquidity is
 * removed by a user, the Sushi LP is burned, the USDC is returned to the pool and the
 * ETH is returned to the user.
 */
contract NexusLPSushi is ERC20("Nexus LP SushiSwap ETH/USDC", "NSLP"), RebalancingStrategy1 {
    using SafeERC20 for IERC20;

    event Mint(address indexed sender, address indexed beneficiary, uint256 shares);
    event Burn(address indexed sender, address indexed beneficiary, uint256 shares);
    event Pair(
        address indexed sender,
        address indexed minter,
        uint256 pairedUSDC,
        uint256 pairedETH,
        uint256 liquidity
    );
    event Unpair(address indexed sender, address indexed minter, uint256 exitUSDC, uint256 exitETH, uint256 liquidity);
    event ClaimRewards(address indexed sender, uint256 amount);
    event CompoundProfits(address indexed sender, uint256 liquidity);

    /**
     * Stores the original minter for every Nexus LP token, only this original minter
     * can burn the tokens and remove liquidity. This means the address that calls addLiquidity
     * must also call removeLiquidity.
     */
    struct Minter {
        uint256 pairedETH;
        uint256 pairedUSDC;
        uint256 pairedShares; // Nexus LP tokens that represent ETH paired with USDC to create Sushi LP
        uint256 unpairedETH;
        uint256 unpairedShares; // Nexus LP tokens that represent standalone ETH (waiting in this contract's balance)
    }

    uint256 public totalLiquidity;
    uint256 public totalPairedUSDC;
    uint256 public totalPairedETH;
    uint256 public totalPairedShares;
    mapping(address => Minter) public minters;

    /**
     * The contract holds available USDC to be paired with newly deposited ETH to create
     * Sushi LP. If there's not enough available USDC, the ETH deposit tx will revert.
     * This view function shows what's the maximum amount of ETH that can be deposited.
     * Should be called by clients to make sure users' txs are not reverted.
     */
    function availableSpaceToDepositETH() external view returns (uint256 amountETH) {
        return quoteInverse(IERC20(USDC).balanceOf(address(this)));
    }

    /**
     * The number of Sushi LP per Nexus LP share is growing due to rewards compounding.
     * This view function shows this number that should be above 1 at all times.
     */
    function pricePerFullShare() external view returns (uint256) {
        if (totalPairedShares == 0) return 0;
        return (1 ether * totalLiquidity) / totalPairedShares;
    }

    /**
     * Depositors only deposit ETH. This convenience function allows to deposit ETH directly.
     */
    function addLiquidityETH(address beneficiary, uint256 deadline)
        external
        payable
        nonReentrant
        whenNotPaused
        verifyPrice(quote(1 ether))
    {
        uint256 amountETH = msg.value;
        IWETH(WETH).deposit{value: amountETH}();
        _deposit(beneficiary, amountETH, deadline);
    }

    /**
     * Depositors only deposit ETH. This convenience function allows to deposit WETH (ERC20).
     */
    function addLiquidity(
        address beneficiary,
        uint256 amountETH,
        uint256 deadline
    ) external nonReentrant whenNotPaused verifyPrice(quote(1 ether)) {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amountETH);
        _deposit(beneficiary, amountETH, deadline);
    }

    /**
     * When a depositor removes liquidity, they get ETH back. This works with ETH directly.
     * Argument shares is the number of Nexus LP tokens to burn.
     * Note: only the original address that called addLiquidity can call removeLiquidity.
     */
    function removeLiquidityETH(
        address payable beneficiary,
        uint256 shares,
        uint256 deadline
    ) external nonReentrant verifyPrice(quote(1 ether)) returns (uint256 exitETH) {
        exitETH = _withdraw(msg.sender, beneficiary, shares, deadline);
        IWETH(WETH).withdraw(exitETH);
        Address.sendValue(beneficiary, exitETH);
    }

    /**
     * When a depositor removes liquidity, they get ETH back. This works with WETH (ERC20).
     * Argument shares is the number of Nexus LP tokens to burn.
     * Note: only the original address that called addLiquidity can call removeLiquidity.
     */
    function removeLiquidity(
        address beneficiary,
        uint256 shares,
        uint256 deadline
    ) external nonReentrant verifyPrice(quote(1 ether)) returns (uint256 exitETH) {
        exitETH = _withdraw(msg.sender, beneficiary, shares, deadline);
        IERC20(WETH).safeTransfer(beneficiary, exitETH);
    }

    /**
     * Remove the entire Nexus LP balance.
     */
    function removeAllLiquidityETH(address payable beneficiary, uint256 deadline)
        external
        nonReentrant
        verifyPrice(quote(1 ether))
        returns (uint256 exitETH)
    {
        exitETH = _withdraw(msg.sender, beneficiary, balanceOf(msg.sender), deadline);
        require(exitETH <= IERC20(WETH).balanceOf(address(this)), "not enough ETH");
        IWETH(WETH).withdraw(exitETH);
        Address.sendValue(beneficiary, exitETH);
    }

    /**
     * Remove the entire Nexus LP balance.
     */
    function removeAllLiquidity(address beneficiary, uint256 deadline)
        external
        nonReentrant
        verifyPrice(quote(1 ether))
        returns (uint256 exitETH)
    {
        exitETH = _withdraw(msg.sender, beneficiary, balanceOf(msg.sender), deadline);
        IERC20(WETH).safeTransfer(beneficiary, exitETH);
    }

    /**
     * Since all Sushi LP held by this contract are auto deposited in Sushi MasterChef, SUSHI rewards accrue.
     * This allows the governance (the vault working with this contract) to claim the rewards so they can
     * be sold by governance and compounded back inside via compoundProfits.
     */
    function claimRewards() external nonReentrant onlyGovernance {
        _claimRewards();
        uint256 amount = IERC20(REWARD).balanceOf(address(this));
        IERC20(REWARD).safeTransfer(msg.sender, amount);

        emit ClaimRewards(msg.sender, amount);
    }

    /**
     * SUSHI rewards that were claimed by governance (the vault working with this contract) and sold by
     * governance can be compounded back inside via this function. Receives all sold rewards as ETH.
     * Argument capitalProviderRewardPercentmil is the split of the profits that should be given to the
     * provider of USDC. Use 50000 to have an even 50/50 split of the reward profits. Use 20000 to take 80%
     * to the ETH providers and leave 20% of reward profits to the USDC provider.
     */
    function compoundProfits(uint256 amountETH, uint256 capitalProviderRewardPercentmil)
        external
        nonReentrant
        onlyGovernance
        returns (
            uint256 pairedUSDC,
            uint256 pairedETH,
            uint256 liquidity
        )
    {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amountETH);

        if (capitalProviderRewardPercentmil > 0) {
            uint256 ownerETH = (amountETH * capitalProviderRewardPercentmil) / 100_000;
            _swapExactETHForUSDC(ownerETH);
            amountETH -= ownerETH;
        }

        amountETH /= 2;
        _swapExactETHForUSDC(amountETH);

        (pairedUSDC, pairedETH, liquidity) = _addLiquidityAndStake(amountETH, block.timestamp); // solhint-disable-line not-rely-on-time
        totalPairedUSDC += pairedUSDC;
        totalPairedETH += pairedETH;
        totalLiquidity += liquidity;
        // not adding to shares to distribute rewards to all shareholders

        emit CompoundProfits(msg.sender, liquidity);
    }

    function _deposit(
        address beneficiary,
        uint256 amountETH,
        uint256 deadline
    ) private {
        uint256 shares = _pair(beneficiary, amountETH, deadline);
        _mint(beneficiary, shares);
        emit Mint(msg.sender, beneficiary, shares);
    }

    /**
     * Pair deposited ETH with USDC available in the contract's balance to create Sushi LP.
     */
    function _pair(
        address minterAddress,
        uint256 amountETH,
        uint256 deadline
    ) private returns (uint256 shares) {
        (uint256 pairedUSDC, uint256 pairedETH, uint256 liquidity) = _addLiquidityAndStake(amountETH, deadline);

        if (totalPairedShares == 0) {
            shares = liquidity;
        } else {
            shares = (liquidity * totalPairedShares) / totalLiquidity;
        }

        Minter storage minter = minters[minterAddress];
        minter.pairedUSDC += pairedUSDC;
        minter.pairedETH += pairedETH;
        minter.pairedShares += shares;

        totalPairedUSDC += pairedUSDC;
        totalPairedETH += pairedETH;
        totalPairedShares += shares;
        totalLiquidity += liquidity;

        emit Pair(msg.sender, minterAddress, pairedUSDC, pairedETH, liquidity);
    }

    function _withdraw(
        address sender,
        address beneficiary,
        uint256 shares,
        uint256 deadline
    ) private returns (uint256 exitETH) {
        Minter storage minter = minters[sender];
        shares = Math.min(shares, minter.pairedShares + minter.unpairedShares);
        require(shares > 0, "sender not in minters");

        if (shares > minter.unpairedShares) {
            _unpair(sender, shares - minter.unpairedShares, deadline);
        }

        exitETH = (shares * minter.unpairedETH) / minter.unpairedShares;
        minter.unpairedETH -= exitETH;
        minter.unpairedShares -= shares;

        _burn(sender, shares);
        emit Burn(sender, beneficiary, shares);
    }

    /**
     * Unpair ETH from USDC by burning Sushi LP and rebalancing IL between the two.
     */
    function _unpair(
        address minterAddress,
        uint256 shares,
        uint256 deadline
    ) private {
        uint256 liquidity = (shares * totalLiquidity) / totalPairedShares;
        (uint256 removedETH, uint256 removedUSDC) = _unstakeAndRemoveLiquidity(liquidity, deadline);

        Minter storage minter = minters[minterAddress];
        uint256 pairedUSDC = (minter.pairedUSDC * shares) / minter.pairedShares;
        uint256 pairedETH = (minter.pairedETH * shares) / minter.pairedShares;
        (uint256 exitUSDC, uint256 exitETH) = applyRebalance(removedUSDC, removedETH, pairedUSDC, pairedETH);

        minter.pairedUSDC -= pairedUSDC;
        minter.pairedETH -= pairedETH;
        minter.pairedShares -= shares;

        minter.unpairedETH += exitETH;
        minter.unpairedShares += shares;

        totalPairedUSDC -= pairedUSDC;
        totalPairedETH -= pairedETH;
        totalPairedShares -= shares;
        totalLiquidity -= liquidity;

        emit Unpair(msg.sender, minterAddress, exitUSDC, exitETH, liquidity);
    }

    /**
     * Allows the owner (the capital provider of USDC) to emergency exit all of their USDC.
     * When called, all Sushi LP is burned to extract ETH+USDC, the USDC part is returned to owner.
     * The ETH will wait in the contract until the original ETH depositors will remove it.
     */
    function emergencyExit(address[] memory minterAddresses) external onlyOwner {
        for (uint256 i = 0; i < minterAddresses.length; i++) {
            address minterAddress = minterAddresses[i];
            Minter storage minter = minters[minterAddress];
            uint256 shares = minter.pairedShares;
            if (shares > 0) {
                _unpair(minterAddress, shares, block.timestamp); //solhint-disable-line not-rely-on-time
            }
        }

        withdrawFreeCapital();
    }
}

