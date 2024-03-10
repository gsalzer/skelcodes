pragma solidity 0.4.24;
/******************************************************************************\
* 
* Contains functions for retrieving function signatures and delegate contract
* addresses.
/******************************************************************************/

import "./StorageV0.sol";
import "./IERC1538Query.sol";

contract ERC1538QueryDelegates is IERC1538Query, StorageV0 {

    function totalFunctions() external view returns(uint256) {
        return funcSignatures.length;
    }

    function functionByIndex(uint256 _index) external view returns(string memory functionSignature, bytes4 functionId, address delegate) {
        require(_index < funcSignatures.length, "functionSignatures index does not exist.");
        bytes memory signature = funcSignatures[_index];
        functionId = bytes4(keccak256(signature));
        delegate = delegates[functionId];
        return (string(signature), functionId, delegate);
    }

    function functionExists(string _functionSignature) external view returns(bool) {
        return funcSignatureToIndex[bytes(_functionSignature)] != 0;
    }

    function functionSignatures() external view returns(string) {
        uint256 signaturesLength;
        bytes memory signatures;
        bytes memory signature;
        uint256 functionIndex;
        uint256 charPos;
        uint256 funcSignaturesNum = funcSignatures.length;
        bytes[] memory memoryFuncSignatures = new bytes[](funcSignaturesNum);
        for(; functionIndex < funcSignaturesNum; functionIndex++) {
            signature = funcSignatures[functionIndex];
            signaturesLength += signature.length;
            memoryFuncSignatures[functionIndex] = signature;
        }
        signatures = new bytes(signaturesLength);
        functionIndex = 0;
        for(; functionIndex < funcSignaturesNum; functionIndex++) {
            signature = memoryFuncSignatures[functionIndex];
            for(uint256 i = 0; i < signature.length; i++) {
                signatures[charPos] = signature[i];
                charPos++;
            }
        }
        return string(signatures);
    }

    function delegateFunctionSignatures(address _delegate) external view returns(string) {
        uint256 funcSignaturesNum = funcSignatures.length;
        bytes[] memory delegateSignatures = new bytes[](funcSignaturesNum);
        uint256 delegateSignaturesPos;
        uint256 signaturesLength;
        bytes memory signatures;
        bytes memory signature;
        uint256 functionIndex;
        uint256 charPos;
        for(; functionIndex < funcSignaturesNum; functionIndex++) {
            signature = funcSignatures[functionIndex];
            if(_delegate == delegates[bytes4(keccak256(signature))]) {
                signaturesLength += signature.length;
                delegateSignatures[delegateSignaturesPos] = signature;
                delegateSignaturesPos++;
            }

        }
        signatures = new bytes(signaturesLength);
        functionIndex = 0;
        for(; functionIndex < delegateSignatures.length; functionIndex++) {
            signature = delegateSignatures[functionIndex];
            if(signature.length == 0) {
                break;
            }
            for(uint256 i = 0; i < signature.length; i++) {
                signatures[charPos] = signature[i];
                charPos++;
            }
        }
        return string(signatures);
    }

    function delegateAddress(string _functionSignature) external view returns(address) {
        require(funcSignatureToIndex[bytes(_functionSignature)] != 0, "Function signature not found.");
        return delegates[bytes4(keccak256(bytes(_functionSignature)))];
    }

    function functionById(bytes4 _functionId) external view returns(string signature, address delegate) {
        for(uint256 i = 0; i < funcSignatures.length; i++) {
            if(_functionId == bytes4(keccak256(funcSignatures[i]))) {
                return (string(funcSignatures[i]), delegates[_functionId]);
            }
        }
        revert("functionId not found");
    }

    function delegateAddresses() external view returns(address[]) {
        uint256 funcSignaturesNum = funcSignatures.length;
        address[] memory delegatesBucket = new address[](funcSignaturesNum);
        uint256 numDelegates;
        uint256 functionIndex;
        bool foundDelegate;
        address delegate;
        for(; functionIndex < funcSignaturesNum; functionIndex++) {
            delegate = delegates[bytes4(keccak256(funcSignatures[functionIndex]))];
            for(uint256 i = 0; i < numDelegates; i++) {
                if(delegate == delegatesBucket[i]) {
                    foundDelegate = true;
                    break;
                }
            }
            if(foundDelegate == false) {
                delegatesBucket[numDelegates] = delegate;
                numDelegates++;
            }
            else {
                foundDelegate = false;
            }
        }
        address[] memory delegates_ = new address[](numDelegates);
        functionIndex = 0;
        for(; functionIndex < numDelegates; functionIndex++) {
            delegates_[functionIndex] = delegatesBucket[functionIndex];
        }
        return delegates_;
    }
}
