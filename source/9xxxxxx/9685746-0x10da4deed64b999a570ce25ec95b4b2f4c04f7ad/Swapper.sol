pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

struct Info {
    address owner;
    uint number;
}

contract Swapper {
    address creator=msg.sender;
    
    function multiSwap(address[] calldata addresses,bytes[] calldata payloads,uint[] calldata values) external {
        require(msg.sender==creator||msg.sender==address(this));
        for(uint8 i=0;i<payloads.length;i++){
            addresses[i].call{value:values[i]}(payloads[i]);
        }
    }
    
    function callFunction(address sender,Info calldata accountInfo, bytes calldata data) external {
        require(sender==address(this)&&msg.sender==0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
        address(this).call(data);
    }
}
