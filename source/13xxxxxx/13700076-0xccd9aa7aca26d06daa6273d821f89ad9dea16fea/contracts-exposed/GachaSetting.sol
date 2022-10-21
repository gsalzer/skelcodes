// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/GachaSetting.sol";

contract XGachaSetting is GachaSetting {
    constructor() {}

    function x_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}

