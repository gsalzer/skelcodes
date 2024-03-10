pragma solidity ^0.6.11;
import "./SafeMath.sol";
import "./IERC20Token.sol";
import "./ReentrancyGuard.sol";

interface IERC721 {
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external;
    function changeName(string calldata name, string calldata symbol) external;
    function updateTokenUri(uint256 _tokenId,string memory _uri) external;
}

interface Ownable {
    function transferOwnership(address newOwner) external;
}

interface BasicERC20 {
    function decimals() external view returns (uint8);
}

contract VaultHandler is ReentrancyGuard {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    address private owner;
    bool public initialized;
    address private nftAddress;
    address private paymentAddress;
    address private recipientAddress;
    uint256 public price;
    
    mapping(address => uint256[]) public balances;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function transferOwnership(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    
    constructor(address _nftAddress, address _paymentAddress, address _recipientAddress, uint256 _price) public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        
        nftAddress = _nftAddress;
        paymentAddress = _paymentAddress;
        recipientAddress = _recipientAddress;
        initialized = true;
        uint decimals = BasicERC20(paymentAddress).decimals();
        price = _price * 10 ** decimals;
    }
    
    function claim(uint256 tokenId) public isOwner {
        IERC721 token = IERC721(nftAddress);
        token.burn(tokenId);
    }
    
    function buyWithPaymentOnly(address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) public payable {
        IERC20Token paymentToken = IERC20Token(paymentAddress);
        IERC721 nftToken = IERC721(nftAddress);
        require(paymentToken.transferFrom(msg.sender, address(recipientAddress), price), 'Transfer ERROR');
        nftToken.mint(_to, _tokenId, _uri, _payload);
    }
    
    function transferNftOwnership(address newOwner) external isOwner {
        Ownable nftToken = Ownable(nftAddress);
        nftToken.transferOwnership(newOwner);
    }
    
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external isOwner {
        IERC721 nftToken = IERC721(nftAddress);
        nftToken.mint(_to, _tokenId, _uri, _payload);
    }
    
    function changeName(string calldata name, string calldata symbol) external isOwner {
        IERC721 nftToken = IERC721(nftAddress);
        nftToken.changeName(name, symbol);
    }
    
    function updateTokenUri(uint256 _tokenId,string memory _uri) external isOwner {
        IERC721 nftToken = IERC721(nftAddress);
        nftToken.updateTokenUri(_tokenId, _uri);
    }
    
    function getPaymentDecimals() public view returns (uint8){
        BasicERC20 token = BasicERC20(paymentAddress);
        return token.decimals();
    }
    
    function changePayment(address payment) public isOwner {
       paymentAddress = payment;
    }
    
    function changeRecipient(address _recipient) public isOwner {
       recipientAddress = _recipient;
    }
    
    function changeNft(address token) public isOwner {
        nftAddress = token;
    }
    
    function changePrice(uint256 _price) public isOwner {
        uint decimals = BasicERC20(paymentAddress).decimals();
        price = _price * 10 ** decimals;
    }
}
