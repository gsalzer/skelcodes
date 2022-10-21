pragma solidity ^0.4.18;

import "./DelegateProxy.sol";

contract Forwarder is DelegateProxy {
  // After compiling contract, `beefbeef...` is replaced in the bytecode by the real target address
  address public constant target = 0x1ed7fc52ac5a37aa3ff6d9b94c894724e2f992b1; // checksumed to silence warning

  /*
  * @dev Forwards all calls to target
  */
  function() payable {
    delegatedFwd(target, msg.data);
  }
}
