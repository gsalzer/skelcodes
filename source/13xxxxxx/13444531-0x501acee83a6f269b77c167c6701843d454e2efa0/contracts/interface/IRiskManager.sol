// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IRiskManager
 * @author solace.fi
 * @notice Calculates the acceptable risk, sellable cover, and capital requirements of Solace products and capital pool.
 *
 * The total amount of sellable coverage is proportional to the assets in the [**risk backing capital pool**](../Vault). The max cover is split amongst products in a weighting system. [**Governance**](/docs/protocol/governance). can change these weights and with it each product's sellable cover.
 *
 * The minimum capital requirement is proportional to the amount of cover sold to [active policies](../PolicyManager).
 *
 * Solace can use leverage to sell more cover than the available capital. The amount of leverage is stored as [`partialReservesFactor`](#partialreservesfactor) and is settable by [**governance**](/docs/protocol/governance).
 */
interface IRiskManager {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a product's risk parameters are set.
    /// Includes adding and removing products.
    event ProductParamsSet(address product, uint32 weight, uint24 price, uint16 divisor);
    /// @notice Emitted when the partial reserves factor is set.
    event PartialReservesFactorSet(uint16 partialReservesFactor);

    /***************************************
    MAX COVER VIEW FUNCTIONS
    ***************************************/

    /// @notice Struct for a product's risk parameters.
    struct ProductRiskParams {
        uint32 weight;  // The weighted allocation of this product vs other products.
        uint24 price;   // The price in wei per 1e12 wei of coverage per block.
        uint16 divisor; // The max cover per policy divisor. (maxCoverPerProduct / divisor = maxCoverPerPolicy)
    }

    /**
     * @notice Given a request for coverage, determines if that risk is acceptable and if so at what price.
     * @param product The product that wants to sell coverage.
     * @param currentCover If updating an existing policy's cover amount, the current cover amount, otherwise 0.
     * @param newCover The cover amount requested.
     * @return acceptable True if risk of the new cover is acceptable, false otherwise.
     * @return price The price in wei per 1e12 wei of coverage per block.
     */
    function assessRisk(address product, uint256 currentCover, uint256 newCover) external view returns (bool acceptable, uint24 price);

    /**
     * @notice The maximum amount of cover that Solace as a whole can sell.
     * @return cover The max amount of cover in wei.
     */
    function maxCover() external view returns (uint256 cover);

    /**
     * @notice The maximum amount of cover that a product can sell in total.
     * @param prod The product that wants to sell cover.
     * @return cover The max amount of cover in wei.
     */
    function maxCoverPerProduct(address prod) external view returns (uint256 cover);

    /**
     * @notice The amount of cover that a product can still sell.
     * @param prod The product that wants to sell cover.
     * @return cover The max amount of cover in wei.
     */
    function sellableCoverPerProduct(address prod) external view returns (uint256 cover);

    /**
     * @notice The maximum amount of cover that a product can sell in a single policy.
     * @param prod The product that wants to sell cover.
     * @return cover The max amount of cover in wei.
     */
    function maxCoverPerPolicy(address prod) external view returns (uint256 cover);

    /**
     * @notice Checks is an address is an active product.
     * @param prod The product to check.
     * @return status True if the product is active.
     */
    function productIsActive(address prod) external view returns (bool status);

    /**
     * @notice Return the number of registered products.
     * @return count Number of products.
     */
    function numProducts() external view returns (uint256 count);

    /**
     * @notice Return the product at an index.
     * @dev Enumerable `[1, numProducts]`.
     * @param index Index to query.
     * @return prod The product address.
     */
    function product(uint256 index) external view returns (address prod);

    /**
     * @notice Returns a product's risk parameters.
     * The product must be active.
     * @param prod The product to get parameters for.
     * @return weight The weighted allocation of this product vs other products.
     * @return price The price in wei per 1e12 wei of coverage per block.
     * @return divisor The max cover per policy divisor.
     */
    function productRiskParams(address prod) external view returns (uint32 weight, uint24 price, uint16 divisor);

    /**
     * @notice Returns the sum of weights.
     * @return sum WeightSum.
     */
    function weightSum() external view returns (uint32 sum);

    /***************************************
    MIN CAPITAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The minimum amount of capital required to safely cover all policies.
     * @return mcr The minimum capital requirement.
     */
    function minCapitalRequirement() external view returns (uint256 mcr);

    /**
     * @notice Multiplier for minimum capital requirement.
     * @return factor Partial reserves factor in BPS.
     */
    function partialReservesFactor() external view returns (uint16 factor);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a product.
     * If the product is already added, sets its parameters.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param product_ Address of the product.
     * @param weight_ The products weight.
     * @param price_ The products price in wei per 1e12 wei of coverage per block.
     * @param divisor_ The max cover per policy divisor.
     */
    function addProduct(address product_, uint32 weight_, uint24 price_, uint16 divisor_) external;

    /**
     * @notice Removes a product.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param product_ Address of the product to remove.
     */
    function removeProduct(address product_) external;

    /**
     * @notice Sets the products and their parameters.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param products_ The products.
     * @param weights_ The product weights.
     * @param prices_ The product prices.
     * @param divisors_ The max cover per policy divisors.
     */
    function setProductParams(address[] calldata products_, uint32[] calldata weights_, uint24[] calldata prices_, uint16[] calldata divisors_) external;

    /**
     * @notice Sets the partial reserves factor.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param partialReservesFactor_ New partial reserves factor in BPS.
     */
    function setPartialReservesFactor(uint16 partialReservesFactor_) external;
}

