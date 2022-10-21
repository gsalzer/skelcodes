// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "diamond-libraries/contracts/libraries/LibDiamond.sol";
import "diamond-libraries/contracts/libraries/LibOwnership.sol";
import "diamond-libraries/contracts/interfaces/IDiamondLoupe.sol";
import "diamond-libraries/contracts/interfaces/IERC165.sol";
import "diamond-libraries/contracts/interfaces/IERC173.sol";

contract ReignDiamond {
    constructor(IDiamondCut.FacetCut[] memory _diamondCut, address _owner)
        payable
    {
        require(_owner != address(0), "owner must not be 0x0");

        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        LibOwnership.setContractOwner(_owner);

        LibDiamondStorage.DiamondStorage storage ds =
            LibDiamondStorage.diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds =
            LibDiamondStorage.diamondStorage();

        address facet = address(bytes20(ds.facets[msg.sig].facetAddress));
        require(facet != address(0), "Diamond: Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}

