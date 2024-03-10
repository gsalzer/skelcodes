pragma solidity ^0.4.24;

import "./RemoteTokenURIProvider.sol";
import "./Privileged.sol";
import "./ERC721.sol";

/**
 * An ERC721Metadata override which uses an external contract for providing tokenURI values.
 */
contract RemoteTokenURI is ERC721Metadata, Privileged {
  RemoteTokenURIProvider public remoteTokenUriContract;
  uint8 internal setRemoteTokenUriAddressPrivilege;

  constructor(uint8 _setRemoteTokenUriAddressPrivilege) internal {
    setRemoteTokenUriAddressPrivilege = _setRemoteTokenUriAddressPrivilege;
  }

  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    if (remoteTokenUriContract != address(0)) {
      return remoteTokenUriContract.tokenURI(_tokenId);
    } else {
      // If not set, all tokenURI values are blank
      return "";
    }
  }

  function setRemoteTokenUriAddress(address _target) public requirePrivileges(setRemoteTokenUriAddressPrivilege) {
    remoteTokenUriContract = RemoteTokenURIProvider(_target);
  }
}

