// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title Factory for arbitrary code deployment using the "CREATE" and "CREATE2" opcodes
 */
abstract contract Factory {
    bytes private constant MINIMAL_PROXY_INIT_CODE_PREFIX =
        hex"3d602d80600a3d3981f3_363d3d373d3d3d363d73";
    bytes private constant MINIMAL_PROXY_INIT_CODE_SUFFIX =
        hex"5af43d82803e903d91602b57fd5bf3";

    event ContractDeployed(address indexed deployment);

    /**
     * @notice deploy an EIP1167 minimal proxy using "CREATE" opcode
     * @param target implementation contract to proxy
     * @return minimalProxy address of deployed proxy
     */
    function _deployMinimalProxy(address target) internal returns (address minimalProxy) {
        return _deploy(_generateMinimalProxyInitCode(target));
    }

    /**
     * @notice deploy an EIP1167 minimal proxy using "CREATE2" opcode
     * @dev reverts if deployment is not successful (likely because salt has already been used)
     * @param target implementation contract to proxy
     * @param salt input for deterministic address calculation
     * @return minimalProxy address of deployed proxy
     */
    function _deployMinimalProxy(address target, bytes32 salt) internal returns (address minimalProxy) {
        return _deploy(_generateMinimalProxyInitCode(target), salt);
    }

    /**
     * @notice calculate the deployment address for a given target and salt
     * @param target implementation contract to proxy
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function calculateMinimalProxyDeploymentAddress(address target, bytes32 salt) public view returns (address) {
        return
            calculateDeploymentAddress(
                keccak256(_generateMinimalProxyInitCode(target)),
                salt
            );
    }

    /**
     * @notice concatenate elements to form EIP1167 minimal proxy initialization code
     * @param target implementation contract to proxy
     * @return bytes memory initialization code
     */
    function _generateMinimalProxyInitCode(address target) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                MINIMAL_PROXY_INIT_CODE_PREFIX,
                target,
                MINIMAL_PROXY_INIT_CODE_SUFFIX
            );
    }

    /**
     * @notice deploy contract code using "CREATE" opcode
     * @param initCode contract initialization code
     * @return deployment address of deployed contract
     */
    function _deploy(bytes memory initCode) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create(0, encoded_data, encoded_size)
        }
        require(deployment != address(0), "Factory: failed deployment");
        emit ContractDeployed(deployment);
    }

    /**
     * @notice deploy contract code using "CREATE2" opcode
     * @dev reverts if deployment is not successful (likely because salt has already been used)
     * @param initCode contract initialization code
     * @param salt input for deterministic address calculation
     * @return deployment address of deployed contract
     */
    function _deploy(bytes memory initCode, bytes32 salt) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create2(0, encoded_data, encoded_size, salt)
        }
        require(deployment != address(0), "Factory: failed deployment");
        emit ContractDeployed(deployment);
    }

    /**
     * @notice calculate the _deployMetamorphicContract deployment address for a given salt
     * @param initCodeHash hash of contract initialization code
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function calculateDeploymentAddress(bytes32 initCodeHash, bytes32 salt) public view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                address(this),
                                salt,
                                initCodeHash
                            )
                        )
                    )
                )
            );
    }
}

