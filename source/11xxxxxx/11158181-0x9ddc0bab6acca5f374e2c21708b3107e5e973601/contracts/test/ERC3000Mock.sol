/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "erc3k/contracts/IERC3000.sol";

import "@aragon/govern-contract-utils/contracts/erc165/ERC165.sol";

contract ERC3000Mock is IERC3000, ERC165 {
    function schedule(ERC3000Data.Container memory) override public returns (bytes32) { }

    function execute(ERC3000Data.Container memory) override public returns (bytes32, bytes[] memory) { }

    function challenge(ERC3000Data.Container memory, bytes memory) override public returns (uint256 resolverId) { }

    function resolve(ERC3000Data.Container memory, uint256) override public returns (bytes32, bytes[] memory) { }

    function veto(bytes32, bytes memory) override public { }

    function configure(ERC3000Data.Config memory) override public returns (bytes32) { }

    function interfaceID() public pure returns (bytes4) {
        return ERC3000_INTERFACE_ID;
    }

    function supportsInterface(bytes4 interfaceId) override public view returns (bool) {
        return interfaceId == ERC3000_INTERFACE_ID;
    }
}

