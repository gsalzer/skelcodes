// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



pragma solidity ^0.8.0;

contract EtheremuraMintForVT3 is Ownable{
	
	MAIN public constant MAIN_CONTRACT = MAIN(0x42074B47E57a0950F21443CCBab452Ab53890956);
	VT3 public constant VT3_CONTRACT = VT3(0xF17F7aE4100F2615722279520A91AeB6d76a3258);
	bool public paused = true;
	uint256 private _price;

    constructor(uint256 newprice){
        _price = newprice;
    }
    
    function mintForVT3(address _to, uint _count) public {
        
        require(!paused, "Contract in not active");
        require(VT3_CONTRACT.balanceOf(msg.sender) >= priceInVT3(_count), "Contract in not active");
        require(VT3_CONTRACT.allowance(msg.sender, address(this)) >= priceInVT3(_count), "No permission to use the required amount of VT3");
        require(address(this).balance >= MAIN_CONTRACT.price(_count), "There is no required amount of ether on the contract");
        require(VT3_CONTRACT.transferFrom(msg.sender, address(this), priceInVT3(_count)), "VT3 Transfer error");
        MAIN_CONTRACT.mintSamurai{value: MAIN_CONTRACT.price(_count)}(_to, _count);
        
    }
    
    function priceInVT3(uint _count) public view returns (uint256) {
        return _count * _price;
    }
    
    function pause(bool val) public onlyOwner {
        paused = val;
    }
    
    function setPrice(uint256 newprice) public onlyOwner{
        _price = newprice;
    }
    
    function withdrawAllETH() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
     
    function withdrawAllVT3() public onlyOwner {
        require(VT3_CONTRACT.transfer(msg.sender, VT3_CONTRACT.balanceOf(address(this))));
    }
    
    function sendEther() public payable {
        require(msg.value > 0);
    }
    
}

interface MAIN{
    function mintSamurai(address _to, uint _count) external payable;
    function price(uint _count) external view returns (uint256);
}

interface VT3{
    function balanceOf(address account) external view returns (uint256);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
