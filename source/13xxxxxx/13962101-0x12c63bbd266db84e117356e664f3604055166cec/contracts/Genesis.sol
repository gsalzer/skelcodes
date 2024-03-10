//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/GenesisSupplyInterface.sol";
import "./interfaces/State.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Genesis is ERC721Pausable, Ownable, State {
    struct Airdrop {
        address to;
        uint256 count;
    }

    /**
     * Mint parameters
     */
    uint256 public constant WHITELIST_MINT_COUNT = 1;
    uint256 public price;
    string public baseTokenURI;
    mapping(address => bool) private addressToMint;

    /**
     * Merkle tree properties
     */
    bytes32 private whiteListMerkleTreeRoot;

    DeployedSupply private supply;
    address private proxyRegistryAddress;

    constructor(
        address _genesisSupplyAddress,
        string memory unrevealedURI,
        uint256 _price,
        address _proxyRegistryAddress
    ) ERC721("Mythics Genesis", "MGEN") {
        supply = DeployedSupply(_genesisSupplyAddress);
        baseTokenURI = unrevealedURI;
        price = _price;
        proxyRegistryAddress = _proxyRegistryAddress;
        _pause();
    }

    /**
     * Getters
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmbZwPZgKS6YJkT2U4Vmp87udA6Cfy4Tu63KKDv4QnncU2";
    }

    function totalSupply() external view returns (uint256) {
        return supply.currentIndex();
    }

    /**
     * Setters
     */
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        require(mintState == MintState.Maintenance, "Mint not maintenance");
        // Set in Supply contract for the `getMetadataForTokenId` function
        supply.setIsRevealed(true);
        baseTokenURI = _baseTokenURI;
    }

    function setWhiteListMerkleTreeRoot(bytes32 _whiteListMerkleTreeRoot)
        external
        onlyOwner
    {
        whiteListMerkleTreeRoot = _whiteListMerkleTreeRoot;
    }

    function setMintState(MintState _mintState) external onlyOwner {
        require(_mintState > mintState, "State can't go back");
        mintState = _mintState;
        supply.setMintState(_mintState);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    /**
     * Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Airdrop tokens to an array of address
     * @param airdrops list of people to airdrop to
     */
    function airdrop(Airdrop[] calldata airdrops)
        external
        onlyOwner
        whenNotPaused
    {
        require(
            mintState == MintState.Closed || mintState == MintState.Active,
            "Not closed or active"
        );
        for (uint256 index = 0; index < airdrops.length; index++) {
            (uint256 startIndex, uint256 endIndex) = supply.mint(
                airdrops[index].count
            );
            for (uint256 i = startIndex; i < endIndex; i++) {
                _mint(airdrops[index].to, i);
            }
        }
    }

    /**
     * Whitelist mint
     * @param nonce nonce used to verify that the caller is allowed to mint
     * @param proof Proof to verify that the caller is allowed to mint
     */
    function mintWhitelist(uint256 nonce, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        active
    {
        require(
            verifyProof(nonce, whiteListMerkleTreeRoot, proof),
            "Address is not in the whitelist"
        );
        require(addressToMint[msg.sender] == false, "Already minted");
        require(msg.value == price, "Not enough ETH");
        addressToMint[msg.sender] = true;
        (uint256 startIndex, ) = supply.mint(1);
        _mint(msg.sender, startIndex);
    }

    /**
     * Function to mint the reserved gods
     * @param count number of gods to mint from the reserved pool
     */
    function mintReservedGods(uint256 count)
        external
        onlyOwner
        whenNotPaused
        closed
    {
        (uint256 startingIndex, uint256 maxSupply) = supply
            .reservedGodsCurrentIndexAndSupply();
        require(
            startingIndex + count <= maxSupply,
            "Not enough reserved gods left"
        );
        supply.mintReservedGods(count);
        // We use the current index if the reserved is done in multiple parts
        for (uint256 i = startingIndex; i < count + startingIndex; i++) {
            _mint(msg.sender, i);
        }
    }

    /**
     * Generate a leaf of the Merkle tree with a nonce and the address of the sender
     * @param nonce nonce to be used
     * @param addr id of the token
     * @return leaf generated
     */
    function generateLeaf(uint256 nonce, address addr)
        internal
        pure
        returns (bytes32 leaf)
    {
        return keccak256(abi.encodePacked(nonce, addr));
    }

    /**
     * Verifies the proof of the sender to confirm they are in given list
     * @param nonce nonce to be used
     * @param root Merkle tree root
     * @param proof proof
     * @return valid TRUE if the proof is valid, FALSE otherwise
     */
    function verifyProof(
        uint256 nonce,
        bytes32 root,
        bytes32[] memory proof
    ) internal view returns (bool valid) {
        return MerkleProof.verify(proof, root, generateLeaf(nonce, msg.sender));
    }

    /**
     * Withdraw balance from the contract
     */
    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * Override isApprovedForAll to whitelist user's ProxyRegistry proxy accounts to
     * enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

