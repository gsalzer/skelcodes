// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Erc20Allocation} from "contracts/tvl/Erc20Allocation.sol";

contract Erc20AllocationFactory {
    function create(address addressRegistry) external returns (address) {
        Erc20Allocation erc20Allocation = new Erc20Allocation(addressRegistry);
        return address(erc20Allocation);
    }
}

