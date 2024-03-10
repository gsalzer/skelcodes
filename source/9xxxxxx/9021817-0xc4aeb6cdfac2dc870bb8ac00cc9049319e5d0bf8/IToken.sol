pragma solidity 0.4.25;


/// @title IToken
/// @dev Interface for interaction with the TMV token contract.
interface IToken {
    function burnLogic(address from, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function mint(address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}


