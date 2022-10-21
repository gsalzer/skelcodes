//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC1155SupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract CryptoStamp is Initializable, OwnableUpgradeable, ERC1155SupplyUpgradeable {
  function initialize(string calldata _uri) internal initializer {
    __Ownable_init();
    __ERC1155_init(_uri);
  }

  /**
   * @notice See definition of `_mint` in ERC1155 contract
   */
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) public virtual onlyOwner {
    _mint(account, id, amount, data);
  }

  /**
   * @notice See definition of `_mintBatch` in ERC1155 contract
   */
  function mintBatch(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) public virtual onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  /**
   * @notice allows to send NFTs of a specific token id to a number of addresses
   */
  function distributeNFTs(
    address _from,
    address[] calldata _recipients,
    uint256 _tokenId
  ) external {
    require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()), "CryptoStamp: caller is not owner nor approved");
    for (uint256 i = 0; i < _recipients.length; i++) {
      _safeTransferFrom(_from, _recipients[i], _tokenId, 1, "");
    }
  }

  /**
   * @notice allows to update the metadata URI
   */
  function updateURI(string calldata _newUri) external onlyOwner {
    _setURI(_newUri);
  }

  // https://forum.openzeppelin.com/t/storage-layout-upgrade-with-hardhat-upgrades/14567/2
  uint256[50] private __gap;
}

