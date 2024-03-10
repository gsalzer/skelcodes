pragma solidity ^0.4.24;

interface IERC20ImplUpgradeable {
    function getImplAddress() view external returns(address);
    function getMintBurnAddress() view external returns(address);
    function isImplAddress(address) view external returns(bool);
}
