// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./utils/Ownable.sol";
import "./CosmoMasksERC721.sol";

interface IERC20BurnTransfer {
    function burn(uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ICosmoTokenMint {
    function mintToFond(uint256 amount) external returns (bool);
}

interface ICosmoMasks {
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}


contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


// https://eips.ethereum.org/EIPS/eip-721 tokenURI
/**
 * @title CosmoMasks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract CosmoMasks is Ownable, CosmoMasksERC721, ICosmoMasks {
    using SafeMath for uint256;

    // This is the provenance record of all CosmoMasks artwork in existence
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant NAME_CHANGE_PRICE = 1830 * (10**18);
    uint256 public constant MAX_SUPPLY = 16410;
    string public constant PROVENANCE = "67c9815f30768bdaa4d8f016295ebe0339326587ab9a5dc423191c5aee4ce532";
    string public PROVENANCE_EXTRA;
    bool public provenanceExtraSetted;
    uint256 public SALE_START_TIMESTAMP;
    // Time after which CosmoMasks are randomized and allotted
    uint256 public REVEAL_TIMESTAMP;

    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    address private _cosmoToken;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;
    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;
    // Mapping from token ID to whether the CosmoMask was minted before reveal
    mapping(uint256 => bool) private _mintedBeforeReveal;
    // CosmoMasks Power address
    address private _cmpAddress;
    address proxyRegistryAddress;
    string private _contractURI;

    event NameChange(uint256 indexed tokenId, string newName);
    event SetStartingIndexBlock(uint256 startingIndexBlock);
    event SetStartingIndex(uint256 startingIndex);


    constructor(address cmpAddress, uint256 emissionStartTimestamp, address _proxyRegistryAddress) public CosmoMasksERC721("CosmoMasks", "COSMAS") {
        _cmpAddress = cmpAddress;
        SALE_START_TIMESTAMP = emissionStartTimestamp;
        REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (SECONDS_IN_A_DAY * 14);
        proxyRegistryAddress = _proxyRegistryAddress;
        _setBaseURI("https://TheCosmoMasks.com/cosmomasks-metadata/");
        _setURL("https://TheCosmoMasks.com/");
        _contractURI = "https://TheCosmoMasks.com/cosmomasks-contract-metadata.json";
    }

    function getCosmoToken() public view returns (address) {
        return _cosmoToken;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns name of the CosmoMask at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    /**
     * @dev Returns if the CosmoMask has been minted before reveal phase
     */
    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }

    /**
     * @dev Gets current CosmoMask Price
     */
    function getPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "CosmoMasks: sale has not started");
        require(totalSupply() < MAX_SUPPLY, "CosmoMasks: sale has already ended");

        uint256 currentSupply = totalSupply();

        if (currentSupply >= 16409) {
            return 1000000e18;
        } else if (currentSupply >= 16407) {
            return 100000e18;
        } else if (currentSupply >= 16400) {
            return 10000e18;
        } else if (currentSupply >= 16381) {
            return 1000e18;
        } else if (currentSupply >= 16000) {
            return 100e18;
        } else if (currentSupply >= 15000) {
            return 17e18;
        } else if (currentSupply >= 11000) {
            return 9e18;
        } else if (currentSupply >= 7000) {
            return 5e18;
        } else if (currentSupply >= 3000) {
            return 3e18;
        } else {
            return 1e18;
        }
    }

    /**
    * @dev Mints CosmoMasks
    */
    function mint(uint256 numberOfMasks) public payable {
        require(totalSupply() < MAX_SUPPLY, "CosmoMasks: sale has already ended");
        require(numberOfMasks > 0, "CosmoMasks: numberOfMasks cannot be 0");
        require(numberOfMasks <= 20, "CosmoMasks: You may not buy more than 20 CosmoMasks at once");
        require(totalSupply().add(numberOfMasks) <= MAX_SUPPLY, "CosmoMasks: Exceeds MAX_SUPPLY");
        require(getPrice().mul(numberOfMasks) == msg.value, "CosmoMasks: Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfMasks; i++) {
            uint256 mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
            ICosmoTokenMint(_cosmoToken).mintToFond(1e24);
        }

        if (startingIndex == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            _setStartingIndex();
        }
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "CosmoMasks: starting index is already set");
        require(block.timestamp >= REVEAL_TIMESTAMP, "CosmoMasks: Too early");
        _setStartingIndex();
    }

    function _setStartingIndex() internal {
        startingIndexBlock = block.number - 1;
        emit SetStartingIndexBlock(startingIndexBlock);

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_SUPPLY;
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
        emit SetStartingIndex(startingIndex);
    }

    /**
     * @dev Changes the name for CosmoMask tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "CosmoMasks: caller is not the token owner");
        require(validateName(newName) == true, "CosmoMasks: not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "CosmoMasks: new name is same as the current one");
        require(isNameReserved(newName) == false, "CosmoMasks: name already reserved");

        IERC20BurnTransfer(_cmpAddress).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        IERC20BurnTransfer(_cmpAddress).burn(NAME_CHANGE_PRICE);
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1)
            return false;
        // Cannot be longer than 25 characters
        if (b.length > 25)
            return false;
        // Leading space
        if (b[0] == 0x20)
            return false;
        // Trailing space
        if (b[b.length - 1] == 0x20)
            return false;

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            // Cannot contain continous spaces
            if (char == 0x20 && lastChar == 0x20)
                return false;
            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;
            lastChar = char;
        }
        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90))
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            else
                bLower[i] = bStr[i];
        }
        return string(bLower);
    }

    function setProvenanceExtra(string memory provenanceExtra) public onlyOwner {
        require(provenanceExtraSetted == false, "CosmoMasks: provenanceExtra has already setted");
        PROVENANCE_EXTRA = provenanceExtra;
        provenanceExtraSetted = true;
    }

    function setCosmoToken(address token) public onlyOwner {
        require(_cosmoToken == address(0), "CosmoMasks: CosmosToken has already setted");
        require(token != address(0), "CosmoMasks: CosmoToken is the zero address");
        _cosmoToken = token;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function setURL(string memory newUrl) public onlyOwner {
        _setURL(newUrl);
    }
}

