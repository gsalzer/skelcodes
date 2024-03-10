// solium-disable linebreak-style
pragma solidity ^0.5.0;


contract medianizerContract {
    function read() public view returns (bytes32);
}

contract Test {

    function getMakerPricing() public view returns (bytes32) {
        address medianizerAddress = 0x729D19f657BD0614b4985Cf1D82531c67569197B;
        medianizerContract mC = medianizerContract(medianizerAddress);
        return mC.read();
    }
    
    function ByteToUint(bytes32 b) public pure returns(uint) {
        return uint(b);
    }
    
    function GetMePrice() public view returns (uint) {
        return ByteToUint(getMakerPricing());
    }
}
