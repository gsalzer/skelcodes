// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//        '
//        .                      .
//        .                      ;
//        :                  - --+- -
//        !           .          !
//        |        .             .
//        |_         +
//     ,  | '.
//    --- --+-<#>-+- ---  --  -
//     '._|_,'
//        T
//        |
//        !
//        :         . :
//        .       *
//        '

/** @title Chromospheres */
contract Chromospheres is ERC721Enumerable, Ownable {
    string public contractState; // "presale" or "public_mint"
    bytes32 public publicMintState = keccak256(abi.encodePacked("public_mint"));
    bytes32 public presaleMintState = keccak256(abi.encodePacked("presale"));
    uint256 public constant mintPricePublic = 0.065 ether;
    uint256 public constant mintPricePresale = 0.05 ether;
    uint256 public constant maxSupply = 707;
    uint256 public constant reservedTokens = 14;
    string private currentBaseURI;
    address public presaleAccessAddr =
        0x01a9f037d4Cd7DA318ab097a47aCD4DEA3ABc083;

    mapping(uint256 => bool) presaleAccessAddrUsed;

    event Received(address, uint256);

    constructor() ERC721("Chromospheres", "CHROMO") {}

    /**
     * @dev Set the contract's state
     * @param _contractState The new desired contract state
     */
    function setContractState(string memory _contractState) public onlyOwner {
        contractState = _contractState;
    }

    /** @dev Update the base URI
     * @param baseURI_ New value of the base URI
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        currentBaseURI = baseURI_;
    }

    /** @dev Get the current base URI
     * @return currentBaseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return currentBaseURI;
    }

    /** @dev Sets the setPresaleAccessAddr address
     * @param presaleAccessAddr_ the address
     */
    function setPresaleAccessAddr(address presaleAccessAddr_) public onlyOwner {
        presaleAccessAddr = presaleAccessAddr_;
    }

    /** @dev Attempt a mint in the presale
     * @param quantity the quantity to mint
     */
    function mintPresale(uint256 quantity) public payable {
        require(
            keccak256(abi.encodePacked(contractState)) == presaleMintState,
            "Presale is not active"
        );

        // check the txn value
        require(
            msg.value >= mintPricePresale * quantity,
            "Insufficient value to presale mint"
        );

        // find the presaleAccessToken ids that have not been used to get a chromo
        uint256 nValidPresaleAccessIds = getNumValidPresaleAccessIds();

        // find the maxQuantity of CHROMO mintable given the remaining presaleTokens not used
        uint256 maxQuantity = nValidPresaleAccessIds / 2; // rounds down

        // ensure the quantity requested is possible
        require(
            quantity <= maxQuantity,
            "Insufficient presale tokens to mint this amount"
        );

        // calculate how many presale access tokens will be 'used' to mint this qty
        uint256 nPresaleIdsToUse = quantity * 2;
        uint256 nPresaleIdsUsed = 0;

        // iterate over the presaleAccessToken ids
        // and mark nPresaleIdsToUse as used
        uint256[] memory presaleIds = getOwnedPresaleAccessIds();
        for (uint256 i = 0; i < presaleIds.length; i++) {
            if (!presaleAccessAddrUsed[presaleIds[i]]) {
                // mark this presaleToken as used
                presaleAccessAddrUsed[presaleIds[i]] = true;
                nPresaleIdsUsed += 1;
                if (nPresaleIdsUsed == nPresaleIdsToUse) {
                    break;
                }
            }
        }
        mint(quantity);
    }

    /** @dev A public function to check the ids of presale access tokens
     * @param tokenId tokenId from the presaleAccess contract
     */
    function isPresaleAccessIdValid(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return !presaleAccessAddrUsed[tokenId];
    }

    /** @dev Calculate the number of remaining valid presaleAccess tokens
     *
     */
    function getNumValidPresaleAccessIds() public view returns (uint256) {
        uint256[] memory presaleIds = getOwnedPresaleAccessIds();
        // find the presaleAccessToken ids that have not been used to get a chromo
        uint256 nValidPresaleAccessIds = 0;

        for (uint256 i = 0; i < presaleIds.length; i++) {
            if (!presaleAccessAddrUsed[presaleIds[i]]) {
                nValidPresaleAccessIds += 1;
            }
        }

        return nValidPresaleAccessIds;
    }

    /** @dev Get the tokenIds of presale access tokens owned by the sender
     */
    function getOwnedPresaleAccessIds() public view returns (uint256[] memory) {
        ERC721Enumerable presaleAccessToken = ERC721Enumerable(
            presaleAccessAddr
        );

        uint256[] memory ownedIds = new uint256[](
            presaleAccessToken.balanceOf(msg.sender)
        );

        for (uint256 i = 0; i < ownedIds.length; i++) {
            ownedIds[i] = presaleAccessToken.tokenOfOwnerByIndex(msg.sender, i);
        }

        return ownedIds;
    }

    /** @dev Mints a token during the public mint phase
     * @param quantity The quantity of tokens to mint
     */
    function mintPublic(uint256 quantity) public payable {
        require(
            (keccak256(abi.encodePacked(contractState)) == publicMintState),
            "Public minting is not active"
        );
        // check the txn value

        require(
            msg.value >= mintPricePublic * quantity,
            "Insufficient value to public mint"
        );

        mint(quantity);
    }

    /** @dev Mints a token
     * @param quantity The quantity of tokens to mint
     */
    function mint(uint256 quantity) private {
        /// Disallow transactions that would exceed the maxSupply
        require(totalSupply() + quantity <= maxSupply, "Supply is exhausted");
        /// mint the requested quantity
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /**
     * @dev Set some tokens aside for the team
     */
    function reserveTokens() public onlyOwner {
        for (uint256 i = 0; i < reservedTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /**
     * @dev Withdraw ether to owner's wallet
     */
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

