// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.0;

contract HasMaster {
    address public masterContract;
    
    function newMaster(address addy) external view returns (bool) {
        require(msg.sender == masterContract);
        masterContract == addy;
        assert(addy == masterContract);
        return true;
    }
}

contract ExternalAccessible is HasMaster {

    function checkAccess() public returns (bool) {
        bytes memory payload = abi.encodeWithSignature("checkAccessAddy(address)", msg.sender);
        (bool success, bytes memory returnData) = masterContract.call(payload);
        bool data = abi.decode(returnData, (bool));
        require(data);
        return true;
    }

//    function checkAccess() public view returns (bool) {
//        bytes memory payload = abi.encodeWithSignature("checkAccessAddy", msg.sender);
//        (bool success, bytes memory returnData) = masterContract.call(payload);
//        require(success);
//        return true;
//    }

    modifier hasAccess() {
        require(checkAccess());
        _;
    }
}
