pragma solidity ^0.6.0;

contract TokenFallThrough {
    address payable private _owner;
    
    constructor() public {
        _owner = msg.sender;
    }
    
    function withdraw() public {
        _owner.transfer(address(this).balance);
    }
    
    function symbol() public pure returns (string memory) {
        return string("NTFY");
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function name() public view returns(string memory) {
        uint256 size;
        assembly { size := extcodesize(address()) }
        uint256 nameSize = size - 86;
        bytes memory bName = new bytes(nameSize);
        assembly { extcodecopy(address(), add(bName, 0x20), 86, nameSize) }
        return string(bName);
    }
    
    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }
    
    function totalSupply() external pure returns (uint256) {
        return 1;
    }
    
    function balanceOf(address) external pure returns (uint256) {
        return 1;
    }
    
    function transfer(address, uint256) external returns (bool success) {
        address a;
        assembly {
            let ptr := mload(0x40)
            extcodecopy(address(), ptr, 66, 32)
            a := shr(0x60, mload(ptr))
        }
        if (a == msg.sender) {
            assembly { success := call(gas(), address(), 0, 0, 0, 0, 0) }
        } else {
            success = false;
        }
    }
}
