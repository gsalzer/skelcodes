pragma solidity =0.6.6;

import "./ERC1155.sol";

abstract contract ERC1155Enumerable is ERC1155 {
    mapping(uint256 => bool) public tokenIdExists;
    uint256[] public tokenIds;

    function trackTokenId(uint256 id) internal {
        if (!tokenIdExists[id]) {
            tokenIds.push(id);
            tokenIdExists[id] = true;
        }
    }

    function _mintEnumerable(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        trackTokenId(id);

        ERC1155._mint(account, id, amount, data);
    }

    function _mintBatchEnumerable(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            trackTokenId(ids[i]);
        }

        ERC1155._mintBatch(to, ids, amounts, data);
    }

    function balanceOfAll(address owner)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory balances = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            balances[i] = ERC1155.balanceOf(owner, tokenIds[i]);
        }
        return (balances, tokenIds);
    }
}

