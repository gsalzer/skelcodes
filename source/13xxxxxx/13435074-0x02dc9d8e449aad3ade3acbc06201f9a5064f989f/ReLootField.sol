// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReLoot.sol";
import "./LootGenerator.sol";

contract ReLootField {
    ReLoot _reloot;
    LootGenerator _lootGenerator;

    constructor(address reloot, address lootGenerator) {
        _reloot = ReLoot(reloot);
        _lootGenerator = LootGenerator(lootGenerator);
    }

    function GetSuffix(uint256 tokenId, uint256 idx) external view returns(string memory) {
        int8[5] memory vector = _reloot.getEquipmentVector(tokenId, idx);
        if (vector[3]<0){
            return "";
        }
        return _lootGenerator.getFieldSuffix(uint8(vector[3]));
    }

    function GetNamePrefix(uint256 tokenId, uint256 idx) external view returns(string memory){
        int8[5] memory vector = _reloot.getEquipmentVector(tokenId, idx);
        if (vector[0]<0 || vector[1]<0) {
            return "";
        }

        string memory namePrefix = _lootGenerator.getFieldNamePrefix(uint8(vector[0]));
        namePrefix = string(abi.encodePacked('"', namePrefix, ' ', _lootGenerator.getFieldNameSuffix(uint8(vector[1])), '"'));
        return namePrefix;
    }

    function GetAddition(uint256 tokenId, uint256 idx) external view returns(string memory){
        int8[5] memory vector = _reloot.getEquipmentVector(tokenId, idx);
        if (vector[4] == 0) {
            return "+1";
        }
        return "";
    }
}
