pragma solidity ^0.4.18;

import "./DelegateProxy.sol";

contract Forwarder is DelegateProxy {
  // After compiling contract, `beefbeef...` is replaced in the bytecode by the real target address
  address public constant target = 0x4c7f27882edb11e057adbb4bd873c21c6a1dbe27; // checksumed to silence warning

  /*
  * @dev Forwards all calls to target
  */
  function() payable {
    delegatedFwd(target, msg.data);
  }
}
