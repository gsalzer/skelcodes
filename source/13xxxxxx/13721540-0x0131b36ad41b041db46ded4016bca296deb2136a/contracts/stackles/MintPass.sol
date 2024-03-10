// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// The mint pass contract for Staxx Invaders.
///
/// The contract provides two paths for minting.
///   1) through an access list (merkle proof) with a free reward allocation
///   2) through the public sale
///
/// The access list will go live before the public sale to give existing holders of STAXX a chance
/// to mint early.
contract MintPass is ERC1155, ERC1155Burnable, ERC1155Supply, ERC1155Pausable, Ownable {
  using MerkleProof for bytes32[];

  /// The price each pass will sell for.
  uint256 public constant price = 0.03 ether;

  /// Total number of passes to sell.
  uint256 public constant total = 10500;

  /// Timestamp of the public launch: 2021-12-03 08:00:00.0Z
  uint256 private _publicLaunch = 1638478800;

  /// The address of the contract that will redeem the mint passes for STAXX Invaders.
  address private _redeemFrom;

  /// The root hash of the merkle proof used to validate the access list and reward allocations.
  bytes32 private _rootHash;

  /// Keep track of the number of passes claimed from the access list to prevent double dipping.
  mapping(address => uint256) private _claimed;

  /// Events.
  event TokensClaimed(address sender, uint256 claimed, uint256 amount, uint256 free);
  event DepositReceived(address sender, uint256 value);
  event WithdrawBalance(address caller, uint256 amount);
  event ProofValidated(address sender, uint256 allocation, bytes32 leaf, bytes32 root);

  event ErrorHandled(string reason);

  /// Errors.
  error InvalidProof(address sender, uint256 allocation, bytes32 leaf, bytes32 root);
  error SaleNotStarted(uint256 currentTime, uint256 startTime);
  error InsufficientFunds(uint256 required, uint256 provided);
  error InsufficientSupply(uint256 total, uint256 supply, uint256 requested);

  constructor(
    address redeemFrom_,
    bytes32 rootHash_,
    string memory uri_
  ) ERC1155(uri_) {
    _redeemFrom = redeemFrom_;
    _rootHash = rootHash_;

    // Put aside 750 passes for future community engagement etc.
    _mint(msg.sender, 0, 750, "reserving tokens");
  }

  /// Fallback to be able to receive ETH payments (just in case!)
  receive() external payable {
    emit DepositReceived(msg.sender, msg.value);
  }

  /// Minting method for people on the access list that can mint before the public sale and
  /// potentially with a reward of free passes.
  ///
  /// The merkle proof is for the combination of the senders address and number of allocated passes.
  /// These values are encoded to a fixed length padding to help prevent attacking the hash.
  ///
  /// The minter will only pay for any passes they mint beyond those allocated to them. They can
  /// mint as many times as they like, and with as many tokens at a time as they would like. We
  /// track the number of claimed tokens to prevent double dipping.
  function mintPassWithAllocation(
    uint256 count,
    uint256 allocated,
    bytes32[] calldata proof
  ) external payable {
    address sender = _msgSender();
    bytes32 leaf = keccak256(abi.encode(sender, allocated));
    if (!proof.verify(_rootHash, leaf)) {
      revert InvalidProof(sender, allocated, leaf, _rootHash);
    } else {
      emit ProofValidated(sender, allocated, leaf, _rootHash);
    }

    uint256 supply = totalSupply(0);
    if (supply + count > total) {
      revert InsufficientSupply(total, supply, count);
    }

    uint256 claiming = _claimed[_msgSender()];
    uint256 remaining = (claiming < allocated) ? allocated - claiming : 0;

    uint256 paid = remaining > count ? 0 : count - remaining;
    emit TokensClaimed(sender, claiming, count, paid);

    uint256 cost = paid * price;
    if (msg.value < cost) {
      revert InsufficientFunds(cost, msg.value);
    }

    _mint(sender, 0, count, "minted from presale");
    _claimed[sender] += (count - paid);

    if (msg.value > cost) {
      uint256 refund = msg.value - cost;
      (bool success, ) = payable(sender).call{value: refund}("");
      require(success);
    }
  }

  /// Perform a regular mint with no limit on passes per transaction. All passes are charged at full
  /// price.
  function mintPass(uint256 count) external payable onlyAfter(_publicLaunch) {
    uint256 cost = count * price;
    if (msg.value < cost) {
      revert InsufficientFunds(cost, msg.value);
    }

    _mint(msg.sender, 0, count, "minted from public sale");

    if (msg.value > cost) {
      uint256 refund = msg.value - cost;
      (bool success, ) = payable(msg.sender).call{value: refund}("");
      require(success, "ERROR: could not refund excees payment");
    }
  }

  /// Burns [amount] tokens in return for something else (determined by the calling contract).
  function burnFromRedeem(
    address account,
    uint256 token,
    uint256 count
  ) external onlyRedeemer {
    _burn(account, token, count);
  }

  /// Pauses the contract to prevent further sales.
  function pause() external virtual onlyOwner {
    _pause();
  }

  /// Unpauses the contract to allow sales to continue.
  function unpause() external virtual onlyOwner {
    _unpause();
  }

  /// Returns the number of free passes claimed by a given wallet.
  function claimed(address addr) external view returns (uint256) {
    return _claimed[addr];
  }

  /// Returns the number of free passes claimed by the caller.
  function claimedByMe() external view returns (uint256) {
    return _claimed[msg.sender];
  }

  /// Returns the root hash of the merkle tree proof used to validate the access list.
  function rootHash() external view returns (bytes32) {
    return _rootHash;
  }

  /// Returns the wallet that burn passes to redeem.
  function redeemFrom() external view returns (address) {
    return _redeemFrom;
  }

  /// Returns the timestamp of the public sale start time.
  function publicLaunch() external view returns (uint256) {
    return _publicLaunch;
  }

  /// Lets us set an updated launch date.
  function setPublicLaunch(uint32 publicLaunch_) external onlyOwner {
    _publicLaunch = publicLaunch_;
  }

  /// Updates the address that can redeem passes later.
  function setRedeemFrom(address redeemFrom_) external onlyOwner {
    _redeemFrom = redeemFrom_;
  }

  /// Updates the root hash of the merkle proof.
  function setRootHash(bytes32 rootHash_) external onlyOwner {
    _rootHash = rootHash_;
  }

  /// Updates the metadata URI.
  function setURI(string calldata baseURI) external onlyOwner {
    _setURI(baseURI);
  }

  /// Transfers the funds out of the contract to the owners wallet.
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
    emit WithdrawBalance(msg.sender, balance);
  }

  /// DANGER: Here be dragons!
  function destroy() external onlyOwner {
    selfdestruct(payable(msg.sender));
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Supply, ERC1155Pausable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  modifier onlyRedeemer() {
    require(msg.sender == _redeemFrom || msg.sender == owner());
    _;
  }

  modifier onlyAfter(uint256 timestamp) {
    if (block.timestamp < timestamp) {
      revert SaleNotStarted(block.timestamp, timestamp);
    }
    _;
  }
}

