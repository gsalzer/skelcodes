// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title IBondTeller
 * @author solace.fi
 * @notice Base type of Bond Tellers.
 *
 * Bond tellers allow users to buy bonds. After vesting for `vestingTerm`, bonds can be redeemed for [**SOLACE**](./SOLACE) or [**xSOLACE**](./xSOLACE). Payments are made in `principal` which is sent to the underwriting pool and used to back risk.
 *
 * Bonds are represented as ERC721s, can be viewed with [`bonds()`](#bonds), and redeemed with [`redeem()`](#redeem).
 */
interface IBondTeller {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a bond is created.
    event CreateBond(uint256 bondID, uint256 principalAmount, address payoutToken, uint256 payoutAmount, uint256 maturation);
    /// @notice Emitted when a bond is redeemed.
    event RedeemBond(uint256 bondID, address recipient, address payoutToken, uint256 payoutAmount);
    /// @notice Emitted when deposits are paused.
    event Paused();
    /// @notice Emitted when deposits are unpaused.
    event Unpaused();
    /// @notice Emitted when terms are set.
    event TermsSet();
    /// @notice Emitted when fees are set.
    event FeesSet();
    /// @notice Emitted when fees are set.
    event AddressesSet();

    /***************************************
    INITIALIZER
    ***************************************/

    /**
     * @notice Initializes the teller.
     * @param name_ The name of the bond token.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param solace_ The SOLACE token.
     * @param xsolace_ The xSOLACE token.
     * @param pool_ The underwriting pool.
     * @param dao_ The DAO.
     * @param principal_ address The ERC20 token that users deposit.
     * @param bondDepo_ The bond depository.
     */
    function initialize(
        string memory name_,
        address governance_,
        address solace_,
        address xsolace_,
        address pool_,
        address dao_,
        address principal_,
        address bondDepo_
    ) external;

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    // BOND PRICE

    /**
     * @notice Calculate the current price of a bond.
     * Assumes 1 SOLACE payout.
     * @return price_ The price of the bond measured in `principal`.
     */
    function bondPrice() external view returns (uint256 price_);

    /**
     * @notice Calculate the amount of **SOLACE** or **xSOLACE** out for an amount of `principal`.
     * @param amountIn Amount of principal to deposit.
     * @param stake True to stake, false to not stake.
     * @return amountOut Amount of **SOLACE** or **xSOLACE** out.
     */
    function calculateAmountOut(uint256 amountIn, bool stake) external view returns (uint256 amountOut);

    /**
     * @notice Calculate the amount of `principal` in for an amount of **SOLACE** or **xSOLACE** out.
     * @param amountOut Amount of **SOLACE** or **xSOLACE** out.
     * @param stake True to stake, false to not stake.
     * @return amountIn Amount of principal to deposit.
     */
    function calculateAmountIn(uint256 amountOut, bool stake) external view returns (uint256 amountIn);

    /***************************************
    BONDER FUNCTIONS
    ***************************************/

    /**
     * @notice Redeem a bond.
     * Bond must be matured.
     * Redeemer must be owner or approved.
     * @param bondID The ID of the bond to redeem.
     */
    function redeem(uint256 bondID) external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Pauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function pause() external;

    /**
     * @notice Unpauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function unpause() external;

    /**
     * @notice Sets the addresses to call out.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace_ The SOLACE token.
     * @param xsolace_ The xSOLACE token.
     * @param pool_ The underwriting pool.
     * @param dao_ The DAO.
     * @param principal_ address The ERC20 token that users deposit.
     * @param bondDepo_ The bond depository.
     */
    function setAddresses(
        address solace_,
        address xsolace_,
        address pool_,
        address dao_,
        address principal_,
        address bondDepo_
    ) external;
}

