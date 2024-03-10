pragma solidity ^0.5.7;

/**
 * @title ERC20 interface without bool returns
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external;

    function approve(address spender, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function burn(uint256 value) external;

    function burnFrom(address from, uint256 value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

