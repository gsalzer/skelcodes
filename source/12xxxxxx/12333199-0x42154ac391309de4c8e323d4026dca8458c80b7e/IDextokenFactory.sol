pragma solidity 0.5.17;


interface IDextokenFactory {
    function getFeePool() external view returns (address);
}
