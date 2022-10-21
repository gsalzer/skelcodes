// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../interface/Compound/IComptroller.sol";
import "../interface/Compound/ICToken.sol";
import "./BaseProduct.sol";


/**
 * @title CompoundProduct
 * @author solace.fi
 * @notice The **CompoundProduct** can be used to purchase coverage for **Compound** positions.
 */
contract CompoundProduct is BaseProduct {

    // IComptroller.
    IComptroller internal _comptroller;

    /**
      * @notice Constructs the CompoundProduct.
      * @param governance_ The address of the [governor](/docs/protocol/governance).
      * @param policyManager_ The [`PolicyManager`](../PolicyManager) contract.
      * @param registry_ The [`Registry`](../Registry) contract.
      * @param comptroller_ The Compound Comptroller.
      * @param minPeriod_ The minimum policy period in blocks to purchase a **policy**.
      * @param maxPeriod_ The maximum policy period in blocks to purchase a **policy**.
     */
    constructor (
        address governance_,
        IPolicyManager policyManager_,
        IRegistry registry_,
        address comptroller_,
        uint40 minPeriod_,
        uint40 maxPeriod_
    ) BaseProduct(
        governance_,
        policyManager_,
        registry_,
        comptroller_,
        minPeriod_,
        maxPeriod_,
        "Solace.fi-CompoundProduct",
        "1"
    ) {
        _comptroller = IComptroller(comptroller_);
        _SUBMIT_CLAIM_TYPEHASH = keccak256("CompoundProductSubmitClaim(uint256 policyID,address claimant,uint256 amountOut,uint256 deadline)");
        _productName = "Compound";
    }

    /**
     * @notice Compound's Comptroller.
     * @return comptroller_ The comptroller.
     */
    function comptroller() external view returns (address comptroller_) {
        return address(_comptroller);
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
                // get 20 bytes starting at offset+32
                positionContract := shr(0x60, mload(add(add(positionDescription, 0x20), offset)))
            }
            // must be a cToken
            (bool isListed, , ) = _comptroller.markets(positionContract);
            if(!isListed) return false;
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
     * @param comptroller_ The new Comptroller.
     */
    function setCoveredPlatform(address comptroller_) public override {
        super.setCoveredPlatform(comptroller_);
        _comptroller = IComptroller(comptroller_);
    }
}

