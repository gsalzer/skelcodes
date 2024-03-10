// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IChildERC20} from "./interfaces/IChildERC20.sol";

/*
 * @dev One way token bridge from Polygon to Ethereum
 */
contract OneWayBridge {
    using SafeERC20 for IERC20;

    modifier onlySender() {
        require(isSender, "Must be sender");
        _;
    }

    modifier onlyReceiver() {
        require(!isSender, "Must be receiver");
        _;
    }
    
    bool public isSender;
    address public destination;
    bool public initialized;

    function initialize(bool _isSender, address _destination) external {
        require(initialized == false, "Already initialized");
        isSender = _isSender;
        destination = _destination;
        initialized = true;
    }
    
    function transferAll(address _token) onlyReceiver external {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(destination, amount);
    }

    function withdrawAll(address _token) onlySender external {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IChildERC20(_token).withdraw(amount);
    }
}

