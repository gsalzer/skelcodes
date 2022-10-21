/* SPDX-License-Identifier: BUSL-1.1 */
/* Copyright © 2021 Fragcolor Pte. Ltd. */

pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

contract RoyaltiesReceiver {
    using SafeERC20 for IERC20;

    uint256 public constant FRAGMENT_ROYALTIES_BPS = 1000;

    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    bytes32 private constant SLOT_royaltiesRecipient =
        bytes32(
            uint256(
                keccak256("fragments.RoyaltiesReceiver.royaltiesRecipient")
            ) - 1
        );
    bytes32 private constant SLOT_royaltiesBps =
        bytes32(
            uint256(keccak256("fragments.RoyaltiesReceiver.royaltiesBps")) - 1
        );

    function getRoyaltiesRecipient()
        private
        view
        returns (address payable dest)
    {
        bytes32 slot = SLOT_royaltiesRecipient;
        assembly {
            dest := sload(slot)
        }
    }

    function getRoyaltiesBps() private view returns (uint256 bps) {
        bytes32 slot = SLOT_royaltiesBps;
        assembly {
            bps := sload(slot)
        }
    }

    function setupRoyalties(
        address payable royaltiesRecipient,
        uint256 royaltiesBps
    ) internal {
        bytes32 slot = SLOT_royaltiesRecipient;
        assembly {
            sstore(slot, royaltiesRecipient)
        }

        slot = SLOT_royaltiesBps;
        assembly {
            sstore(slot, royaltiesBps)
        }
    }

    function _supportsInterface(bytes4 interfaceId)
        internal
        pure
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function getRoyalties(uint256)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        recipients = new address payable[](1);
        recipients[0] = getRoyaltiesRecipient();
        bps = new uint256[](1);
        bps[0] = getRoyaltiesBps();
        return (recipients, bps);
    }

    function getFeeRecipients(uint256)
        external
        view
        returns (address payable[] memory recipients)
    {
        recipients = new address payable[](1);
        recipients[0] = getRoyaltiesRecipient();
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint256[] memory bps) {
        bps = new uint256[](1);
        bps[0] = getRoyaltiesBps();
        return bps;
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        returns (address, uint256)
    {
        return (getRoyaltiesRecipient(), (value * getRoyaltiesBps()) / 10000);
    }
}

