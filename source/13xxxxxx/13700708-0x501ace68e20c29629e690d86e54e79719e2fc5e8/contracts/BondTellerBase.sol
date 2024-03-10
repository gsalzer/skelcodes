// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./GovernableInitializable.sol";
import "./ERC721EnhancedInitializable.sol";
import "./interface/ISOLACE.sol";
import "./interface/IxSOLACE.sol";
import "./interface/IBondDepository.sol";
import "./interface/IBondTellerErc20.sol";


/**
 * @title BondTellerBase
 * @author solace.fi
 * @notice A base type for bond tellers.
 *
 * Bond tellers allow users to buy bonds. After vesting for `vestingTerm`, bonds can be redeemed for [**SOLACE**](./SOLACE) or [**xSOLACE**](./xSOLACE). Payments are made in `principal` which is sent to the underwriting pool and used to back risk.
 *
 * Bonds are represented as ERC721s, can be viewed with [`bonds()`](#bonds), and redeemed with [`redeem()`](#redeem).
 */
abstract contract BondTellerBase is IBondTeller, ReentrancyGuard, GovernableInitializable, ERC721EnhancedInitializable {
    using SafeERC20 for IERC20;

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // prices
    uint256 public capacity;                   // capacity remaining for all bonds
    uint256 public nextPrice;                  // the price of the next bond before decay
    uint256 public minimumPrice;               // price floor measured in principal per 1 solace
    uint128 public priceAdjNum;                // factor that increases price after purchase
    uint128 public priceAdjDenom;              // factor that increases price after purchase
    uint256 public halfLife;                   // factor for price decay
    uint256 public lastPriceUpdate;            // last timestamp price was updated
    uint256 public maxPayout;                  // max payout in a single bond measured in principal
    uint256 internal constant MAX_BPS = 10000; // 10k basis points (100%)
    uint256 public daoFeeBps;                  // portion of principal that is sent to the dao, the rest to the pool
    uint256 public bondFeeBps;                 // portion of SOLACE that is sent to stakers, the rest to the bonder
    bool public termsSet;                      // have terms been set
    bool public capacityIsPayout;              // capacity limit is for payout vs principal
    bool public paused;                        // pauses deposits

    // times
    uint40 public startTime;                   // timestamp bonds start
    uint40 public endTime;                     // timestamp bonds no longer offered
    uint40 public vestingTerm;                 // duration in seconds (fixed-term)

    // bonds
    uint256 public numBonds;                   // total number of bonds that have been created

    struct Bond {
        address payoutToken;                   // solace or xsolace
        uint256 payoutAmount;                  // amount of solace or xsolace to be paid
        uint256 pricePaid;                     // measured in 'principal', for front end viewing
        uint256 maturation;                    // timestamp after which bond is redeemable
    }

    mapping (uint256 => Bond) public bonds;    // mapping of bondID to Bond object

    // addresses
    ISOLACE public solace;                     // solace native token
    IxSOLACE public xsolace;                   // xsolace staking contract
    IERC20 public principal;                   // token to accept as payment
    address public underwritingPool;           // the underwriting pool to back risks
    address public dao;                        // the dao
    IBondDepository public bondDepo;           // the bond depository

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
    ) external override initializer {
        __Governable_init(governance_);
        string memory symbol = "SBT";
        __ERC721Enhanced_init(name_, symbol);
        _setAddresses(solace_, xsolace_, pool_, dao_, principal_, bondDepo_);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    // BOND PRICE

    /**
     * @notice Calculate the current price of a bond.
     * Assumes 1 SOLACE payout.
     * @return price_ The price of the bond measured in `principal`.
     */
    function bondPrice() public view override returns (uint256 price_) {
        uint256 timeSinceLast = block.timestamp - lastPriceUpdate;
        price_ = exponentialDecay(nextPrice, timeSinceLast);
        if (price_ < minimumPrice) {
            price_ = minimumPrice;
        }
    }

    /**
     * @notice Calculate the amount of **SOLACE** or **xSOLACE** out for an amount of `principal`.
     * @param amountIn Amount of principal to deposit.
     * @param stake True to stake, false to not stake.
     * @return amountOut Amount of **SOLACE** or **xSOLACE** out.
     */
    function calculateAmountOut(uint256 amountIn, bool stake) external view override returns (uint256 amountOut) {
        require(termsSet, "not initialized");
        // exchange rate
        uint256 bondPrice_ = bondPrice();
        require(bondPrice_ > 0, "zero price");
        amountOut = 1 ether * amountIn / bondPrice_; // 1 ether => 1 solace
        // ensure there is remaining capacity for bond
        if (capacityIsPayout) {
            // capacity in payout terms
            require(capacity >= amountOut, "bond at capacity");
        } else {
            // capacity in principal terms
            require(capacity >= amountIn, "bond at capacity");
        }
        require(amountOut <= maxPayout, "bond too large");
        // route solace
        uint256 bondFee = amountOut * bondFeeBps / MAX_BPS;
        if(bondFee > 0) {
            amountOut -= bondFee;
        }
        // optionally stake
        if(stake) {
            amountOut = xsolace.solaceToXSolace(amountOut);
        }
        return amountOut;
    }

    /**
     * @notice Calculate the amount of `principal` in for an amount of **SOLACE** or **xSOLACE** out.
     * @param amountOut Amount of **SOLACE** or **xSOLACE** out.
     * @param stake True to stake, false to not stake.
     * @return amountIn Amount of principal to deposit.
     */
    function calculateAmountIn(uint256 amountOut, bool stake) external view override returns (uint256 amountIn) {
        require(termsSet, "not initialized");
        // optionally stake
        if(stake) {
            amountOut = xsolace.xSolaceToSolace(amountOut);
        }
        // bond fee
        amountOut = amountOut * MAX_BPS / (MAX_BPS - bondFeeBps);
        // exchange rate
        uint256 bondPrice_ = bondPrice();
        require(bondPrice_ > 0, "zero price");
        amountIn = amountOut * bondPrice_ / 1 ether;
        // ensure there is remaining capacity for bond
        if (capacityIsPayout) {
            // capacity in payout terms
            require(capacity >= amountOut, "bond at capacity");
        } else {
            // capacity in principal terms
            require(capacity >= amountIn, "bond at capacity");
        }
        require(amountOut <= maxPayout, "bond too large");
    }

    /***************************************
    BONDER FUNCTIONS
    ***************************************/

    /**
     * @notice Redeem a bond.
     * Bond must be matured.
     * Redeemer must be owner or approved.
     * @param bondID The ID of the bond to redeem.
     */
    function redeem(uint256 bondID) external override nonReentrant tokenMustExist(bondID) {
        // checks
        Bond memory bond = bonds[bondID];
        require(_isApprovedOrOwner(msg.sender, bondID), "!bonder");
        require(block.timestamp >= bond.maturation, "bond not yet redeemable");
        // send payout
        SafeERC20.safeTransfer(IERC20(bond.payoutToken), msg.sender, bond.payoutAmount);
        // delete bond
        _burn(bondID);
        delete bonds[bondID];
        emit RedeemBond(bondID, msg.sender, bond.payoutToken, bond.payoutAmount);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Calculate the payout in **SOLACE** and update the current price of a bond.
     * @param depositAmount asdf
     * @return amountOut asdf
     */
    function _calculatePayout(uint256 depositAmount) internal returns (uint256 amountOut) {
        // calculate this price
        uint256 timeSinceLast = block.timestamp - lastPriceUpdate;
        uint256 price_ = exponentialDecay(nextPrice, timeSinceLast);
        if(price_ < minimumPrice) price_ = minimumPrice;
        require(price_ != 0, "invalid price");
        lastPriceUpdate = block.timestamp;
        // calculate amount out
        amountOut = 1 ether * depositAmount / price_; // 1 ether => 1 solace
        // update next price
        nextPrice = price_ + (amountOut * uint256(priceAdjNum) / uint256(priceAdjDenom));
    }

    /**
     * @notice Calculates exponential decay.
     * @dev Linear approximation, trades precision for speed.
     * @param initValue The initial value.
     * @param time The time elapsed.
     * @return endValue The value at the end.
     */
    function exponentialDecay(uint256 initValue, uint256 time) internal view returns (uint256 endValue) {
        endValue = initValue >> (time / halfLife);
        endValue -= endValue * (time % halfLife) / halfLife / 2;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Pauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function pause() external override onlyGovernance {
        paused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses deposits.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
    */
    function unpause() external override onlyGovernance {
        paused = false;
        emit Unpaused();
    }

    struct Terms {
        uint256 startPrice;     // The starting price, measured in `principal` for one **SOLACE**.
        uint256 minimumPrice;   // The minimum price of a bond, measured in `principal` for one **SOLACE**.
        uint256 maxPayout;      // The maximum **SOLACE** that can be sold in a single bond.
        uint128 priceAdjNum;    // Used to calculate price increase after bond purchase.
        uint128 priceAdjDenom;  // Used to calculate price increase after bond purchase.
        uint256 capacity;       // The amount still sellable.
        bool capacityIsPayout;  // True if `capacity_` is measured in **SOLACE**, false if measured in `principal`.
        uint40 startTime;       // The time that purchases start.
        uint40 endTime;         // The time that purchases end.
        uint40 vestingTerm;     // The duration that users must wait to redeem bonds.
        uint40 halfLife;        // Used to calculate price decay.
    }

    /**
     * @notice Sets the bond terms.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param terms The terms of the bond.
     */
    function setTerms(Terms calldata terms) external onlyGovernance {
        require(terms.startPrice > 0, "invalid price");
        nextPrice = terms.startPrice;
        minimumPrice = terms.minimumPrice;
        maxPayout = terms.maxPayout;
        require(terms.priceAdjDenom != 0, "1/0");
        priceAdjNum = terms.priceAdjNum;
        priceAdjDenom = terms.priceAdjDenom;
        capacity = terms.capacity;
        capacityIsPayout = terms.capacityIsPayout;
        require(terms.startTime <= terms.endTime, "invalid dates");
        startTime = terms.startTime;
        endTime = terms.endTime;
        vestingTerm = terms.vestingTerm;
        require(terms.halfLife > 0, "invalid halflife");
        halfLife = terms.halfLife;
        termsSet = true;
        lastPriceUpdate = block.timestamp;
        emit TermsSet();
    }

    /**
     * @notice Sets the bond fees.
     * @param bondFee The fraction of **SOLACE** that will be sent to stakers measured in BPS.
     * @param daoFee The fraction of `principal` that will be sent to the dao measured in BPS.
     */
    function setFees(uint256 bondFee, uint256 daoFee) external onlyGovernance {
        require(bondFee <= MAX_BPS, "invalid bond fee");
        require(daoFee <= MAX_BPS, "invalid dao fee");
        bondFeeBps = bondFee;
        daoFeeBps = daoFee;
        emit FeesSet();
    }

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
    ) external override onlyGovernance {
        _setAddresses(solace_, xsolace_, pool_, dao_, principal_, bondDepo_);
    }

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
    function _setAddresses(
        address solace_,
        address xsolace_,
        address pool_,
        address dao_,
        address principal_,
        address bondDepo_
    ) internal {
        require(solace_ != address(0x0), "zero address solace");
        require(xsolace_ != address(0x0), "zero address xsolace");
        require(pool_ != address(0x0), "zero address pool");
        require(dao_ != address(0x0), "zero address dao");
        require(principal_ != address(0x0), "zero address principal");
        require(bondDepo_ != address(0x0), "zero address bond depo");
        solace = ISOLACE(solace_);
        xsolace = IxSOLACE(xsolace_);
        solace.approve(xsolace_, type(uint256).max);
        underwritingPool = pool_;
        dao = dao_;
        principal = IERC20(principal_);
        bondDepo = IBondDepository(bondDepo_);
        emit AddressesSet();
    }
}

