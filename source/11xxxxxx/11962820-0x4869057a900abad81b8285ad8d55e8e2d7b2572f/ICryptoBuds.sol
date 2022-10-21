//SPDX-License-Identifier: UNLICENSED
import "./IERC721Enumerable.sol";
pragma solidity ^0.7.0;

interface ICryptoBuds is IERC721Enumerable {
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}
