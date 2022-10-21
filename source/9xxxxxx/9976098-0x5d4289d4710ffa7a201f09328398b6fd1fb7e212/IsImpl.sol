pragma solidity ^0.6.0;

contract IsImpl {
    
    function implement(address _contract) public view returns (bytes memory){
        assembly {
            let ptr:= mload(0x40)
            let size:= extcodesize(_contract)
            extcodecopy(_contract, ptr, 0, size)
            
            return(ptr, size)
        }
    }
}
