// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./BondTellerBase.sol";
import "./interface/IBondTellerEth.sol";


/**
 * @title BondTellerEth
 * @author solace.fi
 * @notice A bond teller that accepts **ETH** and **WETH** as payment.
 *
 * Bond tellers allow users to buy bonds. After vesting for `vestingTerm`, bonds can be redeemed for [**SOLACE**](./SOLACE) or [**xSOLACE**](./xSOLACE). Payments are made in **ETH** or **WETH** which is sent to the underwriting pool and used to back risk.
 *
 * Bonds can be purchased via [`depositEth()`](#depositeth), [`depositWeth()`](#depositweth), or [`depositWethSigned()`](#depositwethsigned). Bonds are represented as ERC721s, can be viewed with [`bonds()`](#bonds), and redeemed with [`redeem()`](#redeem).
 *
 * Most of the implementation details are in [`BondTellerBase`](./BondTellerBase).
 */
contract BondTellerEth is BondTellerBase, IBondTellerEth {

    /***************************************
    BONDER FUNCTIONS
    ***************************************/

    /**
     * @notice Create a bond by depositing **ETH**.
     * Principal will be transferred from `msg.sender` using `allowance`.
     * @param minAmountOut The minimum **SOLACE** or **xSOLACE** out.
     * @param depositor The bond recipient, default msg.sender.
     * @param stake True to stake, false to not stake.
     * @return payout The amount of SOLACE or xSOLACE in the bond.
     * @return bondID The ID of the newly created bond.
     */
    function depositEth(
        uint256 minAmountOut,
        address depositor,
        bool stake
    ) external payable override returns (uint256 payout, uint256 bondID) {
        // accounting
        return _deposit(msg.value, minAmountOut, depositor, stake, false);
    }

    /**
     * @notice Create a bond by depositing `amount` **WETH**.
     * **WETH** will be transferred from `msg.sender` using `allowance`.
     * @param amount Amount of **WETH** to deposit.
     * @param minAmountOut The minimum **SOLACE** or **xSOLACE** out.
     * @param depositor The bond recipient, default msg.sender.
     * @param stake True to stake, false to not stake.
     * @return payout The amount of SOLACE or xSOLACE in the bond.
     * @return bondID The ID of the newly created bond.
     */
    function depositWeth(
        uint256 amount,
        uint256 minAmountOut,
        address depositor,
        bool stake
    ) external override returns (uint256 payout, uint256 bondID) {
        // pull tokens
        SafeERC20.safeTransferFrom(principal, msg.sender, address(this), amount);
        // accounting
        return _deposit(amount, minAmountOut, depositor, stake, true);
    }

    /**
     * @notice Create a bond by depositing `amount` **WETH**.
     * **WETH** will be transferred from `depositor` using `permit`.
     * Note that not all **WETH**s have a permit function, in which case this function will revert.
     * @param amount Amount of **WETH** to deposit.
     * @param minAmountOut The minimum **SOLACE** or **xSOLACE** out.
     * @param depositor The bond recipient, default msg.sender.
     * @param stake True to stake, false to not stake.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     * @return payout The amount of SOLACE or xSOLACE in the bond.
     * @return bondID The ID of the newly created bond.
     */
    function depositWethSigned(
        uint256 amount,
        uint256 minAmountOut,
        address depositor,
        bool stake,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 payout, uint256 bondID) {
        // permit
        IERC20Permit(address(principal)).permit(depositor, address(this), amount, deadline, v, r, s);
        // pull tokens
        SafeERC20.safeTransferFrom(principal, depositor, address(this), amount);
        // accounting
        return _deposit(amount, minAmountOut, depositor, stake, true);
    }

    /**
     * @notice Create a bond by depositing `amount` of `principal`.
     * @param amount Amount of principal to deposit.
     * @param minAmountOut The minimum **SOLACE** or **xSOLACE** out.
     * @param depositor The bond recipient, default msg.sender.
     * @param stake True to stake, false to not stake.
     * @param isWrapped True if payment was made in **WETH**, false if made in **ETH**.
     * @return payout The amount of SOLACE or xSOLACE in the bond.
     * @return bondID The ID of the newly created bond.
     */
    function _deposit(
        uint256 amount,
        uint256 minAmountOut,
        address depositor,
        bool stake,
        bool isWrapped
    ) internal returns (uint256 payout, uint256 bondID) {
        require(depositor != address(0), "invalid address");
        require(!paused, "cannot deposit while paused");

        require(termsSet, "not initialized");
        require(block.timestamp >= uint256(startTime), "bond not yet started");
        require(block.timestamp <= uint256(endTime), "bond concluded");

        payout = _calculatePayout(amount);

        // ensure there is remaining capacity for bond
        if (capacityIsPayout) {
            // capacity in payout terms
            require(capacity >= payout, "bond at capacity");
            capacity = capacity - payout;
        } else {
            // capacity in principal terms
            require(capacity >= amount, "bond at capacity");
            capacity = capacity - amount;
        }
        require(payout <= maxPayout, "bond too large");

        uint256 maturation = vestingTerm + block.timestamp;
        // route principal
        uint256 daoFee = amount * daoFeeBps / MAX_BPS;
        if(daoFee > 0) _transferEth(dao, daoFee, isWrapped);
        _transferEth(underwritingPool, amount - daoFee, isWrapped);
        // route solace
        bondDepo.pullSolace(payout);
        uint256 bondFee = payout * bondFeeBps / MAX_BPS;
        if(bondFee > 0) {
            SafeERC20.safeTransfer(solace, address(xsolace), bondFee);
            payout -= bondFee;
        }

        // optionally stake
        address payoutToken;
        if(stake) {
            payoutToken = address(xsolace);
            payout = xsolace.stake(payout);
        } else {
            payoutToken = address(solace);
        }
        require(minAmountOut <= payout, "slippage protection: insufficient output");

        // record bond info
        bondID = ++numBonds;
        bonds[bondID] = Bond({
            payoutToken: payoutToken,
            payoutAmount: payout,
            pricePaid: amount,
            maturation: maturation
        });
        _mint(depositor, bondID);
        emit CreateBond(bondID, amount, payoutToken, payout, maturation);
        return (payout, bondID);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Safely transfers **ETH** or **WETH**.
     * @param destination Where to send.
     * @param amount Amount to send.
     * @param isWrapped True to send **WETH**, false to send **ETH**.
     */
    function _transferEth(address destination, uint256 amount, bool isWrapped) internal {
        if(isWrapped) SafeERC20.safeTransfer(principal, destination, amount);
        else Address.sendValue(payable(destination), amount);
    }

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive *ETH*.
     * Deposits **ETH** and creates bond.
     */
    receive () external payable override nonReentrant {
        _deposit(msg.value, 0, msg.sender, false, false);
    }

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     * Deposits **ETH** and creates bond.
     */
    fallback () external payable override nonReentrant {
        _deposit(msg.value, 0, msg.sender, false, false);
    }
}

