// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

contract MinimalProxyFactory {
    function _deployBytecode(address _prototype) internal pure returns(bytes memory) {
        return abi.encodePacked(
            hex'602d600081600a8239f3363d3d373d3d3d363d73',
            _prototype,
            hex'5af43d82803e903d91602b57fd5bf3'
        );
    }

    function _deploy(address _prototype, bytes32 _salt) internal returns(address payable _result) {
        bytes memory _bytecode = _deployBytecode(_prototype);
        assembly {
            _result := create2(0, add(_bytecode, 32), mload(_bytecode), _salt)
        }
        return _result;
    }
}

