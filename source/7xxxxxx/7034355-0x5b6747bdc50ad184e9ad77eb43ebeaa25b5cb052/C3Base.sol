pragma solidity ^0.5.0 <0.6.0;

contract C3Base {
  function () external payable {
    _fallback();
  }

  function _fallback() internal {
    _delegateCall(logicBoard());
  }

  function logicBoard() internal view returns (address);

  function _delegateCall(address _logicBoard) internal {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // Load msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the logicBoard.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas, _logicBoard, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }
}

