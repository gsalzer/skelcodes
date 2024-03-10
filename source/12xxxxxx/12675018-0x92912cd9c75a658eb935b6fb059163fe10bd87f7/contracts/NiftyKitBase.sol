//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NiftyKitBase is Ownable, AccessControl {
    using SafeMath for uint256;
    uint256 internal _commission; // parts per 10,000
    address internal _treasury;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    function setCommission(uint256 commission) public onlyOwner {
        _commission = commission;
    }

    function setTreasury(address treasury) public onlyOwner {
        _treasury = treasury;
    }
}

