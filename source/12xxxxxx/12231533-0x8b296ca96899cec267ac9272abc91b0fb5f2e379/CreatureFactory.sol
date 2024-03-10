pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./IFactoryERC721.sol";
import "./Creature.sol";
import "./Strings.sol";

contract CreatureFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://creatures-api.opensea.io/api/factory/";

    /**
     * Three different options for minting Creatures (basic, premium, and gold).
     */
    uint256 NUM_OPTIONS = 3;

    constructor(address _proxyRegistryAddress, address _nftAddress) public {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() external view returns (string memory) {
        return "OpenSeaCreature Item Sale";
    }

    function symbol() external view returns (string memory) {
        return "CPF";
    }


    function supportsFactoryInterface() public view returns (bool) {
        return true;
    }

    function numOptions() public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) public {
        return;
    }

    function canMint(uint256 _optionId) public view returns (bool) {
        return false;
    }

    function tokenURI(uint256 _optionId) external view returns (string memory) {
        return Strings.strConcat(baseURI, Strings.uint2str(_optionId));
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

