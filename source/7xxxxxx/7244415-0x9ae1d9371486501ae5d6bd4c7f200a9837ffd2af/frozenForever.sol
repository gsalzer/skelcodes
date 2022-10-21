pragma solidity >=0.4.24;

contract frozenForever {
    string public  name = "DEFLAT FROZEN FOREVER";
    string public symbol = "DEFT";
    string public comment = 'this contract do nothing';

    function () payable external {        
       //this function has nothing 		
    }
}
