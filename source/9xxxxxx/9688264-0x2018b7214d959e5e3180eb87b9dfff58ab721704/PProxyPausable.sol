// Sources flattened with buidler v1.1.2 https://buidler.dev

// File contracts/PProxyStorage.sol

pragma solidity ^0.6.2;

contract PProxyStorage {

    function readString(bytes32 _key) public view returns(string memory) {
        return bytes32ToString(storageRead(_key));
    }

    function setString(bytes32 _key, string memory _value) internal {
        storageSet(_key, stringToBytes32(_value));
    }

    function readBool(bytes32 _key) public view returns(bool) {
        return storageRead(_key) == bytes32(uint256(1));
    }

    function setBool(bytes32 _key, bool _value) internal {
        if(_value) {
            storageSet(_key, bytes32(uint256(1)));
        } else {
            storageSet(_key, bytes32(uint256(0)));
        }
    }

    function readAddress(bytes32 _key) public view returns(address) {
        return bytes32ToAddress(storageRead(_key));
    }

    function setAddress(bytes32 _key, address _value) internal {
        storageSet(_key, addressToBytes32(_value));
    }

    function storageRead(bytes32 _key) public view returns(bytes32) {
        bytes32 value;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            value := sload(_key)
        }
        return value;
    }

    function storageSet(bytes32 _key, bytes32 _value) internal {
        // targetAddress = _address;  // No!
        bytes32 implAddressStorageKey = _key;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(implAddressStorageKey, _value)
        }
    }

    function bytes32ToAddress(bytes32 _value) public pure returns(address) {
        return address(uint160(uint256(_value)));
    }

    function addressToBytes32(address _value) public pure returns(bytes32) {
        return bytes32(uint256(_value));
    }

    function stringToBytes32(string memory _value) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_value);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_value, 32))
        }
    }

    function bytes32ToString(bytes32 _value) public pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_value) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}


// File contracts/PProxy.sol

pragma solidity ^0.6.2;


contract PProxy is PProxyStorage {

    bytes32 constant IMPLEMENTATION_SLOT = keccak256(abi.encodePacked("IMPLEMENTATION_SLOT"));
    bytes32 constant OWNER_SLOT = keccak256(abi.encodePacked("OWNER_SLOT"));

    modifier onlyProxyOwner() {
        require(msg.sender == readAddress(OWNER_SLOT), "PProxy.onlyProxyOwner: msg sender not owner");
        _;
    }

    constructor () public {
        setAddress(OWNER_SLOT, msg.sender);
    }

    function getProxyOwner() public view returns (address) {
       return readAddress(OWNER_SLOT);
    }

    function setProxyOwner(address _newOwner) onlyProxyOwner public {
        setAddress(OWNER_SLOT, _newOwner);
    }

    function getImplementation() public view returns (address) {
        return readAddress(IMPLEMENTATION_SLOT);
    }

    function setImplementation(address _newImplementation) onlyProxyOwner public {
        setAddress(IMPLEMENTATION_SLOT, _newImplementation);
    }


    fallback () external payable {
       return internalFallback();
    }

    function internalFallback() internal virtual {
        address contractAddr = readAddress(IMPLEMENTATION_SLOT);
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), contractAddr, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

}


// File contracts/interfaces/IPProxyOverrides.sol

pragma solidity ^0.6.2;

interface IPProxyOverrides {
    function doesOverride(bytes4 _selector) external view returns (bool);
}


// File contracts/PProxyOverrideable.sol

pragma solidity ^0.6.2;



contract PProxyOverrideable is PProxy {

    bytes32 constant OVERRIDES_SLOT = keccak256(abi.encodePacked("OVERRIDES_SLOT"));

    function getOverrides() public view returns (address) {
        return readAddress(OVERRIDES_SLOT);
    }

    function setOverrides(address _newOverrides) public onlyProxyOwner {
        setAddress(OVERRIDES_SLOT, _newOverrides);
    }

    function internalFallback() internal virtual override {
        IPProxyOverrides overrides = IPProxyOverrides(readAddress(OVERRIDES_SLOT));
        // If overrrides function implements function override the called function.
        if(overrides.doesOverride(msg.sig)) {
            address contractAddr = address(overrides);
            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize())
                let result := delegatecall(gas(), contractAddr, ptr, calldatasize(), 0, 0)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)

                switch result
                case 0 { revert(ptr, size) }
                default { return(ptr, size) }
            }
        } else {
            super.internalFallback();
        }
    }
}


// File contracts/PProxyPausable.sol

pragma solidity ^0.6.2;


contract PProxyPausable is PProxy {

    bytes32 constant PAUSED_SLOT = keccak256(abi.encodePacked("PAUSED_SLOT"));
    bytes32 constant PAUZER_SLOT = keccak256(abi.encodePacked("PAUZER_SLOT"));

    constructor() PProxy() public {
        setAddress(PAUZER_SLOT, msg.sender);
    }

    modifier onlyPauzer() {
        require(msg.sender == readAddress(PAUZER_SLOT), "PProxyPausable.onlyPauzer: msg sender not pauzer");
        _;
    }

    modifier notPaused() {
        require(!readBool(PAUSED_SLOT), "PProxyPausable.notPaused: contract is paused");
        _;
    }

    function getPauzer() public view returns (address) {
        return readAddress(PAUZER_SLOT);
    }

    function setPauzer(address _newPauzer) public onlyProxyOwner{
        setAddress(PAUZER_SLOT, _newPauzer);
    }

    function renouncePauzer() public onlyPauzer {
        setAddress(PAUZER_SLOT, address(0));
    }

    function getPaused() public view returns (bool) {
        return readBool(PAUSED_SLOT);
    }

    function setPaused(bool _value) public onlyPauzer {
        setBool(PAUSED_SLOT, _value);
    }

    function internalFallback() internal virtual override notPaused {
        super.internalFallback();
    }

}


// File contracts/PProxyOverrideablePausable.sol

pragma solidity ^0.6.2;



contract PProxyOverrideablePausable is PProxyOverrideable, PProxyPausable {
    function internalFallback() internal override(PProxyOverrideable, PProxyPausable) notPaused {
        PProxyOverrideable.internalFallback();
    }
}


// File contracts/test/TestImplementation.sol

pragma solidity ^0.6.2;


contract TestImplementation {

    string public value;
    string public value1;

    function setValue1(string calldata _value) external {
        value1 = _value;
    }

    function getValue1() public view returns(string memory) {
        return value1;
    }

    function setValue(string calldata _value) external {
        value = _value;
    }

    function getValue() public view returns(string memory) {
        return value;
    }

}


// File contracts/test/TestOverrides.sol

pragma solidity ^0.6.2;

contract TestOverrides {

    string public value;
    string public value1;

    function doesOverride(bytes4 _selector) public view returns (bool) {
        if(
            _selector == this.name.selector ||
            _selector == this.symbol.selector ||
            _selector == this.setValue1.selector
        ) {
            return true;
        }

        return false;
    }

    function name() public view returns (string memory) {
        return "TOKEN_NAME";
    }

    function symbol() public view returns (string memory) {
        return "SYMBOL";
    }

    function setValue1(string memory _value) public {
        value1 = "OVERWRITTEN";
    }

}
