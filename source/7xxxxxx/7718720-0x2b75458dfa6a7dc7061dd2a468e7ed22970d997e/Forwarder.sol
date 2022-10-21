pragma solidity ^0.4.18;

import "./DelegateProxy.sol";

contract Forwarder is DelegateProxy {
  // After compiling contract, `beefbeef...` is replaced in the bytecode by the real target address
  address public constant target = 0x92268d9c15657f14c9b0d551b97e260467dbe585; // checksumed to silence warning

  /*
  * @dev Forwards all calls to target
  */
  function() payable {
    delegatedFwd(target, msg.data);
  }
}
