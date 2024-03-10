pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "./MushroomNFT.sol";
import "./MushroomLib.sol";
import "./metadata/MushroomMetadata.sol";

contract MushroomFactory is Initializable, OwnableUpgradeSafe {
    using MushroomLib for MushroomLib.MushroomData;
    using MushroomLib for MushroomLib.MushroomType;
    using SafeMath for uint256;

    IERC20 public sporeToken;
    MushroomNFT public mushroomNft;
    MushroomMetadata public mushroomMetadata;

    uint256 public costPerMushroom;
    uint256 public mySpecies;

    function initialize(IERC20 sporeToken_, MushroomNFT mushroomNft_, uint256 costPerMushroom_) public initializer {
        __Ownable_init();
        sporeToken=sporeToken_;
        mushroomNft=mushroomNft_;
        costPerMushroom=costPerMushroom_;
    }

    function _generateMushroomLifespan(uint256 minLifespan, uint256 maxLifespan) internal returns (uint256) {
        uint256 range = maxLifespan.sub(minLifespan);
        uint256 fromMin = uint256(keccak256(abi.encodePacked(block.timestamp))) % range;
        return minLifespan.add(fromMin);
    }

    // Each mushroom costs 1/10th of the spore rate in spores.
    function growMushrooms(address recipient, uint256 numMushrooms) public onlyOwner {
        MushroomLib.MushroomType memory species = mushroomNft.getSpecies(mySpecies);
        for (uint256 i = 0; i < numMushrooms; i++) {
            uint256 nextId = mushroomNft.totalSupply().add(1);
            mushroomNft.mint(recipient, nextId, mySpecies, _generateMushroomLifespan(species.minLifespan, species.maxLifespan));
        }
    }
}
