pragma solidity ^0.5.0;


contract HolderProxy {

    address public delegate;
    address public owner = msg.sender;

    function upgradeDelegate(address newDelegate) public {
        require(msg.sender == owner, "Access denied");
        if (delegate != newDelegate) {
            delegate = newDelegate;
        }
    }

    function() external payable {
        address _impl = delegate;
        require(_impl != address(0), "Delegate not initialized");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
