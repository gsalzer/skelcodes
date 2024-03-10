/**
 *Submitted for verification at Polygonscan.com on 08-11-2021
*/
// SPDX-License-Identifier: MIT


//██╗░░░██╗███╗░░░███╗██████╗░░█████╗░  ██████╗░░█████╗░██╗███╗░░░███╗░█████╗░  ██╗░░██╗
//██║░░░██║████╗░████║██╔══██╗██╔══██╗  ██╔══██╗██╔══██╗██║████╗░████║██╔══██╗  ╚██╗██╔╝
//██║░░░██║██╔████╔██║██████╦╝███████║  ██║░░██║███████║██║██╔████╔██║███████║  ░╚███╔╝░
//██║░░░██║██║╚██╔╝██║██╔══██╗██╔══██║  ██║░░██║██╔══██║██║██║╚██╔╝██║██╔══██║  ░██╔██╗░
//╚██████╔╝██║░╚═╝░██║██████╦╝██║░░██║  ██████╔╝██║░░██║██║██║░╚═╝░██║██║░░██║  ██╔╝╚██╗
//░╚═════╝░╚═╝░░░░░╚═╝╚═════╝░╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝  ╚═╝░░╚═╝
//
//░█████╗░██████╗░██████╗░██████╗░███████╗░█████╗░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗
//██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
//███████║██████╔╝██████╔╝██████╔╝█████╗░░██║░░╚═╝██║███████║░░░██║░░░██║██║░░██║██╔██╗██║
//██╔══██║██╔═══╝░██╔═══╝░██╔══██╗██╔══╝░░██║░░██╗██║██╔══██║░░░██║░░░██║██║░░██║██║╚████║
//██║░░██║██║░░░░░██║░░░░░██║░░██║███████╗╚█████╔╝██║██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║
//╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚═╝░░╚═╝╚══════╝░╚════╝░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝
//
//████████╗░█████╗░██╗░░██╗███████╗███╗░░██╗
//╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝████╗░██║
//░░░██║░░░██║░░██║█████═╝░█████╗░░██╔██╗██║
//░░░██║░░░██║░░██║██╔═██╗░██╔══╝░░██║╚████║
//░░░██║░░░╚█████╔╝██║░╚██╗███████╗██║░╚███║
//░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝

pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() 
    {    require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract UmbaDaimaXApprTok is Ownable, ERC1155, ERC1155Burnable {
    
    mapping(uint => string) public locator;
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/") { }
    
    function uri(uint256 _id) public view override returns (string memory)
    {
        return string(abi.encodePacked('https://gateway.pinata.cloud/ipfs/', locator[_id]));
    }
    
    function mapIdToLocator(uint _tokenId, string memory locale) internal {
        locator[_tokenId] = locale;
    }
    //, bytes memory data
    function mintTocaller(address account, uint256 amount, string memory givenURL) 
        public onlyOwner returns (uint256)
    {
        _tokenIds.increment();
        
        uint256 id = _tokenIds.current();
        _mint(account, id, amount, "");
        mapIdToLocator(id, givenURL);
        
        return id;
    }
}
