pragma solidity 0.5.4;


interface IDGTXToken {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}
