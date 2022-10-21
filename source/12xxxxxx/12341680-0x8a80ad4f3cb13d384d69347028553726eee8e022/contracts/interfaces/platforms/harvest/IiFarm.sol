pragma solidity 0.7.6;

import "contracts/interfaces/ERC20.sol";

interface iFarm is ERC20 {
    function getPricePerFullShare() external view returns (uint256);
}

