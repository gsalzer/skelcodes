/* SPDX-License-Identifier: BUSL-1.1 */
/* Copyright © 2021 Fragcolor Pte. Ltd. */

pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IFragment.sol";
import "./IEntity.sol";

contract Vault is Initializable {
    using SafeERC20 for IERC20;

    bytes32 private constant SLOT_fragmentsLibrary =
        bytes32(uint256(keccak256("fragments.vault.fragmentsLibrary")) - 1);
    bytes32 private constant SLOT_entityContract =
        bytes32(uint256(keccak256("fragments.vault.entityContract")) - 1);

    function fragmentOwner() public view virtual returns (address) {
        address entityContract;
        bytes32 slot = SLOT_entityContract;
        assembly {
            entityContract := sload(slot)
        }
        IEntity e = IEntity(entityContract);
        return e.fragmentOwner();
    }

    function foundation() public view virtual returns (address) {
        address fragmentsLibrary;
        bytes32 slot = SLOT_fragmentsLibrary;
        assembly {
            fragmentsLibrary := sload(slot)
        }
        IFragment t = IFragment(fragmentsLibrary);
        return t.owner();
    }

    constructor() {}

    function deposit() public payable {}

    function bootstrap(address entityContract, address fragmentsLibrary)
        public
        initializer
    {
        bytes32 slot = SLOT_entityContract;
        assembly {
            sstore(slot, entityContract)
        }

        slot = SLOT_fragmentsLibrary;
        assembly {
            sstore(slot, fragmentsLibrary)
        }
    }

    function claimERC20(address tokenAddress) public {
        IERC20 erc20 = IERC20(tokenAddress);
        uint256 balance = erc20.balanceOf(address(this));
        assert(balance > 0);
        // 80% to the fragmentOwner
        uint256 royalties = (balance * 8000) / 10000;
        erc20.safeTransfer(fragmentOwner(), royalties);
        // transfer rest to vault owner (aka fragment contract owner/fragments foundation)
        balance -= royalties;
        erc20.safeTransfer(foundation(), balance);
    }

    function claimETH() public {
        uint256 balance = address(this).balance;
        assert(balance > 0);
        // 80% to the fragmentOwner
        uint256 royalties = (balance * 8000) / 10000;
        payable(fragmentOwner()).transfer(royalties);
        // transfer rest to vault owner (aka fragment contract owner/fragments foundation)
        balance -= royalties;
        payable(foundation()).transfer(balance);
    }
}

