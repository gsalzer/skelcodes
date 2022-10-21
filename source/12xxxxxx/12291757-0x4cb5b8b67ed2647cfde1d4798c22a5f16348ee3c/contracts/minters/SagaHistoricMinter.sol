pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../library/LibSafeMath.sol";
import "../ERC1155Mintable.sol";
import "../mixin/MixinOwnable.sol";
import "../mixin/MixinPausable.sol";
import "../HashRegistry.sol";

contract SagaHistoricMinter is Ownable, MixinPausable {
  using LibSafeMath for uint256;

  uint256 public tokenType;

  ERC1155Mintable public mintableErc1155;
  HashRegistry public registry;

  // historic pricing params
  uint256 immutable public startingPriceForHistoric;
  uint256 immutable public pricePerMintForHistoric;

  // max total minting supply
  uint256 immutable maxMintingSupply;

  address payable public treasury;

  constructor(
    address _registry,
    address _mintableErc1155,
    address payable _treasury,
    uint256 _tokenType,
    uint256 _startingPriceForHistoric,
    uint256 _pricePerMintForHistoric,
    uint256 _maxMintingSupply
  ) {
    registry = HashRegistry(_registry);
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    treasury = _treasury;
    tokenType = _tokenType;
    startingPriceForHistoric = _startingPriceForHistoric;
    pricePerMintForHistoric = _pricePerMintForHistoric;
    maxMintingSupply = _maxMintingSupply;
  }

  modifier onlyUnderMaxSupply(uint256 mintingAmount) {
    require(maxIndex() + mintingAmount <= maxMintingSupply, 'max supply minted');
    _;
  }

  function pause() external onlyOwner() {
    _pause();
  } 

  function unpause() external onlyOwner() {
    _unpause();
  }  

  function setTreasury(address payable _treasury) external onlyOwner() {
    treasury = _treasury;
  }

  function maxIndex() public view returns (uint256) {
    return mintableErc1155.maxIndex(tokenType);
  }

  function pricingCurveForHistoric(uint256 _maxIndex) public view returns (uint256) {
    return _maxIndex.safeMul(pricePerMintForHistoric).safeAdd(startingPriceForHistoric); 
  }

  function mint(address[] calldata _dsts, uint256[] calldata _txHashes) public payable whenNotPaused() onlyUnderMaxSupply(_dsts.length) {
    require(_dsts.length == _txHashes.length, "dsts, txhashes length mismatch");
    // verify and transfer fee
    uint256 price = 0;
    for (uint256 i = 0; i < _dsts.length; ++i) {
      price += pricingCurveForHistoric(maxIndex() + i);
    }
    require(price <= msg.value, "insufficient funds to pay for mint");
    treasury.transfer(price);
    msg.sender.transfer(msg.value.safeSub(price));
    _mint(_dsts, _txHashes);
  }

  function _mint(address[] memory dsts, uint256[] memory txHashes) internal {
    uint256[] memory tokenIds = new uint256[](dsts.length);
    for (uint256 i = 0; i < dsts.length; ++i) {
      uint256 index = maxIndex() + 1 + i;
      uint256 tokenId  = tokenType | index;
      tokenIds[i] = tokenId;
    }
    mintableErc1155.mintNonFungible(tokenType, dsts);
    registry.writeToRegistry(tokenIds, txHashes);
  }
}
