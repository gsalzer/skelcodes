// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface IChainRunners is IERC721Enumerable {
    function renderingContractAddress() external view returns (address);
}
