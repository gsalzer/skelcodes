// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IHegexoption {
    //custom functions in use
    function burnHegexoption(uint _id) external;
    function mintHegexoption(address _to) external returns (uint256);
    //IERC721 functions in use
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

