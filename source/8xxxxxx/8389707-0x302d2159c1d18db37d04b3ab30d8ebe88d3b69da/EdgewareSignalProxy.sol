pragma solidity ^0.5.11;

import "./Lockdrop.sol";

/// @dev Proxy contract that enables secure signalling through three-distinct private keys.
/// fundSrc = address that provides funds to the proxy
/// fundDst = address that receives funds when signalling is completed
/// admin = address that can trigger release() of funds to fundDst
contract EdgewareSignalProxy {
  address payable public fundDst;
  address public fundSrc;
  address public admin;
  bytes public edgewareAddr;
  Lockdrop public lockdrop;

  /// @dev Establish a new proxy for singnalling.
  /// @param _lockdrop Address of the Edgeware Lockdrop singalling contract
  /// @param _fundSrc The address that provides funds to this proxy
  /// @param _fundDst The address that will receive funds after signalling is complete
  /// @param _admin The administration address: can call signal() and release()
  /// @param _edgewareAddr The edgeware address that will receive funds from the lockdrop
  constructor(
    Lockdrop _lockdrop,
    address _fundSrc,
    address payable _fundDst,
    address _admin,
    bytes memory _edgewareAddr
  ) public {
    lockdrop = _lockdrop;
    fundSrc = _fundSrc;
    fundDst = _fundDst;
    admin = _admin;
    edgewareAddr = _edgewareAddr;
  }

  /// @dev Ensures that only the admin or the fundDst addresses can call a given function.
  modifier auth() {
    require(msg.sender == admin || msg.sender == fundDst, "Sender must be the fund destination or admin address");
    _;
  }

  /// @dev Signals to the lockdrop contract when new founds are deposited.
  /// Will only receive deposits from the designated fundSrc address
  function () external payable {
    require(msg.sender == fundSrc, "Sender must be the fund source address");
    signal();
  }

  /// @dev Calls the signal() method on the lockdrop contract with the Edgeware address
  /// associated with this proxy.
  function signal() internal {
    // Note that the nonce parameter can be set to any value. We're signalling on behalf of
    // oursevles and not another contract and so when Lockdrop.signal calls didCreate
    // the nonce value is ignored.
    lockdrop.signal(address(this), 0, edgewareAddr);
  }

  /// @dev Sends all fund held by this contract back to the fundDst address.
  /// Note that if funds are release()d before the Edgeware Lockdrop snapshot has occurred
  /// that no credit for this signalling will take place. Be sure to release() funds
  /// after the snapshot has completed to ensure credit for signal()ing.
  function release() external auth {
    address(fundDst).transfer(address(this).balance);
  }
}
