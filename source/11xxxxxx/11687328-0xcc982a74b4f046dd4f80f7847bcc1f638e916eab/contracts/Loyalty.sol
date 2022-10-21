pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/presets/ERC721PresetMinterPauserAutoId.sol";

contract Loyalty is ERC721PresetMinterPauserAutoIdUpgradeSafe {
  function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyAdmin {
    _setTokenURI(_tokenId, _tokenURI);
  }

  function setBaseURI(string memory baseURI_) external onlyAdmin {
    _setBaseURI(baseURI_);
  }

  modifier onlyAdmin() {
    require(hasRole(MINTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!mod");
    _;
  }
}

