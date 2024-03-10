pragma solidity ^0.5.4;

import "./SafeMathLib.sol";

contract FairPlayOptions {
    
    using SafeMathLib for uint256;
    
    mapping (address => bool) private admins;
    
    event OptionCreated(uint id, string text);
    
    struct Option {
        string text;
    }
    
    uint[] public options;
    
    uint optionCounter;
    
    mapping(uint => Option) public optionMap;
    
    modifier isAdmin(address _addr) {
        require(admins[_addr]);
        _;
    }
    
    constructor() public {
        optionCounter = 1;
        admins[msg.sender] = true;
    }
    
    function getOptions() public view returns(uint[] memory) {return options;}
    
    function getOption(uint _id) public view returns(string memory) {return optionMap[_id].text;}
    
    function createOption(string memory text) isAdmin(msg.sender) public {
        uint id = optionCounter;
        optionCounter = optionCounter.add(1);
        Option memory opt = Option(text);
        optionMap[id] = opt;
        options.push(id);
        emit OptionCreated(id, text);
    }
    
    function gaddress() public view returns(address) { return address(this); }
}
