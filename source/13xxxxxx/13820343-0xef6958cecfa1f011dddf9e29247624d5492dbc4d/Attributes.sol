// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./AttributesStorage.sol";

contract Attributes is AttributesStorage {
    using SafeMath for uint256;

    uint256 randNonce = 0;

    event SetNFTAddress(address oldAddress, address newAddress);

    modifier isController() {
        require(controllers[msg.sender], "Ownable: caller is not the controller");
        _;
    }

    function initTokenIdAttributes(uint256 tokenId) public {
        require(msg.sender == _nftAddress, "caller is not the nft Address");
        if(intelligence[tokenId]==0 && agility[tokenId]==0 && aggressivity[tokenId]==0) {
            intelligence[tokenId] = random();
            agility[tokenId] = random();
            aggressivity[tokenId] = random();
        }
    }

    function random() private returns (uint8) {
        randNonce++;
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randNonce)))%50);
    }

    function tokenIdAttributes(uint256 tokenId) public view returns(uint256, uint256, uint256) {
        return (intelligence[tokenId], agility[tokenId], aggressivity[tokenId]);
    }

    function _setNFTAddress(address nftAddress) external {
        require(msg.sender == admin, "Ownable: caller is not the admin");
        emit SetNFTAddress(_nftAddress, nftAddress);
        _nftAddress = nftAddress;
    }

    
    function updateAttributes(uint256 tokenId,uint256[] memory updateValues, uint256[] memory updates) public isController {
        require(updateValues.length == updates.length, "Mismatched inputs");
        updateIntelligenceValue(tokenId, updateValues[0], updates[0]);
        updateAgilityValue(tokenId, updateValues[1], updates[1]);
        updateAggressivityValue(tokenId, updateValues[2], updates[2]);
    }

    function updateIntelligenceValue(uint256 tokenId, uint256 value, uint256 update) internal {
        if(value > 0) {
            if(update == 1) {
                if(intelligence[tokenId].add(value) > MAX) {
                    value = MAX.sub(intelligence[tokenId]);
                }
                intelligence[tokenId] = intelligence[tokenId].add(value);
            } else {
                if(intelligence[tokenId] < value) {
                    value = intelligence[tokenId];
                }
                intelligence[tokenId] = intelligence[tokenId].sub(value);
            }
        }
    }

    function updateAgilityValue(uint256 tokenId, uint256 value, uint256 update) internal {
        if(value > 0) {
            if(update == 1) {
                if(agility[tokenId].add(value) > MAX) {
                    value = MAX.sub(agility[tokenId]);
                }
                agility[tokenId] = agility[tokenId].add(value);
            } else {
                if(agility[tokenId] < value) {
                    value = agility[tokenId];
                }
                agility[tokenId] = agility[tokenId].sub(value);
            }
        }
    }

    function updateAggressivityValue(uint256 tokenId, uint256 value, uint256 update) internal {
        if(value > 0) {
            if(update == 1) {
                if(aggressivity[tokenId].add(value) > MAX) {
                    value = MAX.sub(aggressivity[tokenId]);
                }
                aggressivity[tokenId] = aggressivity[tokenId].add(value);
            } else {
                if(aggressivity[tokenId] < value) {
                    value = aggressivity[tokenId];
                }
                aggressivity[tokenId] = aggressivity[tokenId].sub(value);
            }
        }
    }
}
