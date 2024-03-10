// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";


/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
contract ArtBurn is Ownable, ERC721 {
    
    using Strings for uint256;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;


    struct Collection {
        string title;
        string description;
        // Keep track of how much of contract value will be transfered to the token owner
        // that burns the first tokenId in this collection where _withdrawOnBurn[tokenId] is true 
        uint balance;

        // If true, then it is not possible to mint more tokens to this collection ever.
        // Contract owner can only close collections. Nobody can open collections.
        bool closed;
    }
    
    // Array of all created collections.
    Collection[] private _collections;


    // Keep track of how much of contract value can be withdrawn by owner.
    // Payments to contract that are note through deposit(collectionId) is added here.
    uint256 public ownerBalance = 0;
    
    
    // mapping from collection to tokens
    mapping(uint256 => EnumerableSet.UintSet) private _collectionTokens;
    
    // mapping from collection to withdrawOnBurnTokens
    mapping(uint256 => EnumerableSet.UintSet) private _collectionWithdrawOnBurnTokens;

    // Mapping from token to the collection it is a part of
    mapping(uint256 => uint256) private _tokenCollection;

    // Mapping from keccak256(title) to collection_id+1.
    // The plus one part is since first collection will have id=0
    // and this mapping defaults to zero.
    // used to get collectionId from title
    mapping(bytes32 => uint256) private _collectionIdsPlusOne;



    // URL for the storefront-level metadata
    string private _contractURI;
    
    // Counter to keep track of curren token_id
    uint256 private _currentTokenId = 0;
    
    // Mapping from tokenId to contentURI. ContentURI cannot be changed after mint.
    // Should mint this to be the artwork IPFS-hash
    mapping(uint256 => string) private _contentURIs;
    
    // Mapping from collectionId to collectionContentBaseURI.
    // Some collections might not have a collectionContentBaseURI, for example when content is onchain.
    // while other might.
    mapping(uint256 => string) private _collectionContentBaseURIs;

    // Mapping from token to withdrawOnBurn flag
    mapping(uint256 => bool) private _withdrawOnBurn;

    
    // Mapping from tokenId to maximum edition that can be claimed
    // A claim will create a identical token as this, but with different edition number.
    mapping(uint256 => uint256) private _maximumEditions;
    
    // Mapping from tokenId to price increase per claim in percent
    // If greater than zero, then each claim will increase the price for the next claim by the percent given here.
    // Value 10 means 10 percent, then if price is: 0.1, then after 
    // one claim the price will increase to 0.11 for the next claim
    mapping(uint256 => uint8) private _percentPriceIncreasePerClaim;

    // Mapping from tokenId to current edition
    // The number of editions (claims made + 1) for a given tokenId
    // Will always be inclusive between 1 and _maximumEditions[tokenId]
    mapping(uint256 => uint256) private _editions;

    // Mapping from tokenId to price to claim
    mapping(uint256 => uint256) private _prices;
    
    // Mapping from tokenId to edition number
    mapping(uint256 => uint256) private _editionNumbers;

    // Mapping from tokenId to the token it was claimed from
    mapping(uint256 => uint256) private _claimedFromTokens;

    // Mapping from tokenId to the tokens that are claims of this token
    mapping(uint256 => EnumerableSet.UintSet) private _claimedTokens;


    bool locked;
    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    constructor (string memory name, string memory symbol) ERC721(name, symbol) {}


    /**
    * @dev Claim next edition number of a claimable token.
    * The price increase by percentage specified in _percentPriceIncreasePerClaim[tokenId] after each claim.
    */
    function claim(uint256 tokenId) external payable noReentrancy {
        require(_exists(tokenId), "claim: Nonexistent token.");
        require(_maximumEditions[tokenId] > _editions[tokenId], "claim: Maximum supply already met.");
        require(msg.value >= _prices[tokenId], "claim: Insufficient amount to claim.");
        require(_prices[tokenId] > 0, "claim: Claim start price not set yet.");

        uint256 collectionId = _tokenCollection[tokenId];

        if(_collectionWithdrawOnBurnTokens[collectionId].length() > 0)
        { // If this collection still has tokens that will withdraw when burned, then add amount to collection balance
            _collections[collectionId].balance+=_prices[tokenId];
        }
        else
        { // If now withdraw on burn tokens exists, add to contract owner balance
            ownerBalance+=_prices[tokenId];
        }

        // If more than price was sent, we return the reaminig amout to the sender at the end of this function
        uint256 remains = msg.value.sub(_prices[tokenId]);
        
        // Make next claim more expensive
        _prices[tokenId] += _prices[tokenId].mul(_percentPriceIncreasePerClaim[tokenId]).div(100);
        
        // Mint the claim
        _mintClaim(msg.sender, tokenId);

        // Refund exceeding amount
        if(remains > 0){
            msg.sender.transfer(remains);    
        }
        
    }
    
    
    /**
    * @dev sets tokenClaimStartPrice for a tokenId.
    * This is the price for the first claim and can only be set before any claims are made.
    */
    function setTokenClaimStartPrice(uint256 tokenId, uint256 price) external onlyOwner {
        require(_exists(tokenId), 'setTokenClaimStartPrice: Nonexisting token.');
        require(_maximumEditions[tokenId] > 1, 'setTokenClaimStartPrice: Unclaimable token.');
        require(_editions[tokenId] == 1, 'setTokenClaimStartPrice: Start price can not be set after first claim.');
        _prices[tokenId] = price;
    }
    
    /**
    * @dev Returns true if this token is claimable, meaning it can have or actually have _maximumEditions[tokenId] > 1
    */
    function isClaimable(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), 'setTokenClaimStartPrice: Nonexisting token.');
        if(_maximumEditions[tokenId] > 1)
        {
            return true;
        }
        else{
            return false;
        }
    }
    
    
    /**
    * @dev Mint token to an address and include it to the given collection.
    * tokenURI must be IPFS hash of metadata.json. 
    * contentURI must be IPFS hash of the actuall token content (the art piece).
    * If withdrawOnBurn is set to true, then token owner will receive collection balance, if any, when token is burned. 
    */
    function _mintClaim(address to, uint tokenId) private {
        require(to != address(0), "mintClaim: Cannot mint to zero address.");
        require(_exists(tokenId), "mintClaim: Nonexistent tokenId.");

        // Mint the token
        uint256 claimTokenId = _getNextTokenId();
        _safeMint(to, claimTokenId, "");
        _incrementTokenId();
        
        // Increase edition for source token and set edition number for claimed token
        uint256 editionNumber_ = _editions[tokenId].add(1);
        _editions[tokenId] = editionNumber_;
        _editionNumbers[claimTokenId] = editionNumber_;

        // Set tokenURI, contentURI and withdrawOnBurn to the same as source token
        _setTokenURI(claimTokenId, _tokenURIs[tokenId]);
        _contentURIs[claimTokenId] = _contentURIs[tokenId];
        _withdrawOnBurn[claimTokenId] = _withdrawOnBurn[tokenId];
        
        // Add token to same collection as source token
        _addTokenToCollection(claimTokenId, tokenCollection(tokenId));
        
        // Add claimed token to mapping with source token as key
        _claimedTokens[tokenId].add(claimTokenId);

        // Add to mapping used to retrieve the source tokenId
        _claimedFromTokens[claimTokenId] = tokenId;

    }

    function editionNumber(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "editionNumber: Nonexistent tokenId.");

        return _editionNumbers[tokenId];
        
    }
    
    function maximumEdition(uint256 tokenId) external view returns (uint256) {
        if(_editionNumbers[tokenId] > 1){
           return _maximumEditions[_claimedFromTokens[tokenId]];
        }
        return _maximumEditions[tokenId];
    }
    
    function currentEdition(uint256 tokenId) external view returns (uint256) {
        if(_editionNumbers[tokenId] > 1){
           return _editions[_claimedFromTokens[tokenId]];
        }
        return _editions[tokenId];
    }
    
    /**
    * @dev sets tokenURI for a tokenId. It is necessary for the contract owner to be able to alter this, since 
    * third parties like opensesa requires baseURI to be part of the offchain metadata. So to avvoid "page not found" in the future
    * setTokenURI must be callable. However, contentURI (that is the IPFS hash of the art piece, can never be changed.)
    */
    function getTokenClaimPrice(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), 'getTokenClaimPrice: Nonexisting token.');
        return _prices[tokenId];
    }


    
    /**
    * @dev Returns the total number of collections ever created
    */
    function numberOfCollections() external view returns (uint256) {
        return _collections.length;
    }
    
    /**
    * @dev Returns title, description and balance for collectionId
    */
    function collection(uint256 collectionId) external view returns (string memory title, string memory description, uint256 balance) {
        require(_collectionExists(collectionId), "collection: Nonexistent collection.");
        return (_collections[collectionId].title, _collections[collectionId].description, _collections[collectionId].balance);
    }

    
    /**
    * @dev Returns true if collection is closed, false otherwise. Only open collections can be minted to.
    *  Owner can only close a collection, never open it. Once closed, it is closed forever.
    */
    function collectionIsClosed(uint256 collectionId) public view returns (bool) {
        return _collections[collectionId].closed;
    }

    
    /**
    * @dev Returns the total amount of tokens stored in the given collection.
    */
    function collectionSupply(uint collectionId) external view returns (uint256) {
        return _collectionTokens[collectionId].length();
    }

    /**
    * @dev Returns the total amount of tokens that have withdrawOnBurn set to true and belongs to the given collection.
    */
    function collectionWithdrawOnBurnSupply(uint collectionId) public view returns (uint256) {
        return _collectionWithdrawOnBurnTokens[collectionId].length();
    }
    
    /**
     * @dev Returns a token ID in collection at a given `index` of its token list.
     * Use along with {collectionSupply} to enumerate all of ``collection``'s tokens.
     */
    function tokenInCollectionByIndex(uint collectionId, uint256 index) external view returns (uint256) {
        return _collectionTokens[collectionId].at(index);
    }
    
    
    /**
    * @dev Returns the collection ID for the given token id
    */
    function tokenCollection(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "tokenCollection: Nonexistent token");
        require(_collectionExists(_tokenCollection[tokenId]), "tokenCollection: Nonexistent collection.");
        return _tokenCollection[tokenId];
    }
    
    /**
    * @dev Returns a hash of the title. Is used by function that checks if collection title already exists.
    */
    function _collectionHashFromTitle(string memory title) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(title));
    }

    /**
    * @dev Create a new collection it will be created as open and with balance equal to zero
    */
    function createCollection(string memory title, string memory description) external onlyOwner
    {
        require(_collectionIdsPlusOne[_collectionHashFromTitle(title)] == 0,"createCollection: Title already exists");
        uint256 collectionId = _collections.length;

        _collections.push(Collection(title, description, 0, false));
        
        // Save collectionId + 1 since mapping default to zero
        _collectionIdsPlusOne[_collectionHashFromTitle(title)] = collectionId.add(1);
    }
    
    /**
    * @dev Close an open collection. It is not possible to mint tokens to closed collections and a closed collection cannot be opened again.
    */
    function closeCollection(uint256 collectionId) external onlyOwner
    {
        require(_collectionExists(collectionId), "closeCollection: Nonexistent collection.");
       _collections[collectionId].closed = true;
    }
    
 
    /**
    * @dev Returns collectionId from title
    */
    function collectionIdFromTitle(string memory title) external view returns (uint256)
    {
        // Subtract one since mappings stores collectionId + 1
        uint256 _collectionId = _collectionIdsPlusOne[_collectionHashFromTitle(title)].sub(1);
        require(_collectionExists(_collectionId), "collectionIdFromTitle: Nonexistent collection.");
        return _collectionId;
    }
    
    /**
     * @dev Returns whether `collectionId` exists.
     *
     *
     * Collections start existing when they are added to the Collections array
     */
    function _collectionExists(uint256 collectionId) private view returns (bool) {
        return collectionId < _collections.length;
    }
    
    /**
    * @dev Mint token to an address and include it to the given collection.
    * tokenURI must be IPFS hash of metadata.json. 
    * contentURI must be IPFS hash of the actuall token content (the art piece).
    * If withdrawOnBurn is set to true, then token owner will receive collection balance, if any, when token is burned. 
    */
    function mintTo(address to, string memory _tokenURI, string memory _contentURI, bool withdrawOnBurn_, uint256 collectionId, uint256 _maximumEdition, uint8 percentPriceIncreasePerClaim) external onlyOwner {
        require(_collectionExists(collectionId), "mintTo: Nonexistent collection.");
        require(!collectionIsClosed(collectionId), "mintTo: Collection is closed.");
        require(bytes(_tokenURI).length > 0, "mintTo: tokenURI cannot be empty.");
        require(bytes(_contentURI).length > 0, "mintTo: contentURI cannot be empty.");
        require(_maximumEdition > 0, "mintTo: MaximumEdition must at least be one.");

        // Mint token
        uint256 tokenId = _getNextTokenId();
        _safeMint(to, tokenId, "");
        _incrementTokenId();

        // Set tokenURI, contentURI and withdrawOnBurn
        _setTokenURI(tokenId, _tokenURI);
        _contentURIs[tokenId] = _contentURI;
        _withdrawOnBurn[tokenId] = withdrawOnBurn_;
        
        _addTokenToCollection(tokenId, collectionId);
        
        _maximumEditions[tokenId] = _maximumEdition;
        _editions[tokenId]=1;
        _editionNumbers[tokenId]=1;    
        _percentPriceIncreasePerClaim[tokenId] = percentPriceIncreasePerClaim;
        
    }

    /**
    * @dev As part of minting, the token must be added to a collection. This is a helper function to do so. 
    */    
    function _addTokenToCollection(uint256 tokenId, uint256 collectionId) internal {
        _tokenCollection[tokenId] = collectionId;
        _collectionTokens[collectionId].add(tokenId);
        
        // If token is burnable we must add it to the list of burnable tokens in collection
        if(_withdrawOnBurn[tokenId]){
            _collectionWithdrawOnBurnTokens[collectionId].add(tokenId);
        }
        
    }

    /**
    * @dev calculates the next token ID based on value of _currentTokenId
    * @return uint256 for the next token ID
    */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
    * @dev increments the value of _currentTokenId
    */
    function _incrementTokenId() private {
        _currentTokenId++;
    }


   
    
    /**
    * @dev return the contentURI. Will concatenated with nonempty _collectionContentBaseURIs[collectionId].
    */
    function contentURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "contentURI: Nonexistent token");

        string memory _contentURI = _contentURIs[tokenId];
        uint256 collectionId = _tokenCollection[tokenId];

        // If there is no base URI, return the token content URI.
        if (bytes(_collectionContentBaseURIs[collectionId]).length == 0) {
            return _contentURI;
        }
        
        // Else, concatenate the baseURI and tokenURI (via abi.encodePacked).
        return string(abi.encodePacked(_collectionContentBaseURIs[collectionId], _contentURI));
        
    }
    
    
    /**
    * @dev Returns true if tokenId has withdrawOnBurn set to true. Meaning, token owner will receive
    * collection balance when token is burned.
    */
    function willWithdrawWhenBurned(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "willWithdrawWhenBurned: Nonexistent token");
        return _withdrawOnBurn[tokenId];
    }
     
    /**
    * @dev Use this to deposit ETH to a collection's balance. 
    * It is only possible to send ETH to a collection that exists and that have at least one token with withdrawOnBurn equal to true
    */
    function deposit(uint256 collectionId) external payable {
        require(_collectionExists(collectionId), "deposit: Nonexistent collection.");
        require(collectionWithdrawOnBurnSupply(collectionId) > 0, "deposit: No WithdrawOnBurn tokens in collection");
        _collections[collectionId].balance+=msg.value;
    }

    /**
    * @dev Fallback that will ensure ETH transfered to the contract that are not depsoits to some collection can be withdrawn by contract owner.
    */
    fallback() external payable { ownerBalance+=msg.value; }

    /**
    * @dev Contract can recieve, and contract owner withdraw, ETH that are not deposits to a collection balance.
    */
    receive() external payable {
        ownerBalance+=msg.value;
    }

    /**
    * @dev Contract owner can withdraw contract balance excluding the amount held by collection balances.
    */
    function withdraw() external onlyOwner noReentrancy {
        uint256 value = ownerBalance;
        ownerBalance=0;
        payable(owner()).transfer(value);
    }
    
    /**
    * @dev returns contractURI used to get contract metadata by third parties like opensea
    */
    function contractURI() external view returns (string memory) {
         
        // If there is no base URI, return _contractURI (that is only the hash).
        if (bytes(baseURI()).length == 0) {
            return _contractURI;
        }
        
        return string(abi.encodePacked(baseURI(), _contractURI));
    
    }
    
    /**
    * @dev sets tokenURI for a tokenId. It is necessary for the contract owner to be able to alter this, since 
    * third parties like opensesa requires baseURI to be part of the offchain metadata. So to avvoid "page not found" in the future
    * setTokenURI must be callable. However, contentURI (that is the IPFS hash of the art piece, can never be changed.)
    */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);  
    }

    /**
    * @dev set contractURI. A url to offline metadata with information like contract logo/image, description.
    * Used by thirdparties like opensea.
    */
    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }
    

    /**
    * @dev sets the baseURI which is concatenated with tokenURI and contractURI when calls are made to retrieve them from the contract.
    */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
    * @dev sets the collectionContentBaseURI which is concatenated with contentURI when calls are made to retrieve them from the contract.
    */
    function setCollectionContentBaseURI(uint256 collectionId, string memory contentBaseURI) external onlyOwner {
        require(_collectionExists(collectionId), "setCollectionContentBaseURI: Nonexistent collection.");
        _collectionContentBaseURIs[collectionId] = contentBaseURI;
    }
    
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     * - `tokenId` must exist.
     */
    function burn(uint256 tokenId) external noReentrancy  {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        require(_exists(tokenId), "burn: Query for nonexistent token");

        uint256 _collectionId = _tokenCollection[tokenId];

        // Clear custom metadata (if any)
        if (bytes(_contentURIs[tokenId]).length != 0) {
            delete _contentURIs[tokenId];
        }
        
        delete _maximumEditions[tokenId];
        delete _editionNumbers[tokenId];
        delete _percentPriceIncreasePerClaim[tokenId];
        delete _tokenCollection[tokenId];
        
        
        _collectionTokens[_collectionId].remove(tokenId);
        address payable tokenOwner = payable(ownerOf(tokenId));
        
        _burn(tokenId);

        // Clear data if token is a token claimed from another
        if(_claimedFromTokens[tokenId] > 0){
            _claimedTokens[_claimedFromTokens[tokenId]].remove(tokenId);
            delete _claimedFromTokens[tokenId];
            delete _editionNumbers[tokenId];
        }


        if(_withdrawOnBurn[tokenId]) {
            // Remove from list of collections withdrawOnBurnTokens
            _collectionWithdrawOnBurnTokens[_collectionId].remove(tokenId);
            
            // Reset metadata
           delete _withdrawOnBurn[tokenId];
            
            // transfer collection balance to token owner and set balance to zero.
            uint256 _collectionBalance = _collections[_collectionId].balance;
            if(_collectionBalance > 0){
                _collections[_collectionId].balance = 0;
                tokenOwner.transfer(_collectionBalance);
            }
            
        }
        
    }
    

}
