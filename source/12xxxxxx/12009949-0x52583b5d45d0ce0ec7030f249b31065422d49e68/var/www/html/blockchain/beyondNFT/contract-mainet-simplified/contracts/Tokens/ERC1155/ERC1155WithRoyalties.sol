// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';

import '../ERCWithRoyalties/ERCWithRoyalties.sol';

abstract contract ERC1155WithRoyalties is ERCWithRoyalties {
    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) public claimableRoyalties;

    function __ERC1155WithRoyalties_init() internal initializer {
        __ERCWithRoyalties_init();
    }

    /**
     * @dev returns how much royalties are required for `id`
     *
     * @return uint256
     */
    function getRoyalties(uint256 id) public view override returns (uint256) {
        return _royalties[id].value;
    }

    /**
     * @dev this is called by other contracts to send royalties for a given id
     *
     * @return "bytes4(keccak256('onRoyaltiesReceived(uint256)'))"
     */
    function onRoyaltiesReceived(uint256 id)
        external
        payable
        override
        returns (bytes4)
    {
        // this means that a marketplace send royalties for id
        // store the value to id recipient
        address recipient = _royalties[id].recipient;
        require(recipient != address(0), 'No royalties for id');

        claimableRoyalties[recipient] = claimableRoyalties[recipient].add(
            msg.value
        );

        emit RoyaltiesReceived(id, recipient, msg.value);

        return this.onRoyaltiesReceived.selector;
    }

    /**
     * @dev allow to claim royalties for `recipient`
     */
    function claimRoyalties(address recipient) external {
        uint256 value = claimableRoyalties[recipient];
        require(value > 0, 'Royalties: Nothing to claim');

        // set 0 before calling transfer to protect against re-entrency
        claimableRoyalties[recipient] = 0;

        (bool sent, ) = payable(recipient).call{value: value}('');

        require(sent, 'Failed to send Ether');
    }
}

