// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {TvlManager} from "contracts/tvl/TvlManager.sol";

contract TvlManagerFactory {
    function create(address addressRegistry) external returns (address) {
        TvlManager tvlManager = new TvlManager(addressRegistry);
        return address(tvlManager);
    }
}

