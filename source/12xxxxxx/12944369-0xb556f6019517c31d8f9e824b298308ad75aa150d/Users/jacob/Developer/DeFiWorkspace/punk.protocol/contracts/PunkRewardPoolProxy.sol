// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "./OwnableStorage.sol";

contract PunkRewardPoolProxy is Proxy{

    event Upgraded(address indexed implementation);

    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _OWNABLE_STORAGE_SLOT = 0x8de9519aeedcea35f7581a1710364953511221d8b7309789ecb15ac4b1a06fc1;
    bytes32 private constant _INITIALIZE_SLOT = 0xd1144699b2459fa4c652fe6a4a3ddb7d1dd632f82d755cb1d4bc09b8ef6d4b4f;

    modifier isInitializer(){
        require( getInitialize() != 1, "Initializable: contract is already initialized");
        _;
    }

    modifier CheckAdmin(){
        require( OwnableStorage( _storage() ).isAdmin(msg.sender), "OWNABLE: 0x0" );
        _;
    }

    function initialize( address implAddress, bytes memory initData, address storage_ ) public isInitializer{
        require(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        require(_OWNABLE_STORAGE_SLOT == bytes32(uint256(keccak256("punk.reward.proxy.ownablestrage")) - 1));
        require(_INITIALIZE_SLOT == bytes32(uint256(keccak256("punk.reward.proxy.initialize")) - 1));

        _setImplementation(implAddress);
        _setStorage( storage_ );
        _setInitialize( );

        if(initData.length > 0) {
            Address.functionDelegateCall(implAddress, initData);
        }

    }

    function _setStorage( address storage_ ) internal {
        bytes32 slot = _OWNABLE_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, storage_)
        }
    }

    function _storage() internal view returns( address storageAddr ){
        bytes32 slot = _OWNABLE_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageAddr := sload(slot)
        }
    }

    function _implementation() internal view override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    function upgradeTo(address newImplementation) public CheckAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967Proxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _setInitialize( ) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_INITIALIZE_SLOT, 1)
        }
    }

    function getInitialize( ) private view returns (uint256 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload( _INITIALIZE_SLOT )
        }
    }

}
