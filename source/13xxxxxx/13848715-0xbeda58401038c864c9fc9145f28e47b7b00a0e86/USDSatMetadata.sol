// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Base64.sol";
import "./Strings.sol";

contract USDSatMetadata {
    string tokenName = "Dollars Nakamoto";
    string tokenDescription = "Multiple Edition - Dollars Nakamoto by Pascal Boyart is a farming NFT collection based on the original artwork made with hundreds of real USD Bills glued on canvas in 2018.";
    
    string JSON = 'data:application/json;base64,';

    uint256 metadataId = 1;

    string DollarsNakamotoGenesisGifCID = "QmP3asJxMbCMrN6aDKN4iZpcUJw2zEHTfJuV8sh5XhUSAv";
    string DollarsNakamotoGenerationGifCID = "QmZ71ajdHPS7NofbK3rpNAJqnxq29mfdNSPaecy3bHUD9G";

    string DollarsNakamotoGenesisMp4CID = "QmRmvo1wDxSV2uBm1KNqJ9z6UayzickLKhMKJYfdhMGCbf";
    string DollarsNakamotoGenerationMp4CID = "QmWBAS7pmRbWZQ3wkiuw918zVtz9eS6oajpkq9hUVBFiwo";
    
    mapping (uint256 => string) _metadataName;
    mapping (uint256 => string) _metadataAttributes;
    mapping (uint256 => string) _metadataImageCID;
    mapping (uint256 => string) _metadataVideoCID;

    constructor() {}

    function _serialize(uint256 _tokenId)
    private pure returns(string memory result) {
        string memory tmp;
        if (_tokenId < 1000) tmp = string(abi.encodePacked('', Strings.toString(_tokenId)));
        if (_tokenId < 100) tmp = string(abi.encodePacked('0', Strings.toString(_tokenId)));
        if (_tokenId < 10) tmp = string(abi.encodePacked('00', Strings.toString(_tokenId)));
        
        result = string(
            abi.encodePacked(
                '#', tmp
            )
        );
    }

    function setMetadata(uint256 _tokenId, uint256 _epochId, uint256 _epoch)
    internal {
        _setMetadataName(_tokenId, _epoch);
        _setMetadataOrigins(_tokenId, _epochId, _epoch);
        _setMetadataImageCID(_tokenId, _epoch);
        _setMetadataVideoCID(_tokenId, _epoch);
        metadataId++;
    }

    function _setMetadataImageCID(uint256 _tokenId, uint256 _epoch)
    internal {
        _metadataImageCID[_tokenId] = string(
            abi.encodePacked(
                "ipfs://",
                _epoch == 0 ?
                DollarsNakamotoGenesisGifCID :
                DollarsNakamotoGenerationGifCID
            )
        );
    }

    function _setMetadataVideoCID(uint256 _tokenId, uint256 _epoch)
    internal {
        _metadataVideoCID[_tokenId] = string(
            abi.encodePacked(
                "ipfs://",
                _epoch == 0 ?
                DollarsNakamotoGenesisMp4CID :
                DollarsNakamotoGenerationMp4CID
            )
        );
    }

    function _setMetadataName(uint256 _tokenId, uint256 _epoch)
    internal {
        _metadataName[_tokenId] = string(
            abi.encodePacked(
                tokenName, ' - ', _epoch == 0 ? 'Genesis Edition' : string(
                    abi.encodePacked(
                        Strings.toString(_epoch + 1), (
                            (_epoch + 1) == 2 ? 'nd' :
                            (_epoch + 1) == 3 ? 'rd' :
                            (_epoch + 1) > 3 ? 'th' :
                            ''
                        ), ' Edition'
                    )
                )
            )
        );
    }

    function _setMetadataOrigins(uint256 _tokenId, uint256 _epochId, uint256 _epoch)
    internal {
        _metadataAttributes[_tokenId] = string(
            abi.encodePacked(
                _epoch == 0 ?
                '{"trait_type":"Edition","value":"Genesis"},' :
                string(
                    abi.encodePacked(
                        '{"trait_type":"Edition","value":"#', Strings.toString(_epoch + 1),'"},'
                    )
                ),
                _epoch == 0 ?
                '{"trait_type":"NFT Type","value":"Generator"},' : '{"trait_type":"NFT Type","value":"Generated"},',
                '{"trait_type":"Serial","value":"',_serialize(_epochId),'"},',
                '{"trait_type":"Character","value":"Dorian Nakamoto"},',
                '{"trait_type":"Effect","value":"BRRR"},',
                '{"trait_type":"USD Portrait","value":"#1 - Who is Satoshi"},',
                '{"trait_type":"Medium","value":"Dollar bills glued on canvas"}'
            )
        );
    }

    function _tokenData(uint256 _tokenId)
    internal view returns (string memory result) {
        result = string(
            abi.encodePacked(
                '{',
                '"name":"',_metadataName[_tokenId],'",',
                '"description":"',tokenDescription,'",',
                '"attributes":[',_metadataAttributes[_tokenId],'],',
                '"image":"',_metadataImageCID[_tokenId],'",',
                '"animation_url":"',_metadataVideoCID[_tokenId],'"',
                '}'
            )
        );
    }

    function _compileMetadata(uint256 _tokenId)
    internal view returns (
        string memory result) {
            result = string(abi.encodePacked(
                JSON,
                Base64.encode(
                    bytes (
                        string(
                            abi.encodePacked(
                                _tokenData(_tokenId)
                            )
                        )
                    )
                )
            )
        );
    }
}

