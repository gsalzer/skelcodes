// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";



contract Buffalos is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    // Time of when the sale starts.
    uint256 public blockStart;

    // Maximum amount of Buffalos in existance. 
    uint256 public MAX_SUPPLY;
    uint256 public cost;
    uint256 public maxMintAmount;
    uint256 public BASE_RATE = 10 ** 18;
    
    address public artist;
    address public txFeeToken;

    string public baseURI;
    // string public nftName;
    // string public nftUnit;
    string public uri;
    string public metaDataExt = ".json";

    bool public mintable = true;
    bool public publicSale = false;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public tokenBalance;
    mapping(address => bool) public excludedList;

    event BuffaloBought (address buyer, uint256 amount);

    constructor(
        string memory name, 
        string memory symbol, 
        string memory URI,
        uint256 initialSupply, 
        uint256 startDate,
        address _artist,
        address _txFeeToken,
        uint _txFeeAmount,
        uint256 _limitPerAddress 
    ) ERC721(name, symbol) {
        setBaseURI(URI);
        setBlockStart(startDate);

        artist = _artist;
        txFeeToken = _txFeeToken;
        // excludedList[artist] = true;
        BASE_RATE = _txFeeAmount * 10 ** 15;
        maxMintAmount = _limitPerAddress;

        MAX_SUPPLY = initialSupply;        
        // Mint 30 Buffalos for airdrop and gift purposes
    }

    // public
    function getNFTPrice(uint256 amount) public view returns (uint256) {
        return amount.mul(BASE_RATE);
    }

    function setExcluded(address excluded, bool status) external {
        require(msg.sender == artist, 'artist only');
        excludedList[excluded] = status;
    }

    function setBlockStart(uint256 startDate) public {
        blockStart = startDate;
    }

    function updateBlockStart(uint256 startDate) onlyOwner public {
        // require(block.timestamp <= blockStart, "Sale has already started.");
        blockStart = startDate;
    }

    function getBlockStart() public view returns (uint256)  {
        return blockStart;
    }

    function getMaxSupply() public view returns (uint256)  {
        return MAX_SUPPLY;
    }

    // function ApproveContract() public {
    //     IERC20 token = IERC20(txFeeToken);
    //     token.approve(address(this), 1000 * 10 ** 18);
    // }
    /**
    * @dev Mints yourself a Buffalo. Or more.
    */
    function mint(uint256 numberofBuffalos) public payable {
        // Some exceptions that need to be handled.
        require(block.timestamp >= blockStart, "Exception 1: Sale has not started yet so you can't get a price yet.");
        if(!publicSale) {
            require(whitelisted[msg.sender], "Exception 2: Signer should be whitelisted.");
        }
        require(totalSupply() < MAX_SUPPLY, "Exception 3: Sale has already ended.");
        require(numberofBuffalos > 0, "Exception 4: You cannot mint 0 Buffalos.");
        require(SafeMath.add(totalSupply(), numberofBuffalos) <= MAX_SUPPLY, "Exception 5: Exceeds maximum Buffalos supply. Please try to mint less Buffalos.");  
        require(tokenBalance[msg.sender] < maxMintAmount, "Exception 6: Reached the limit for each user. You can't mint no more");      
        require(SafeMath.add(tokenBalance[msg.sender], numberofBuffalos) <= maxMintAmount, "Exception 7: Exceeds limit for each user. Please try to mint less Buffalos.");
        
        // require(token.transferFrom(msg.sender, artist, getNFTPrice(numberofBuffalos)), "token transfer failed");        
        
        for(uint256 i=0; i<numberofBuffalos; i++) {
            _safeMint(msg.sender, totalSupply());
            tokenBalance[msg.sender] = SafeMath.add(tokenBalance[msg.sender], 1);
        }
        emit BuffaloBought(msg.sender, numberofBuffalos);
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    
    function canMint(bool mintFlag) onlyOwner public {
        mintable = mintFlag;
    }

    function withdraw(uint256 amount) onlyOwner public {
        payable(artist).transfer(amount);
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeBaseURI(string memory URI) onlyOwner public {
       setBaseURI(URI);
    }
    /**
    * @dev Changes max supply based on future drop dates (owner only)
    */
    function changeMaxSupply(uint256 supply) onlyOwner public {
        MAX_SUPPLY = supply;
    }

    function changePublicSaleState(bool flag) onlyOwner public {
        publicSale = flag;
    }

    function updateMintPrice(uint256 price) onlyOwner public {
        BASE_RATE = price * 10 ** 15;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function checkWhitelisted(address _user) public view returns (bool) {
        return whitelisted[_user];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), metaDataExt))
            : "";
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) onlyOwner public {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) onlyOwner public {
        baseURI = _newBaseURI;
    }

    function whitelistUser(address _user) onlyOwner public {
        if(!whitelisted[_user]) tokenBalance[_user] = 0;
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) onlyOwner public {
        whitelisted[_user] = false;
    }

}
