pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

/// @title Multicall - Aggregate results from multiple read-only function calls
///        this is a fork of the original that supports reverts
/// @author Trevor Aron <trevor.aron@coinbase.com>
/// @author Michael Elliot <mike@makerdao.com>
/// @author Joshua Levine <joshua@makerdao.com>
/// @author Nick Johnson <arachnid@notdot.net>

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls, uint256 gasLimit)
        external
        view
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) =
                calls[i].target.staticcall{ gas: gasLimit }(calls[i].callData);
            if (success) {
                returnData[i] = ret;
            }
        }
    }

    // Helper functions
    function getEthBalance(address addr)
        external
        view
        returns (uint256 balance)
    {
        balance = addr.balance;
    }

    function getBlockHash(uint256 blockNumber)
        external
        view
        returns (bytes32 blockHash)
    {
        blockHash = blockhash(blockNumber);
    }

    function getLastBlockHash() external view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getCurrentBlockTimestamp()
        external
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    function getCurrentBlockDifficulty()
        external
        view
        returns (uint256 difficulty)
    {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit()
        external
        view
        returns (uint256 gaslimit)
    {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockCoinbase()
        external
        view
        returns (address coinbase)
    {
        coinbase = block.coinbase;
    }
}

