pragma solidity ^0.4.0;

import "./MathLibrary.sol";
import "./Erc20TokenInterface.sol";
contract Ownable {
    using MathLibrary for uint256;
    address public owner;
    address[] public BoDAddresses;
    
    address public mintAddress;
    
    address public mintDestChangerAddress;
    address public mintAccessorAddress;
    address public blackListAccessorAddress;
    address public blackFundDestroyerAccessorAddress;
    struct TransferObject {
        uint256 transferCounter;
        uint256 from;
        address to;
        mapping(address => bool) voted;
    }

    TransferObject transferObject;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AuthorityTransfer(address indexed from, address indexed to);

    constructor() public payable {
        owner = msg.sender;
        
    }

     /**
    * change owner of contract
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
     /**
    * change destination of mint address
    */
    function changeMintAddress(address addr) public{
        require(msg.sender == mintDestChangerAddress);
        mintAddress = addr;
    }
    
     /**
    * change accessor of mint destination changer
    */
    function changeMintDestChangerAddress(address addr) public{
        require(msg.sender == BoDAddresses[1]);
        mintDestChangerAddress = addr;
    }
    
     /**
    * change accessor of mint function
    */
    function changeMintAccessorAddress(address addr) public{
        require(msg.sender == BoDAddresses[0]);
        mintAccessorAddress = addr;
    }
    
     /**
    * change accessor of blackList
    */
    function changeBlackListAccessorAddress(address addr) public{
        require(msg.sender == BoDAddresses[2]);
        blackListAccessorAddress = addr;
    }
    
     /**
    * change accessor of blackList destroy fund
    */
    function changeBlackFundAccessorAddress(address addr) public{
        require(msg.sender == BoDAddresses[3]);
        blackFundDestroyerAccessorAddress = addr;
    }
    
     /**
    * sender(caller) vote for transfer `_from' address to '_to' address in board of directors
    *
    * Requirement:
    * - sender(Caller) and _from` should be in the board of directors.
    * - `_to` shouldn't be in the board of directors
    */
    function transferAuthority(uint256 from, address to) notInBoD(to, "_to address is already in board of directors") isAuthority(msg.sender, "you are not permitted to vote for transfer") public {
        require(from < BoDAddresses.length);
        if (BoDAddresses[from] == msg.sender) {
            transferAuth(from, to);
            return;
        }
        require(!transferObject.voted[msg.sender]);

        if (transferObject.from != from || transferObject.to != to) {
            transferObject.transferCounter = 0;
            for (uint j = 0; j < BoDAddresses.length; j++) {
                transferObject.voted[BoDAddresses[j]] = false;
            }
        }
        if (transferObject.transferCounter == 0) {
            transferObject.from = from;
            transferObject.to = to;
            
        }
        transferObject.transferCounter++;
        transferObject.voted[msg.sender] = true;
        if (transferObject.transferCounter == BoDAddresses.length - 1) {
            transferAuth(from, to);
        }
    }

     /**
    * this function is called if all of board of directors vote for the transfer `_from`->`_to'.
    */
    function transferAuth(uint256 from, address to) private {
        for (uint j = 0; j < BoDAddresses.length; j++) {
            transferObject.voted[BoDAddresses[j]] = false;
        }
        emit AuthorityTransfer(BoDAddresses[from], to);
        BoDAddresses[from] = to;
        transferObject.transferCounter = 0;
        
    }

     /**
    * This function is used by board of directors to remove other tokens in contract
    */
    function removeErc20TokensFromContract(address _token, address to) public isAuthority(msg.sender, "you are not permitted"){
        Erc20TokenInterface erc20Token = Erc20TokenInterface(_token);
        uint256 value = erc20Token.balanceOf(address(this));
        erc20Token.transfer(to,value);
    }
    
    
    modifier isAuthority(address authority, string errorMessage) {
        bool isBoD = false;
        for (uint i = 0; i < BoDAddresses.length; i++) {
            if (authority == BoDAddresses[i]) {
                isBoD = true;
                break;
            }
        }
        require(isBoD, errorMessage);
        _;
    }

    modifier notInBoD(address addr, string errorMessage){
        bool flag = true;
        for (uint i = 0; i < BoDAddresses.length; i++) {
            if (addr == BoDAddresses[i]) {
                flag = false;
                break;
            }
        }
        require(flag, errorMessage);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
}

