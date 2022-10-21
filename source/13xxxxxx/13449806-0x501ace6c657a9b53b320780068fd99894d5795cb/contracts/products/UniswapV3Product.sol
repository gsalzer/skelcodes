// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../interface/UniswapV3/IUniswapV3Pool.sol";
import "../interface/UniswapV3/IUniswapV3Factory.sol";

import "./BaseProduct.sol";


/**
 * @title UniswapV3Product
 * @author solace.fi
 * @notice The **UniswapV3Product** can be used to purchase coverage for **UniswapV3 LP** positions.
 */
contract UniswapV3Product is BaseProduct {

    IUniswapV3Factory internal _uniV3Factory;

    /**
      * @notice Constructs the UniswapV3Product.
      * @param governance_ The address of the [governor](/docs/protocol/governance).
      * @param policyManager_ The [`PolicyManager`](../PolicyManager) contract.
      * @param registry_ The [`Registry`](../Registry) contract.
      * @param uniV3Factory_ The UniswapV3Product Factory.
      * @param minPeriod_ The minimum policy period in blocks to purchase a **policy**.
      * @param maxPeriod_ The maximum policy period in blocks to purchase a **policy**.
     */
    constructor (
        address governance_,
        IPolicyManager policyManager_,
        IRegistry registry_,
        address uniV3Factory_,
        uint40 minPeriod_,
        uint40 maxPeriod_
    ) BaseProduct(
        governance_,
        policyManager_,
        registry_,
        uniV3Factory_,
        minPeriod_,
        maxPeriod_,
        "Solace.fi-UniswapV3Product",
        "1"
    ) {
        _uniV3Factory = IUniswapV3Factory(uniV3Factory_);
        _SUBMIT_CLAIM_TYPEHASH = keccak256("UniswapV3ProductSubmitClaim(uint256 policyID,address claimant,uint256 amountOut,uint256 deadline)");
        _productName = "UniswapV3";
    }

    /**
     * @notice Uniswap V2 Factory.
     * @return uniV3Factory_ The factory.
     */
    function uniV2Factory() external view returns (address uniV3Factory_) {
        return address(_uniV3Factory);
    }

    /**
     * @notice Determines if the byte encoded description of a position(s) is valid.
     * The description will only make sense in context of the product.
     * @dev This function should be overwritten in inheriting Product contracts.
     * If invalid, return false if possible. Reverting is also acceptable.
     * @param positionDescription The description to validate.
     * @return isValid True if is valid.
     */
    function isValidPositionDescription(bytes memory positionDescription) public view virtual override returns (bool isValid) {
        // check length
        // solhint-disable-next-line var-name-mixedcase
        uint256 ADDRESS_SIZE = 20;
        // must be concatenation of one or more addresses
        if(positionDescription.length == 0 || positionDescription.length % ADDRESS_SIZE != 0) return false;
        // check all addresses in list
        for(uint256 offset = 0; offset < positionDescription.length; offset += ADDRESS_SIZE) {
            // get next address
            address positionContract;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                positionContract := div(mload(add(add(positionDescription, 0x20), offset)), 0x1000000000000000000000000)
            }
            // must be UniswapV3 Pool
            IUniswapV3Pool uniswapV3Pool = IUniswapV3Pool(positionContract);
            address pool = _uniV3Factory.getPool(uniswapV3Pool.token0(), uniswapV3Pool.token1(), uniswapV3Pool.fee());
            if (pool != address(uniswapV3Pool)) return false;
        }
        return true;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Changes the covered platform.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @dev Use this if the the protocol changes their registry but keeps the children contracts.
     * A new version of the protocol will likely require a new Product.
     * @param uniV3Factory_ The new Address Provider.
     */
    function setCoveredPlatform(address uniV3Factory_) public override {
        super.setCoveredPlatform(uniV3Factory_);
        _uniV3Factory = IUniswapV3Factory(uniV3Factory_);
    }
}

