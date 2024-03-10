pragma solidity ^0.8.0;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

import "../interfaces/community_interface.sol";


import "../recovery/recovery.sol";
import "../interfaces/IRNG.sol";


import "../ec_configuration/ec_configuration.sol";

import "../ec_token/ec_token_interface.sol";

import "hardhat/console.sol";


contract ec_sale is ec_configuration, Ownable, recovery , ReentrancyGuard, IERC777Recipient {
    using SafeMath for uint256;
    using Strings  for uint256;

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    ec_token_interface          _token;

    bool                        _saleActive;
    bool                        _presaleActive;
    bool                        _dustMintActive;

    uint256                     immutable _MaxUserMintable;
    uint256                     _userMinted;

    uint256                     _ts1;
    uint256                     _ts2;

    address             public  _communityAddress;

    mapping(uint256 => bool) public   _claimed;


    address         immutable public  _DUST;
    IERC721         immutable public  _EC;


    mapping (address => uint256)        _freeClaimedPerWallet;
    mapping (address => uint256)        _discountedClaimedPerWallet;
    mapping (address => uint256)        _dusted;
    


    event RandomProcessed(uint stage,uint256 randUsed_,uint256 _start,uint256 _stop,uint256 _supply);
    event DustPayment(uint256 quantity, uint256 value);
    event Allowed(address,bool);

     modifier onlyAllowed() {
        require(_token.permitted(msg.sender) || (msg.sender == owner()),"Unauthorised");
        _;
    }

    constructor( ec_token_interface _token_ ,IERC721 _ec, address _dust) {
        _EC = _ec;
        _token = _token_;
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        _DUST = _dust;
        _MaxUserMintable = _maxSupply - (_clientMintLimit + _ecMintLimit);
    }

    receive() external payable {
        _split(msg.value);
    }

    function _split(uint256 amount) internal {
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = amount * _shares[j] / 1000;
            if (j == _wallets.length-1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            ( sent, ) = _wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }

    function mintAdvanced(bool clientMint, uint256 number, address destination) external onlyAllowed {
        
        uint256 position;
        uint256 limit;
        if (clientMint) {
            position    = _clientMintPosition;
            limit       = _clientMintLimit;
        } else {
            destination = _ecVault;
            position    = _ecMintPosition;
            limit       = _ecMintLimit;
        }
        require(position<limit,"All minted or no allowance");
        uint count = position+number<limit ? number : limit-position;
        _mintCards(count,destination);
        
         if (clientMint) {
             _clientMintPosition = position+count;
         } else {
             _ecMintPosition = position+count;
         }
    }

    function mintFreePresaleWithEtherCards(uint256[] memory tokenIds) external {
        require(checkPresaleIsActive(),"presale not open");
        uint256 numberOfCards = eligibleTokens(tokenIds);
        uint tfec = _totalFreeEC + numberOfCards;
        require(tfec <= _maxFreeEC, "EC allocation exceeded");
        _freeClaimedPerWallet[msg.sender] += numberOfCards;
        require(_freeClaimedPerWallet[msg.sender] <= _freePerAddress, "Max free per address exceeded");
        _totalFreeEC = tfec;
        _mintCards(numberOfCards,msg.sender);
    }

    function mintDiscountPresaleWithEtherCards(uint256 numberOfCards) external payable {
        require(checkPresaleIsActive(),"presale not open");
        require (_EC.balanceOf(msg.sender) > 0,"You do not hold Ether Cards");
        _discountedClaimedPerWallet[msg.sender] += numberOfCards;
        require(_discountedClaimedPerWallet[msg.sender] <= _discountedPerAddress,"Number exceeds max discounted per address");
        _totalDiscount += numberOfCards;
        require(_maxDiscount >= _totalDiscount,"Too many discount tokens claimed");
        _mintPayable(numberOfCards, msg.sender, _discountPrice);
    }


    // make sure this respects ec_limit and client_limit
    function mint(uint256 numberOfCards) external payable {
        require(checkSaleIsActive(),"sale is not open");
        require(numberOfCards <= _maxPerSaleMint,"Exceeds max per Transaction Mint");
        _mintPayable(numberOfCards, msg.sender, _fullPrice); 
    }


    function _mintPayable(uint256 numberOfCards, address recipient, uint256 price) internal {
        require(msg.value >= numberOfCards.mul(price),"price not met");
        _mintCards(numberOfCards,recipient);
        _split(msg.value);
    }

    function _mintCards(uint256 numberOfCards, address recipient) internal {
        _userMinted += numberOfCards;
        require(_userMinted <= _MaxUserMintable,"This exceeds maximum number of user mintable cards");
        _token.mintCards(numberOfCards,recipient);
    }

    // Mint With DUST
    function tokensReceived(
        address ,
        address from,
        address ,
        uint256 amount,
        bytes calldata ,
        bytes calldata
      ) external override nonReentrant {

            require(checkSaleIsActive(),"sale is not open");
            require(_dustMintAvailable,"dust minting not available");
            require(msg.sender == _DUST, "Unauthorised");

            uint256 tokenCount = amount/_dustPrice;
            require(tokenCount > 0, "No. of tokens <= zero");

            _dusted[from] += tokenCount;

            require(_dusted[from]<=_dustPerAddress, "Too many minted by dust"); 

            _mintCards(tokenCount,from);
            
            uint256 _total;
            for (uint256 j = 0; j < _wallets.length; j++) {
                uint256 _amount = amount * _shares[j] / 1000;
                if (j == _wallets.length-1) {
                    _amount = amount - _total;
                } else {
                    _total += _amount;
                }
                IERC777(_DUST).send(_wallets[j],_amount,bytes("Dust Minting")); 
            }
            emit DustPayment(tokenCount, amount);
    }

    // and to mint from the community contract

    function setCommunity(address community) external onlyAllowed {
        _communityAddress = community;
        _token.setAllowed(community,true);
    }

    function communityPurchase(uint256 tokenCount, bytes memory signature, uint256 role) external payable {
        require(_communityAddress != address(0),"Community sale not active");

        (bool success, ) = _communityAddress.call{value: msg.value}(
            abi.encodeWithSignature(
                "communityPurchase(address,uint256,bytes,uint256)",
                msg.sender,
                tokenCount,
                signature,
                role)
        );
        if (success) return;
        
        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            revert(ptr, size)
        }
    
    }


    function setSaleStatus(bool active) external onlyOwner {
        _saleActive = active;
    }

    function setPresaleStatus(bool active) external onlyOwner {
        _presaleActive = active;
    }

    function setSaleDates(bool timedSale, uint256 start, uint256 end) external onlyOwner {
        _timedSale = timedSale;
        _saleStart = start;
        _saleEnd   = end;
    }
    function setPresaleDates(bool timedSale, uint256 start, uint256 end) external onlyOwner {
        _timedPresale = timedSale;
        _presaleStart = start;
        _presaleEnd   = end;
    }

    function checkSaleIsActive() public view returns (bool) {
        if (_saleActive) return true;
        if (_timedSale && (_saleStart <= block.timestamp) && (_saleEnd >= block.timestamp)) return true;
        return false;
    }

    function checkPresaleIsActive() public view returns (bool) {
        if (_presaleActive) return true;
        if (_timedPresale && (_presaleStart <= block.timestamp) && (_presaleEnd >= block.timestamp)) return true;
        return false;
    }

    function eligibleTokens(uint256[] memory tokenIds) internal returns (uint256) {
        uint256 count;
        for (uint j = 0; j < tokenIds.length; j++) {
            uint tokenId = tokenIds[j];
            require(_EC.ownerOf(tokenId)==msg.sender,"You do not own all tokens");
            if (!_claimed[tokenId]) {
                _claimed[tokenId] = true;
                count++;
            }
        }
        return count;
    }



    function tellEverything(address addr) external view returns (theKitchenSink memory) {
        // if community module active - get the community.taken[msg.sender]

        ec_token_interface.TKS memory tokenData = _token.tellEverything();

        uint256 community_claimed;
        if (_communityAddress != address(0)) {
            community_claimed = community_interface(_communityAddress).community_claimed(addr);
        }

        return theKitchenSink(
        _maxSupply,
        tokenData._mintPosition,
        _wallets,
        _shares,
        _fullPrice,
        _discountPrice,
        _communityPrice,
        _timedPresale,
        _presaleStart,
        _presaleEnd,
        _timedSale,
        _saleStart,
        _saleEnd, 
        _dustMintAvailable,
        _dustPrice,
        tokenData._lockTillSaleEnd,

        
        _maxFreeEC,
        _totalFreeEC,
        
        _maxDiscount,
        _totalDiscount,

        _freePerAddress,
        _discountedPerAddress,
        _tokenPreRevealURI,
        _signer,

        checkPresaleIsActive(),
        checkSaleIsActive(),
        checkSaleIsActive() && _dustMintAvailable,

        _freeClaimedPerWallet[addr],
        _discountedClaimedPerWallet[addr],

        address(_EC),
        _DUST,

        _maxPerSaleMint,
        _MaxUserMintable,
        _userMinted,

        community_claimed,

        tokenData._randomReceived,
        tokenData._secondReceived,
        tokenData._randomCL,
        tokenData._randomCL2,
        tokenData._ts1,
        tokenData._ts2

        );
    }

}
