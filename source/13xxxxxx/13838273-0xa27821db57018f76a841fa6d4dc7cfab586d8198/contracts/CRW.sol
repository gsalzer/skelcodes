// TNCX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "./IFactoryERC721.sol";
import "./CRY.sol";

contract CRW is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://api.cryppo.io/factory/";



    uint256 MAX_SUPPLY = 3777; //MAX SUPPLY
    uint256 NUM_OPTIONS = 5; 
    uint256 SINGLE_OPTION = 0; 


    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Cryppo Factory";
    }

    function symbol() override external pure returns (string memory) {
        return "CRW";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );
        require(canMint(_optionId));

        CRY nft = CRY(nftAddress);
        if (_optionId == SINGLE_OPTION) {
            nft.mintTo(_toAddress);

        } else if (_optionId == 1) {
            for (
                uint256 i = 0;
                i < 3;
                i++
            ) {
                nft.mintTo(_toAddress);
            }
        } else if (_optionId == 2) {
            for (
                uint256 i = 0;
                i < 5;
                i++
            ) {
                nft.mintTo(_toAddress);
            }
        } else if (_optionId == 3) {
            for (
                uint256 i = 0;
                i < 25;
                i++
            ) {
                nft.mintTo(_toAddress);
            }
        } else if (_optionId == 4) {
            for (
                uint256 i = 0;
                i < 50;
                i++
            ) {
                nft.mintTo(_toAddress);
            }
        } 
    
        
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        CRY nft = CRY(nftAddress);
        uint256 totalSupply = nft.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_OPTION) {
            numItemsAllocated = 1;

        } else if (_optionId == 1) {
            numItemsAllocated = 3;

        } else if (_optionId == 2) {
            numItemsAllocated = 5;

        }  else if (_optionId == 3) {
            numItemsAllocated = 25;

        }  else if (_optionId == 4) {
            numItemsAllocated = 50;

        } 

        
        return totalSupply <= (MAX_SUPPLY - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
