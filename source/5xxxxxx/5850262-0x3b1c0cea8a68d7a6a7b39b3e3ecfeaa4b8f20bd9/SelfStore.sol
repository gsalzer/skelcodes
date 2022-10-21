// solhint-disable max-line-length
// @title A contract to store only messages sent by owner

/* Deployment:
Owner: 0x33a7ae7536d39032e16b0475aef6692a09727fe2
Owner Ropsten testnet: 0x4460f4c8edbca96f9db17ef95aaf329eddaeac29
Owner private testnet: 0x4460f4c8edbca96f9db17ef95aaf329eddaeac29
Address: 0x3b1c0cea8a68d7a6a7b39b3e3ecfeaa4b8f20bd9
Address Ropsten testnet: 0x7d15361535ae02954b2f028ec0965e93639df4b4
Address private testnet: 0xc03336c0001c8066a891e96c413e3aef072e72fc
ABI: [{"constant":false,"inputs":[{"name":"_dataInfo","type":"string"},{"name":"_version","type":"uint256"}],"name":"add","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"contentCount","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":false,"stateMutability":"nonpayable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"version","type":"uint256"},{"indexed":false,"name":"dataInfo","type":"string"}],"name":"LogMessage","type":"event"}]
Optimized: yes
Solidity version: v0.4.24
*/

// solhint-enable max-line-length

pragma solidity 0.4.24;


contract SelfStore {

    address public owner;

    uint public contentCount = 0;
    
    event LogMessage(uint indexed version, string dataInfo);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    // @notice fallback function, don't allow call to it
    function () public {
        revert();
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }

    function add(string _dataInfo, uint _version) public onlyOwner {
        contentCount++;
        emit LogMessage(_version, _dataInfo);
    }
}
