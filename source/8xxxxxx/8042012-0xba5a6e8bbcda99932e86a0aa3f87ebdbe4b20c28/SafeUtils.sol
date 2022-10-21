pragma solidity 0.5.3;

contract SafeUtils {
    function toUint48(uint val) internal pure returns (uint48) {
        uint48 ret = uint48(val);
        require(ret == val, "toUint48 lost some value.");
        return ret;
    }
    function toUint32(uint val) internal pure returns (uint32) {
        uint32 ret = uint32(val);
        require(ret == val, "toUint32 lost some value.");
        return ret;
    }
    function toUint16(uint val) internal pure returns (uint16) {
        uint16 ret = uint16(val);
        require(ret == val, "toUint16 lost some value.");
        return ret;
    }
    function toUint8(uint val) internal pure returns (uint8) {
        uint8 ret = uint8(val);
        require(ret == val, "toUint8 lost some value.");
        return ret;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Bad safe math multiplication.");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "Attempt to divide by zero in safe math.");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Bad subtraction in safe math.");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Bad addition in safe math.");

        return c;
    }
}
