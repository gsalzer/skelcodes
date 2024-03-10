// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // solhint-disable-line compiler-version
pragma abicoder v2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Kernel } from "../proxy/Kernel.sol";

abstract contract AirdropRegistryStorage is Kernel {
    struct AirdropInfo {
        address token;
        address beneficiary;
        uint256 amount;
        uint256 nonce;
        uint256 chainID;
    }

    //////////////////////////////////////////
    //
    // AirdropRegistry
    //
    //////////////////////////////////////////

    address public tokenWallet;

    // airdrop info hash => boolean
    mapping(bytes32 => bool) public claimed;
}

