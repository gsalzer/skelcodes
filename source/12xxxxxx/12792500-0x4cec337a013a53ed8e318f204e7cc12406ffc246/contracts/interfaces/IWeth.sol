pragma solidity ^0.6.0;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}
