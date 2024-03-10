// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Governable.sol";
import "./interface/IVault.sol";
import "./interface/IRegistry.sol";
import "./interface/IProduct.sol";
import "./interface/IPolicyManager.sol";
import "./interface/IRiskManager.sol";


/**
 * @title RiskManager
 * @author solace.fi
 * @notice Calculates the acceptable risk, sellable cover, and capital requirements of Solace products and capital pool.
 *
 * The total amount of sellable coverage is proportional to the assets in the [**risk backing capital pool**](./Vault). The max cover is split amongst products in a weighting system. [**Governance**](/docs/protocol/governance) can change these weights and with it each product's sellable cover.
 *
 * The minimum capital requirement is proportional to the amount of cover sold to [active policies](./PolicyManager).
 *
 * Solace can use leverage to sell more cover than the available capital. The amount of leverage is stored as [`partialReservesFactor`](#partialreservesfactor) and is settable by [**governance**](/docs/protocol/governance).
 */
contract RiskManager is IRiskManager, Governable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // enumerable map product address to uint32 weight
    mapping(address => uint256) internal _productToIndex;
    mapping(uint256 => address) internal _indexToProduct;
    uint256 internal _productCount;
    mapping(address => ProductRiskParams) internal _productRiskParams;
    uint32 internal _weightSum;

    // Multiplier for minimum capital requirement in BPS.
    uint16 internal _partialReservesFactor;
    // 10k basis points (100%)
    uint16 internal constant MAX_BPS = 10000;

    // Registry
    IRegistry internal _registry;

    /**
     * @notice Constructs the RiskManager contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ Address of registry.
     */
    constructor(address governance_, address registry_) Governable(governance_) {
        require(registry_ != address(0x0), "zero address registry");
        _registry = IRegistry(registry_);
        _weightSum = type(uint32).max; // no div by zero
        _partialReservesFactor = MAX_BPS;
    }

    /***************************************
    MAX COVER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Given a request for coverage, determines if that risk is acceptable and if so at what price.
     * @param prod The product that wants to sell coverage.
     * @param currentCover If updating an existing policy's cover amount, the current cover amount, otherwise 0.
     * @param newCover The cover amount requested.
     * @return acceptable True if risk of the new cover is acceptable, false otherwise.
     * @return price The price in wei per 1e12 wei of coverage per block.
     */
    function assessRisk(address prod, uint256 currentCover, uint256 newCover) external view override returns (bool acceptable, uint24 price) {
        // must be a registered product
        if(_productToIndex[prod] == 0) return (false, type(uint24).max);
        // max cover checks
        uint256 mc = maxCover();
        ProductRiskParams storage params = _productRiskParams[prod];
        // must be less than maxCoverPerProduct
        mc = mc * params.weight / _weightSum;
        uint256 productActiveCoverAmount = IProduct(prod).activeCoverAmount();
        productActiveCoverAmount = productActiveCoverAmount + newCover - currentCover;
        if(productActiveCoverAmount > mc) return (false, params.price);
        // must be less than maxCoverPerPolicy
        mc = mc / params.divisor;
        if(newCover > mc) return (false, params.price);
        // risk is acceptable
        return (true, params.price);
    }

    /**
     * @notice The maximum amount of cover that Solace as a whole can sell.
     * @return cover The max amount of cover in wei.
     */
    function maxCover() public view override returns (uint256 cover) {
        return IVault(payable(_registry.vault())).totalAssets() * MAX_BPS / _partialReservesFactor;
    }

    /**
     * @notice The maximum amount of cover that a product can sell in total.
     * @param prod The product that wants to sell cover.
     * @return cover The max amount of cover in wei.
     */
    function maxCoverPerProduct(address prod) public view override returns (uint256 cover) {
        return maxCover() * _productRiskParams[prod].weight / _weightSum;
    }

    /**
     * @notice The amount of cover that a product can still sell.
     * @param prod The product that wants to sell cover.
     * @return cover The max amount of cover in wei.
     */
    function sellableCoverPerProduct(address prod) external view override returns (uint256 cover) {
        // max cover
        uint256 mc = maxCoverPerProduct(prod);
        // active cover
        uint256 ac = IProduct(prod).activeCoverAmount();
        // diff non underflow
        return (mc < ac)
          ? 0
          : (mc - ac);
    }

    /**
     * @notice The maximum amount of cover that a product can sell in a single policy.
     * @param prod The product that wants to sell cover.
     * @return cover The max amount of cover in wei.
     */
    function maxCoverPerPolicy(address prod) external view override returns (uint256 cover) {
        ProductRiskParams storage params = _productRiskParams[prod];
        require(params.weight > 0, "product inactive");
        return maxCover() * params.weight / (_weightSum * params.divisor);
    }

    /**
     * @notice Checks is an address is an active product.
     * @param prod The product to check.
     * @return status Returns true if the product is active.
     */
    function productIsActive(address prod) external view override returns (bool status) {
        return _productToIndex[prod] != 0;
    }

    /**
     * @notice Return the number of registered products.
     * @return count Number of products.
     */
    function numProducts() external view override returns (uint256 count) {
        return _productCount;
    }

    /**
     * @notice Return the product at an index.
     * @dev Enumerable `[1, numProducts]`.
     * @param index Index to query.
     * @return prod The product address.
     */
    function product(uint256 index) external view override returns (address prod) {
        return _indexToProduct[index];
    }

    /**
     * @notice Returns a product's risk parameters.
     * The product must be active.
     * @param prod The product to get parameters for.
     * @return weight The weighted allocation of this product vs other products.
     * @return price The price in wei per 1e12 wei of coverage per block.
     * @return divisor The max cover amount divisor for per policy. (maxCover / divisor = maxCoverPerPolicy).
     */
    function productRiskParams(address prod) external view override returns (uint32 weight, uint24 price, uint16 divisor) {
        ProductRiskParams storage params = _productRiskParams[prod];
        require(params.weight > 0, "product inactive");
        return (params.weight, params.price, params.divisor);
    }

    /**
     * @notice Returns the sum of weights.
     * @return sum WeightSum.
     */
    function weightSum() external view override returns (uint32 sum) {
        return _weightSum;
    }

    /***************************************
    MIN CAPITAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The minimum amount of capital required to safely cover all policies.
     * @return mcr The minimum capital requirement.
     */
    function minCapitalRequirement() external view override returns (uint256 mcr) {
        return IPolicyManager(_registry.policyManager()).activeCoverAmount() * _partialReservesFactor / MAX_BPS;
    }

    /**
     * @notice Multiplier for minimum capital requirement.
     * @return factor Partial reserves factor in BPS.
     */
    function partialReservesFactor() external view override returns (uint16 factor) {
        return _partialReservesFactor;
    }

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
     * @param divisor_ The max cover amount divisor for per policy. (maxCover / divisor = maxCoverPerPolicy).
     */
    function addProduct(address product_, uint32 weight_, uint24 price_, uint16 divisor_) external override onlyGovernance {
        require(product_ != address(0x0), "zero address product");
        require(weight_ > 0, "no weight");
        require(price_ > 0, "no price");
        require(divisor_ > 0, "1/0");
        uint256 index = _productToIndex[product_];
        if(index == 0) {
            // add new product
            uint32 weightSum_ = (_productCount == 0)
              ? weight_ // first product
              : (_weightSum + weight_);
            _weightSum = weightSum_;
            _productRiskParams[product_] = ProductRiskParams({
                weight: weight_,
                price: price_,
                divisor: divisor_
            });
            index = ++_productCount;
            _productToIndex[product_] = index;
            _indexToProduct[index] = product_;
        } else {
            // change params of existing product
            uint32 prevWeight = _productRiskParams[product_].weight;
            uint32 weightSum_ = _weightSum - prevWeight + weight_;
            _weightSum = weightSum_;
            _productRiskParams[product_] = ProductRiskParams({
                weight: weight_,
                price: price_,
                divisor: divisor_
            });
        }
        emit ProductParamsSet(product_, weight_, price_, divisor_);
    }

    /**
     * @notice Removes a product.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param product_ Address of the product to remove.
     */
    function removeProduct(address product_) external override onlyGovernance {
        uint256 index = _productToIndex[product_];
        // product wasn't added to begin with
        if(index == 0) return;
        // if not at the end copy down
        uint256 lastIndex = _productCount;
        if(index != lastIndex) {
            address lastProduct = _indexToProduct[lastIndex];
            _productToIndex[lastProduct] = index;
            _indexToProduct[index] = lastProduct;
        }
        // pop end of array
        delete _productToIndex[product_];
        delete _indexToProduct[lastIndex];
        uint256 newProductCount = _productCount - 1;
        _weightSum = (newProductCount == 0)
          ? type(uint32).max // no div by zero
          : (_weightSum - _productRiskParams[product_].weight);
        _productCount = newProductCount;
        delete _productRiskParams[product_];
        emit ProductParamsSet(product_, 0, 0, 0);
    }

    /**
     * @notice Sets the products and their parameters.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param products_ The products.
     * @param weights_ The product weights.
     * @param prices_ The product prices.
     * @param divisors_ The max cover per policy divisors.
     */
    function setProductParams(address[] calldata products_, uint32[] calldata weights_, uint24[] calldata prices_, uint16[] calldata divisors_) external override onlyGovernance {
        // check array lengths
        uint256 length = products_.length;
        require(length == weights_.length && length == prices_.length && length == divisors_.length, "length mismatch");
        // delete old products
        for(uint256 index = _productCount; index > 0; index--) {
            address product_ = _indexToProduct[index];
            delete _productToIndex[product_];
            delete _indexToProduct[index];
            delete _productRiskParams[product_];
            emit ProductParamsSet(product_, 0, 0, 0);
        }
        // add new products
        uint32 weightSum_ = 0;
        for(uint256 i = 0; i < length; i++) {
            address product_ = products_[i];
            uint32 weight_ = weights_[i];
            uint24 price_ = prices_[i];
            uint16 divisor_ = divisors_[i];
            require(product_ != address(0x0), "zero address product");
            require(weight_ > 0, "no weight");
            require(price_ > 0, "no price");
            require(divisor_ > 0, "1/0");
            require(_productToIndex[product_] == 0, "duplicate product");
            _productRiskParams[product_] = ProductRiskParams({
                weight: weight_,
                price: price_,
                divisor: divisor_
            });
            weightSum_ += weight_;
            _productToIndex[product_] = i+1;
            _indexToProduct[i+1] = product_;
            emit ProductParamsSet(product_, weight_, price_, divisor_);
        }
        _weightSum = (length == 0)
          ? type(uint32).max // no div by zero
          : weightSum_;
        _productCount = length;
    }

    /**
     * @notice Sets the partial reserves factor.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param partialReservesFactor_ New partial reserves factor in BPS.
     */
    function setPartialReservesFactor(uint16 partialReservesFactor_) external override onlyGovernance {
        _partialReservesFactor = partialReservesFactor_;
        emit PartialReservesFactorSet(partialReservesFactor_);
    }
}

