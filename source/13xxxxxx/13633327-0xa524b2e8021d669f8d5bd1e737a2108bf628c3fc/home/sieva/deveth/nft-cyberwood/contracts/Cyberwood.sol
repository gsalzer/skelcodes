pragma solidity ^0.7.0;


import "../node_modules/@openzeppelin/contracts/introspection/IERC165.sol";
import "../node_modules/@openzeppelin/contracts/introspection/ERC165.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
//import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
//import "../node_modules/@openzeppelin/contracts/utils/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
//import "../node_modules/@openzeppelin/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/utils/EnumerableMap.sol";
import "../node_modules/@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

import "./ICyberwood.sol";


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract Cyberwood is Context,Ownable, ERC165,ICyberwood, IERC721Metadata {


    /**
    Received event when it receives ether in exchange for one of the non-fungible tokens
    Sent event when funds are withdrawn from the contract’s ether balance
     */
     using EnumerableSet for EnumerableSet.UintSet;
     using EnumerableMap for EnumerableMap.UintToAddressMap;
     using SafeMath for uint256;
     using Address for address;
     using Strings for uint256;


    string public  CYBER_PROVENANCE = "eeeeee";

    //removing constant here
    uint256 public  MAX_NFT_SUPPLY_PRESALE = 4444 ;
    uint256 public  MAX_NFT_SUPPLY_FULLSALE = 8888 ;
    uint256 public VIP_WHITELISTING_SUPPLY = 500;


    uint256 public  MAX_NFT_ATONCE_PRESALE = 4;
    uint256 public  MAX_NFT_ATONCE_FULLSALE = 5;

    uint256 public WLtracker = 0;
    uint256 public VIP_WHITELISTING_SUPPLY_counter = 0;


    uint256 public CyberwoodNFTPrice = 88000000000000000; // 0.088 ETH
    uint256 public VIPAccessPrice =    11000000000000000; // 0.011 ETH

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;


    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping(address => bool) public whitelist;



    // Token name
    string private _name;

    // Token symbol
    string private _symbol;


    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     *      CB style
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;



    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;


    // FullSale status
    bool public FullSaleOK = false;

    // PreSale status
    bool public PreSaleOK = false;

    // PreSale status
    bool public VIPWhiteListingOpen = true;

    // PreSale multi
    bool public PreSaleMulti = true;


    /**
   * @dev Throws if called by any account is not whitelisted.
   */
      modifier onlyWhitelisted() {
        require(whitelist[msg.sender],"Sorry, but this address is not on the whitelist. Please message us on Discord.");
        _;
      }



       /**
         WhiteList Addresses
        */
      function addAddressesToWhiteList(address[] memory addresses) public onlyOwner
      {
       for(uint i =0;i<addresses.length;i++)
           {


                 if ( whitelist[addresses[i]] !=true ) {

                     whitelist[addresses[i]]=true;
                     WLtracker=WLtracker+1;

                   }



           }
      }



      /*
       Whitelist SingleAddress
       */

      function VIPAddAddressToWhiteList() public payable
      {
          require(VIPWhiteListingOpen, "VIP Whitelisting is closed.");
          require(VIP_WHITELISTING_SUPPLY_counter < VIP_WHITELISTING_SUPPLY, "Number of VIP spots reached.");
          require(VIPAccessPrice == msg.value, "Ether value incorrect" );

          //cannot whitelist the same twice via VIP route
         require(whitelist[msg.sender] != true, "Address whitelisted already" );


          whitelist[msg.sender]=true;
          VIP_WHITELISTING_SUPPLY_counter = VIP_WHITELISTING_SUPPLY_counter+1;
          WLtracker=WLtracker+1;

      }




      /**
        Remove from whitelist
       */
      function removeAddressFromWhiteList(address  userAddress) public onlyOwner
      {
          whitelist[userAddress]=false;
          WLtracker=WLtracker-1;
      }


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor () {

        _name = "Cyberwood2088";
        _symbol = "CWOOD";
        _baseURI = "https://www.cyberwood2088.com/api/v1/videos/";


        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }



    /**
     * @dev Can update price
     */
    function setPrice(uint256 _newprice) public onlyOwner {
        CyberwoodNFTPrice = _newprice;
    }

    /**
     * @dev Can update price
     */
    function setVIPAccessPrice(uint256 _newprice) public onlyOwner {
        VIPAccessPrice = _newprice;
    }


    /**
     * @dev Can update price
     */
    function setVIPWhitelistSupply(uint256 _newsupply) public onlyOwner {
        VIP_WHITELISTING_SUPPLY = _newsupply;
    }



    /**
     * @dev Can update MAX NFT SUPPLY
     */
    function setMaxTokens(uint256 _maxTokens) public onlyOwner {
        MAX_NFT_SUPPLY_FULLSALE = _maxTokens;
    }


    /**
     * @dev Can update MAX NFT SUPPLY PRESALE
     */
    function setMaxTokensPresale(uint256 _maxTokens) public onlyOwner {
        MAX_NFT_SUPPLY_PRESALE = _maxTokens;
    }


    /**
     * @dev Can update MAX_NFT_ATONCE_PRESALE
     */
    function setNFTBatchPreSale(uint256 _maxTokens) public onlyOwner {
        MAX_NFT_ATONCE_PRESALE = _maxTokens;
    }

    /**
     * @dev Can update MAX_NFT_ATONCE_FULLSALE
     */
    function setNFTBatchFullSale(uint256 _maxTokens) public onlyOwner {
        MAX_NFT_ATONCE_FULLSALE  = _maxTokens;
    }




    /**
     * @dev toggle the Full-sale
     */


     function restartFullSale() public onlyOwner {
         FullSaleOK = true;
     }

     function pauseFullSale() public onlyOwner {
         FullSaleOK = false;
     }



     /**
      * @dev toggle the PreSaleMulti
      */


      function restartPreSaleMulti() public onlyOwner {
          PreSaleMulti = true;
      }

      function pausePreSaleMulti() public onlyOwner {
          PreSaleMulti = false;
      }


     /**
      * @dev toggle the Pre-sale
      */


     function restartPreSale() public onlyOwner {
         PreSaleOK = true;
     }

     function pausePreSale() public onlyOwner {
         PreSaleOK = false;
     }




      /**
       * @dev toggle the Pre-sale
       */


      function restartVIPWhitelisting() public onlyOwner {
          VIPWhiteListingOpen = true;
      }

      function pauseVIPWhitelisting() public onlyOwner {
          VIPWhiteListingOpen = false;
      }




    function regularMint(uint256 numberOfNfts)


       public payable

        {

         //sale is on
         require(FullSaleOK, "Sale is not active");

          // the total supply cannot exceed the max nft supply
          require(totalSupply() < MAX_NFT_SUPPLY_FULLSALE, "Sale is Sold Out");

          //quantity checks
          require(numberOfNfts > 0, "numberOfNfts cannot be 0");
          require(numberOfNfts <= MAX_NFT_ATONCE_FULLSALE, "You may not buy more than XX NFTs at once at FULL SALE");

          //Amount transferred must be correct
          require(CyberwoodNFTPrice.mul(numberOfNfts) == msg.value, "Ether value sent is not correct - wow" );

          //Cannot buy-overflow
          require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY_FULLSALE, "Exceeds MAX_NFT_SUPPLY_FULLSALE");



          for (uint i = 0; i < numberOfNfts; i++) {
              uint mintIndex = this.totalSupply();

              if (totalSupply() < MAX_NFT_SUPPLY_FULLSALE) {
                    _safeMint(msg.sender, mintIndex);
                }
          }


    }



    function PreSaleMintFromWhiteList(uint256 numberOfNfts) public payable onlyWhitelisted {

        require(PreSaleOK, "Sorry, but the presale minting is not available now.");
        require(totalSupply() < MAX_NFT_SUPPLY_PRESALE, "Pre-Sale is Sold Out");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= MAX_NFT_ATONCE_PRESALE,"Sorry, but you can only mint XX tokens during the presale minting.");
        require(CyberwoodNFTPrice.mul(numberOfNfts) == msg.value, "Ether value sent is not correct - wow" );
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY_PRESALE, "Exceeds MAX_NFT_SUPPLY_PRESALE");


         for (uint i = 0; i < numberOfNfts; i++) {
             uint mintIndex = this.totalSupply();

             if (totalSupply() < MAX_NFT_SUPPLY_PRESALE) {
                   _safeMint(msg.sender, mintIndex);
               }
         }


     if (PreSaleMulti == false){
         whitelist[msg.sender]=false;
     }


    }



    function BulkManualMint(address to, uint256 msize) public onlyOwner {



        require(totalSupply().add(msize) <= 8888, "Exceeded collection size supply");

        uint256 index;

        for (index = 0; index < msize; index++) {

            uint mintIndex = this.totalSupply();

            _safeMint(to, mintIndex);


        }


    }


   // Function to return sum of
   // elements of dynamic array
   function getSum(uint256[] memory arr) public view returns(uint)
   {
     uint i;
     uint sum = 0;

     for(i = 0; i < arr.length; i++)
       sum = sum + arr[i];
     return sum;
   }


    function BulkManualMintFromList(address[] memory addresses, uint256[] memory msizes) public onlyOwner {


        uint sumarray=getSum(msizes) ;

        require(totalSupply().add(sumarray) <= 8888, "The sum of tokens added exceeds current supply");

        uint256 index;
        uint256 userid;


        for (userid = 0; userid < msizes.length; userid++){


            for (index = 0; index < msizes[userid]; index++) {

                uint mintIndex = this.totalSupply();

                _safeMint(addresses[userid], mintIndex);

            }


        }

    }




    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }


    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }


    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }


    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }



    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");


        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }


    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }



    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /** custom function to reset the base URI if required**/

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override  returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }


    /**
     * @dev BELOW - ERC721 -- from OZ
     */



    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override  returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */



    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }



    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
     function _exists(uint256 tokenId) internal view returns (bool) {
         return _tokenOwners.contains(tokenId);
     }

     /**
      * @dev Returns whether `spender` is allowed to manage `tokenId`.
      *
      * Requirements:
      *
      * - `tokenId` must exist.
      */
     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
         require(_exists(tokenId), "ERC721: operator query for nonexistent token");
         address owner = ownerOf(tokenId);
         return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
     }

     /**
      * @dev Safely mints `tokenId` and transfers it to `to`.
      *
      * Requirements:
      d*
      * - `tokenId` must not exist.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
     function _safeMint(address to, uint256 tokenId) internal virtual {
         _safeMint(to, tokenId, "");
     }

     /**
      * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
      * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
      */
     function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
         _mint(to, tokenId);
         require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
     }


     /**
      * @dev Mints `tokenId` and transfers it to `to`.
      *
      * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
      *
      * Requirements:
      *
      * - `tokenId` must not exist.
      * - `to` cannot be the zero address.
      *
      * Emits a {Transfer} event.
      */
     function _mint(address to, uint256 tokenId) internal virtual {
         require(to != address(0), "ERC721: mint to the zero address");
         require(!_exists(tokenId), "ERC721: token already minted");

         _beforeTokenTransfer(address(0), to, tokenId);

         _holderTokens[to].add(tokenId);

         _tokenOwners.set(tokenId, to);

         emit Transfer(address(0), to, tokenId);
     }

     /**
      * @dev Transfers `tokenId` from `from` to `to`.
      *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
      *
      * Requirements:
      *
      * - `to` cannot be the zero address.
      * - `tokenId` token must be owned by `from`.
      *
      * Emits a {Transfer} event.
      */
     function _transfer(address from, address to, uint256 tokenId) internal virtual {
         require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
         require(to != address(0), "ERC721: transfer to the zero address");

         _beforeTokenTransfer(from, to, tokenId);

         // Clear approvals from the previous owner
         _approve(address(0), tokenId);

         _holderTokens[from].remove(tokenId);
         _holderTokens[to].add(tokenId);

         _tokenOwners.set(tokenId, to);

         emit Transfer(from, to, tokenId);
     }


     /**
      * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
      * The call is not executed if the target address is not a contract.
      *
      * @param from address representing the previous owner of the given token ID
      * @param to target address that will receive the tokens
      * @param tokenId uint256 ID of the token to be transferred
      * @param _data bytes optional data to send along with the call
      * @return bool whether the call correctly returned the expected magic value
      */
     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
         private returns (bool)
     {
         if (!to.isContract()) {
             return true;
         }
         bytes memory returndata = to.functionCall(abi.encodeWithSelector(
             IERC721Receiver(to).onERC721Received.selector,
             _msgSender(),
             from,
             tokenId,
             _data
         ), "ERC721: transfer to non ERC721Receiver implementer");
         bytes4 retval = abi.decode(returndata, (bytes4));
         return (retval == _ERC721_RECEIVED);
     }


     function _approve(address to, uint256 tokenId) private {
         _tokenApprovals[tokenId] = to;
         emit Approval(ownerOf(tokenId), to, tokenId);
     }

     /**
      * @dev Hook that is called before any token transfer. This includes minting
      * and burning.
      *
      * Calling conditions:
      *
      * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
      * transferred to `to`.
      * - When `from` is zero, `tokenId` will be minted for `to`.
      * - When `to` is zero, ``from``'s `tokenId` will be burned.
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      *
      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
      */
     function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }



}

