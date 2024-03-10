pragma solidity >=0.6.0 <0.7.0;

import "./OwnersMap.sol";

/// @dev Proxy implementation based on https://blog.openzeppelin.com/proxy-patterns/
contract Proxy is OwnersMap {
    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "org.rockside.proxy.implementation", and is
     * validated in the constructor.
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0xeb8e929d60cd64fa98ec5363fe06b59a1224241a3c075680e7fd7afe9ed1f2a4;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "org.rockside.proxy.version", and is
     * validated in the constructor.
     */
    bytes32 private constant VERSION_SLOT = 0xebd5e45a3940557f33764246c4a8f7298050f720cd774a5014dd490b68013e2d;

    event Upgraded(bytes32 version, address implementation);

    constructor(address owner, bytes32 version, address implementation) payable public {
        owners[owner] = true;
        owners[address(this)] = true;
        _setVersion(version);
        _setImplementation(implementation);
    }

    function upgradeTo(bytes32 newVersion, address newImplementation) public {
        require(owners[msg.sender], "Sender is not an owner");
        require(_implementation() != newImplementation, "Implementation already used");
        _setVersion(newVersion);
        _setImplementation(newImplementation);
        emit Upgraded(newVersion, newImplementation);
    }

    function upgradeToAndCall(bytes32 newVersion, address newImplementation, bytes memory data) payable public {
        upgradeTo(newVersion, newImplementation);
        (bool success,) = address(this).call{value:msg.value}(data);
        require(success, "Failing call after upgrade");
    }

    function version() public view returns (bytes32) {
        return _version();
    }

    function implementation() public view returns (address) {
        return _implementation();
    }

    fallback() external payable {
        address _impl = _implementation();
        require(_impl != address(0), "No implementation provided");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    receive() external payable {}

    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
                impl := sload(slot)
        }
    }

    function _setImplementation(address newImplementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _version() internal view returns (bytes32 vrsn) {
        bytes32 slot = VERSION_SLOT;
        assembly {
            vrsn := sload(slot)
        }
    }

    function _setVersion(bytes32 newVersion) internal {
        bytes32 slot = VERSION_SLOT;

        assembly {
            sstore(slot, newVersion)
        }
    }
}

