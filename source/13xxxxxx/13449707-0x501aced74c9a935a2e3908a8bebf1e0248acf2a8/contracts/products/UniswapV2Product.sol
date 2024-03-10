// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../interface/UniswapV2/IUniLPToken.sol";
import "../interface/UniswapV2/IUniV2Factory.sol";

import "./BaseProduct.sol";


/**
 * @title UniswapV2Product
 * @author solace.fi
 * @notice The **UniswapV2Product** can be used to purchase coverage for **UniswapV2 LP** positions.
 */
contract UniswapV2Product is BaseProduct {

    IUniV2Factory internal _uniV2Factory;

    /**
      * @notice Constructs the UniswapV2Product.
      * @param governance_ The address of the [governor](/docs/protocol/governance).
      * @param policyManager_ The [`PolicyManager`](../PolicyManager) contract.
      * @param registry_ The [`Registry`](../Registry) contract.
      * @param uniV2Factory_ The UniswapV2Product Factory.
      * @param minPeriod_ The minimum policy period in blocks to purchase a **policy**.
      * @param maxPeriod_ The maximum policy period in blocks to purchase a **policy**.
     */
    constructor (
        address governance_,
        IPolicyManager policyManager_,
        IRegistry registry_,
        address uniV2Factory_,
        uint40 minPeriod_,
        uint40 maxPeriod_
    ) BaseProduct(
        governance_,
        policyManager_,
        registry_,
        uniV2Factory_,
        minPeriod_,
        maxPeriod_,
        "Solace.fi-UniswapV2Product",
        "1"
    ) {
        _uniV2Factory = IUniV2Factory(uniV2Factory_);
        _SUBMIT_CLAIM_TYPEHASH = keccak256("UniswapV2ProductSubmitClaim(uint256 policyID,address claimant,uint256 amountOut,uint256 deadline)");
        _productName = "UniswapV2";
    }

    /**
     * @notice Uniswap V2 Factory.
     * @return uniV2Factory_ The factory.
     */
    function uniV2Factory() external view returns (address uniV2Factory_) {
        return address(_uniV2Factory);
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
            // must be UniV2 LP Token
            IUniLPToken uniToken = IUniLPToken(positionContract);
            address pair = _uniV2Factory.getPair(uniToken.token0(), uniToken.token1());
            if (pair != address(uniToken)) return false;
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
     * @param uniV2Factory_ The new Address Provider.
     */
    function setCoveredPlatform(address uniV2Factory_) public override {
        super.setCoveredPlatform(uniV2Factory_);
        _uniV2Factory = IUniV2Factory(uniV2Factory_);
    }
}

