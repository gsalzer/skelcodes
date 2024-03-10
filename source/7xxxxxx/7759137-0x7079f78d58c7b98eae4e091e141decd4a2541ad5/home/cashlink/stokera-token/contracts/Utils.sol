pragma solidity ^0.5.3;

library Utils {
    function isContract(address addr) external view returns (bool) {
        if (addr == address(0)) {
            return false;
        }
        uint32 size;
        assembly { size := extcodesize(addr) }
        return (size > 0);
    }
}

