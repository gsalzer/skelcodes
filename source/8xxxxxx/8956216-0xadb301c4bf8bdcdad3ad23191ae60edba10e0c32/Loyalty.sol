pragma solidity >=0.4.21 <0.6.0;

contract Loyalty {

    struct Enterprises {
        uint id;
        string name;
    }

    mapping(uint => Enterprises) public enterpises;

    uint public enterprisesCount;

    constructor () public {
    }

    function addCandidate (string memory _name) public {
        enterprisesCount ++;
        enterpises[enterprisesCount] = Enterprises(enterprisesCount, _name);
    }
}
