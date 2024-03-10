// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../interface/SushiSwap/ISushiLPToken.sol";
import "../interface/SushiSwap/ISushiV2Factory.sol";

import "./BaseProduct.sol";


/**
 * @title SushiswapProduct
 * @author solace.fi
 * @notice The **SushiswapProduct** can be used to purchase coverage for **Sushiswap LP** positions.
 */
contract SushiswapProduct is BaseProduct {

    ISushiV2Factory internal _sushiV2Factory;

    /**
      * @notice Constructs the SushiswapProduct.
      * @param governance_ The address of the [governor](/docs/protocol/governance).
      * @param policyManager_ The [`PolicyManager`](../PolicyManager) contract.
      * @param registry_ The [`Registry`](../Registry) contract.
      * @param sushiV2Factory_ The Sushiswap Factory.
      * @param minPeriod_ The minimum policy period in blocks to purchase a **policy**.
      * @param maxPeriod_ The maximum policy period in blocks to purchase a **policy**.
     */
    constructor (
        address governance_,
        IPolicyManager policyManager_,
        IRegistry registry_,
        address sushiV2Factory_,
        uint40 minPeriod_,
        uint40 maxPeriod_
    ) BaseProduct(
        governance_,
        policyManager_,
        registry_,
        sushiV2Factory_,
        minPeriod_,
        maxPeriod_,
        "Solace.fi-SushiswapProduct",
        "1"
    ) {
        _sushiV2Factory = ISushiV2Factory(sushiV2Factory_);
        _SUBMIT_CLAIM_TYPEHASH = keccak256("SushiswapProductSubmitClaim(uint256 policyID,address claimant,uint256 amountOut,uint256 deadline)");
        _productName = "Sushiswap";
    }

    /**
     * @notice Sushiswap V2 Factory.
     * @return sushiV2Factory_ The factory.
     */
    function sushiV2Factory() external view returns (address sushiV2Factory_) {
        return address(_sushiV2Factory);
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
            // must be Sushi LP Token
            ISushiLPToken slpToken = ISushiLPToken(positionContract);
            address pair = _sushiV2Factory.getPair(slpToken.token0(), slpToken.token1());
            if (pair != address(slpToken)) return false;
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
     * @param sushiV2Factory_ The new Address Provider.
     */
    function setCoveredPlatform(address sushiV2Factory_) public override {
        super.setCoveredPlatform(sushiV2Factory_);
        _sushiV2Factory = ISushiV2Factory(sushiV2Factory_);
    }
}

