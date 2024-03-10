pragma solidity ^0.5.1;


interface WebsensorsDoracleInterface {
    function receiveResult(bytes32 id, bytes calldata result) external;
    /*  
      receiveResult MUST revert if the msg.sender is not an oracle authorized to provide the result for that id
      receiveResult MAY revert if receiveResult has been called with the same id before. 
      receiveResult MAY revert if the id or result cannot be handled by the handler.
    */
}
