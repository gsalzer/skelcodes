//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";

contract Batch {
    using Address for address;

    struct Execution {
        address target;
        bytes callData;
    }

    struct ExecutionWithETH {
        address target;
        bytes callData;
        uint256 value;
    }

    struct SingleTargetExecutionWithETH {
        bytes callData;
        uint256 value;
    }

    address public immutable executor;

    constructor(address _executor) {
        executor = _executor;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "NOT_AUTHORIZED");
        _;
    }

    function atomicBatchWithETH(ExecutionWithETH[] memory executions) external payable onlyExecutor {
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i].target.functionCallWithValue(executions[i].callData, executions[i].value);
        }
    }

    function nonAtomicBatchWithETH(ExecutionWithETH[] memory executions) external payable onlyExecutor {
        for (uint256 i = 0; i < executions.length; i++) {
            _call(executions[i].target, executions[i].callData, executions[i].value);
        }
    }

    function atomicBatch(Execution[] memory executions) external onlyExecutor {
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i].target.functionCall(executions[i].callData);
        }
    }

    function nonAtomicBatch(Execution[] memory executions) external onlyExecutor {
        for (uint256 i = 0; i < executions.length; i++) {
            _call(executions[i].target, executions[i].callData, 0);
        }
    }

    function singleTargetAtomicBatchWithETH(address target, SingleTargetExecutionWithETH[] memory executions)
        external
        payable
        onlyExecutor
    {
        for (uint256 i = 0; i < executions.length; i++) {
            target.functionCallWithValue(executions[i].callData, executions[i].value);
        }
    }

    function singleTargetNonAtomicBatchWithETH(address target, SingleTargetExecutionWithETH[] memory executions)
        external
        payable
        onlyExecutor
    {
        for (uint256 i = 0; i < executions.length; i++) {
            _call(target, executions[i].callData, executions[i].value);
        }
    }

    function singleTargetAtomicBatch(address target, bytes[] memory callDatas) external onlyExecutor {
        for (uint256 i = 0; i < callDatas.length; i++) {
            target.functionCall(callDatas[i]);
        }
    }

    function singleTargetNonAtomicBatch(address target, bytes[] memory callDatas) external onlyExecutor {
        for (uint256 i = 0; i < callDatas.length; i++) {
            _call(target, callDatas[i], 0);
        }
    }

    function _call(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bool) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = target.call{value: value}(data);
        return success;
    }

    // ----------------------------------------------------------------------------------------------------
    // TOKEN RECEPTION
    // ----------------------------------------------------------------------------------------------------

    // ERC1155
    bytes4 private constant ERC1155_IS_RECEIVER = 0x4e2312e0;
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC1155_BATCH_RECEIVED;
    }

    // ERC721

    bytes4 private constant ERC721_IS_RECEIVER = 0x150b7a02;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return ERC721_RECEIVED;
    }

    // ERC165
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == 0x01ffc9a7 || _interfaceId == ERC1155_IS_RECEIVER || _interfaceId == ERC721_IS_RECEIVER;
    }
}

