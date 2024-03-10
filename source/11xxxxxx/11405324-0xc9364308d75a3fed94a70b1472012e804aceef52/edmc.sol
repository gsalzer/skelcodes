/**
 *Submitted for verification at Etherscan.io on 2020-11-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-13
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-30
*/

pragma solidity ^0.5.2;
import "./edm.sol";


/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}
/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);
    
    address ownerAddress;
    
    constructor () public{
        ownerAddress = msg.sender;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return ownerAddress;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        ownerAddress = newOwner;
    }
}


contract airdrop is Ownable,EDM{
      using SafeMath for uint256;
   address public erc20token;
   constructor() public{
   }
    event Multisended(uint256 total, address tokenAddress);
     struct User{
        uint256 amount;
        uint256 tokenAmount;
    }
    mapping(address=>User) public Users;
    //  function arrayLimit() public view returns(uint256) {
    //     return uintStorage[keccak256(abi.encodePacked("arrayLimit"))];
    // }
    function setTxCount(address customer, uint256 _txCount) private {
        uintStorage[keccak256(abi.encodePacked("txCount", customer))] = _txCount;
    }

    // function setArrayLimit(uint256 _newLimit) public onlyOwner {
    //     require(_newLimit != 0);
    //     uintStorage[keccak256("arrayLimit")] = _newLimit;
    // }
    
    function txCount(address customer) public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("txCount", customer))];
    }
    function register()public view returns(address){
        return msg.sender;
    }
    function multisendToken( address[] calldata _contributors, uint256[] calldata _balances) external onlyOwner  {
            // require(_contributors.length <= arrayLimit());
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
            transfer(_contributors[i], _balances[i]);
            Users[_contributors[i]].amount=0;
            }
            setTxCount(msg.sender, txCount(msg.sender).add(1));
        }
    function sendMultiEth(address payable [] calldata userAddress,uint256[] calldata _amount) external  onlyOwner {
     
     uint8 i = 0;
        for (i; i < userAddress.length; i++) {
            userAddress[i].transfer(_amount[i]);
            Users[userAddress[i]].tokenAmount=0;
        }
    }
    function buy()external payable{
        require(msg.value>0,"Select amount first");
        Users[msg.sender].amount=msg.value;
    }
    function sell(uint256 _token)external{
        require(_token>0,"Select amount first");
        transfer(address(this),_token);
        Users[msg.sender].tokenAmount=_token;
    }
    function withDraw(uint256 _amount)onlyOwner payable external{
        msg.sender.transfer(_amount);
    }
        
}
