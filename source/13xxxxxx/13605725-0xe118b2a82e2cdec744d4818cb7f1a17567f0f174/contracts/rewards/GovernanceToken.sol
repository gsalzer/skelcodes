// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    OwnableUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import {
    Initializable
} from "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import {
    ERC20UpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract GovernanceToken is
    Initializable,
    OwnableUpgradeSafe,
    ERC20UpgradeSafe
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    address public proxyAdmin;

    /* ------------------------------- */

    event AdminChanged(address);

    modifier onlyAdmin() {
        require(msg.sender == proxyAdmin, "ADMIN_ONLY");
        _;
    }

    receive() external payable {
        revert("DONT_SEND_ETHER");
    }

    function initialize(address adminAddress, uint256 totalSupply)
        external
        initializer
    {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained("APY Governance Token", "APY");

        // initialize impl-specific storage
        setAdminAddress(adminAddress);

        _mint(msg.sender, totalSupply);
    }

    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyAdmin {}

    function setAdminAddress(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "INVALID_ADMIN");
        proxyAdmin = adminAddress;
        emit AdminChanged(adminAddress);
    }
}

