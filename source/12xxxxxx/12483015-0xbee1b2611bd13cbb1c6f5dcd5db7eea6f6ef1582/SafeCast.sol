pragma solidity ^0.5.0;

library SafeCast {
    /**
     * Cast unsigned a to signed a.
     */
    function castToInt(uint a) internal pure returns(int) {
        assert(a < (1 << 255));
        return int(a);
    }

    /**
     * Cast signed a to unsigned a.
     */
    function castToUint(int a) internal pure returns(uint) {
        assert(a >= 0);
        return uint(a);
    }
}

