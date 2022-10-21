pragma solidity 0.5.13;

interface CurveInterface {

    function calc(uint) external pure returns (uint);

}


contract SqrtCurve is CurveInterface {


    function calc(uint256 _value) external pure returns (uint256 sqrt) {
        uint value = _value * 1 ether;
        uint z = (value + 1) / 2;
        sqrt = value;
        while (z < sqrt) {
            sqrt = z;
            z = (value / z + z) / 2;
        }
    }
}
