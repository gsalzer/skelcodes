//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IKetherHomepage.sol";
import "./KetherNFTRender.sol";


contract FlashEscrow {
  constructor(address target, bytes memory payload) {
    (bool success,) = target.call(payload);
    require(success, "FlashEscrow: target call failed");

    selfdestruct(payable(target));
  }
}

contract KetherNFT is ERC721Enumerable, Ownable {
  /// instance is the KetherHomepage contract that this wrapper interfaces with.
  IKetherHomepage public instance;

  /// disableRenderUpgrade is whether we can still upgrade the tokenURI renderer.
  /// Once it is set it cannot be unset.
  bool disableRenderUpgrade = false;

  ITokenRenderer public renderer;

  constructor(address _ketherContract, address _renderer) ERC721("Thousand Ether Homepage Ad", "1KAD") {
    instance = IKetherHomepage(_ketherContract);
    renderer = ITokenRenderer(_renderer);
  }

  function _encodeFlashEscrow(uint _idx) internal view returns (bytes memory) {
    return abi.encodePacked(
      type(FlashEscrow).creationCode,
      abi.encode(address(instance), _encodeFlashEscrowPayload(_idx)));
  }

  function _encodeFlashEscrowPayload(uint _idx) internal view returns (bytes memory) {
    return abi.encodeWithSignature("setAdOwner(uint256,address)", _idx, address(this));
  }

  /// `precompute` generates a commitment address for minting the NFT to `_owner`. This can be the original owner
  /// of the ad, or a different address. After the ad is transfered to the precomputed address, `wrap` has
  /// to be called with the same `_owner` to complete minting the NFT.
  function precompute(uint _idx, address _owner) public view returns (bytes32 salt, address predictedAddress) {
    require(_owner != address(this) && _owner != address(0), "KetherNFT: invalid _owner");

    salt = sha256(abi.encodePacked(_owner));

    bytes memory bytecode = _encodeFlashEscrow(_idx);

    bytes32 hash = keccak256(
      abi.encodePacked(
        bytes1(0xff),
        address(this),
        salt,
        keccak256(bytecode)
      )
    );

    predictedAddress = address(uint160(uint256(hash)));
    return (salt, predictedAddress);
  }

  function _getAdOwner(uint _idx) internal view returns (address) {
      (address owner,,,,,,,,,) = instance.ads(_idx);
      return owner;
  }

  /// wrap mints an NFT if the ad unit's ownership has been transferred to the
  /// precomputed escrow address.
  function wrap(uint _idx, address _owner) external {
    (bytes32 salt, address precomputedFlashEscrow) = precompute(_idx, _owner);

    require(_getAdOwner(_idx) == precomputedFlashEscrow, "KetherNFT: owner needs to be the correct precommitted address");

    // FlashEscrow completes the transfer escrow atomically and self-destructs.
    new FlashEscrow{salt: salt}(address(instance), _encodeFlashEscrowPayload(_idx));
    require(_getAdOwner(_idx) == address(this), "KetherNFT: owner needs to be KetherNFT after wrap");

    _mint(_owner, _idx);
  }

  function unwrap(uint _idx, address _newOwner) external {
    require(_isApprovedOrOwner(_msgSender(), _idx), "KetherNFT: unwrap for sender that is not owner");

    instance.setAdOwner(_idx, _newOwner);
    require(_getAdOwner(_idx) == _newOwner, "KetherNFT: unwrap ownership transfer failed");

    _burn(_idx);
  }

  function baseURI() public pure returns (string memory) {}

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "KetherNFT: tokenId does not exist");
    return renderer.tokenURI(instance, tokenId);
  }

  /// publish is a proxy for KetherHomapage's publish function.
  ///
  /// Publish allows for setting the link, image, and NSFW status for the ad
  /// unit that is identified by the idx which was returned during the buy step.
  /// The link and image must be full web3-recognizeable URLs, such as:
  ///  - bzz://a5c10851ef054c268a2438f10a21f6efe3dc3dcdcc2ea0e6a1a7a38bf8c91e23
  ///  - bzz://mydomain.eth/ad.png
  ///  - https://cdn.mydomain.com/ad.png
  ///  - https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu
  ///  - ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu
  /// Images should be valid PNG.
  /// Content-addressable storage links like IPFS are encouraged.
  function publish(uint _idx, string calldata _link, string calldata _image, string calldata _title, bool _NSFW) external {
    require(_isApprovedOrOwner(_msgSender(), _idx), "KetherNFT: publish for sender that is not approved");

    instance.publish(_idx, _link, _image, _title, _NSFW);
  }

  /// buy is a proxy for KetherHomepage's buy function. Calling it allows
  /// an ad to be purchased directly as an NFT without needing to wrap it later.
  ///
  /// Ads must be purchased in 10x10 pixel blocks.
  /// Each coordinate represents 10 pixels. That is,
  ///   _x=5, _y=10, _width=3, _height=3
  /// Represents a 30x30 pixel ad at coordinates (50, 100)
  function buy(uint _x, uint _y, uint _width, uint _height) external payable returns (uint idx) {
    idx = instance.buy{value: msg.value}(_x, _y, _width, _height);
    _safeMint(_msgSender(), idx);

    return idx;
  }

  /// Admin helpers:

  /// adminRecoverTrapped allows us to transfer ownership of ads that were
  /// incorrectly transferred to this contract without an NFT being minted.
  /// This should never happen, but we include this recovery function in case
  /// there is a bug in the DApp that somehow falls into this condition.
  /// Note that this function does *not* give admin any control over properly
  /// minted ads/NFTs.
  function adminRecoverTrapped(uint _idx, address _to) external onlyOwner {
    require(!_exists(_idx), "KetherNFT: recovery can only be done on unminted ads");
    require(_getAdOwner(_idx) == address(this), "KetherNFT: ad not held by contract");
    instance.setAdOwner(_idx, _to);
  }

  function adminSetRenderer(address _renderer) external onlyOwner {
    require(disableRenderUpgrade == false, "KetherNFT: upgrading renderer is disabled");
    renderer = ITokenRenderer(_renderer);
  }

  function adminDisableRenderUpgrade() external onlyOwner {
    disableRenderUpgrade = true;
  }
}

