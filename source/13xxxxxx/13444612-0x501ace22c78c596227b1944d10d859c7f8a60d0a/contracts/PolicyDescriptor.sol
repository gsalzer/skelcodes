// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./interface/IPolicyDescriptor.sol";
import "./interface/IPolicyManager.sol";
import "./interface/IProduct.sol";

/**
 * @title PolicyDescriptor
 * @author solace.fi
 * @notice Produces a string containing the data URI for a JSON metadata string of a policy.
 * It is inspired from Uniswap V3 [`NonfungibleTokenPositionDescriptor`](https://docs.uniswap.org/protocol/reference/periphery/NonfungibleTokenPositionDescriptor).
 */
contract PolicyDescriptor is IPolicyDescriptor {
    /**
     * @notice Describes a policy.
     * @param policyManager The policy manager to retrieve policy info to produce URI description.
     * @param policyID The ID of the policy for which to produce a description.
     * @return description The URI of the ERC721-compliant metadata.
     */
    function tokenURI(IPolicyManager policyManager, uint256 policyID) external view override returns (string memory description) {
        address product = policyManager.getPolicyProduct(policyID);
        string memory productName = IProduct(product).name();
        return string(abi.encodePacked("This is a Solace Finance policy that covers a ", productName, " position"));
    }
}

