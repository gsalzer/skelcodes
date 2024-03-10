//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../implements/0x02/CIPStaking.sol";

abstract contract CHCCollect is CIPStaking {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function burn_coll_want_only(uint256 n) public {
        require(rate == 1e18);
        recv_coll(n);
        send_coll(n);
    }

    function burn_coll_bond_only(uint256 n) public {
        require(rate == 0);
        recv_coll(n);
        send_bond(n);
    }
}

