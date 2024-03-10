pragma solidity >=0.4.22 <0.6.0;

library SafeMath {
    function add(uint input1, uint input2) internal pure returns(uint result) {
        result = input1 + input2;
        require(result >= input1);
    }
    function sub(uint input1, uint input2) internal pure returns(uint result) {
        require(input2 <= input1);
        result = input1 - input2;
    }
    function mul(uint input1, uint input2) internal pure returns(uint result) {
        result = input1 * input2;
        require(input1 == 0 || result / input1 == input2);
    }
    function div(uint input1, uint input2) internal pure returns(uint result) {
        require(input2 > 0);
        result = input1 / input2;
    }
}

