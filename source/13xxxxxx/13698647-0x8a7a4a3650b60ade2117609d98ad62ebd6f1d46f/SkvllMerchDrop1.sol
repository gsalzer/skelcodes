// File: contracts/interface/ISkvllpvnkz.sol


pragma solidity ^0.8.0;

interface ISkvllpvnkz {
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: contracts/SkvllStore.sol


pragma solidity ^0.8.0;




struct Skvllpvnk{
    bool isUsed;
    address usedBy;
}

struct Order{
    bool isCancelled;
    uint256 skvllpvnkId;
}

contract SkvllMerchDrop1 is Ownable, ReentrancyGuard {
    
    event PublicSaleStarted();
    event PublicSalePaused();
    
    ISkvllpvnkz private SkvllpvnkzHideout;

    uint256 private _bundlePrice = 0.035 ether;
    
    bool public _publicSale = false;
    
    mapping(uint256 => Skvllpvnk) private usedSkvllpvnkz;
    mapping(address => Order[]) private orders;
    
    constructor(address skvllpvnkzAddress) { 
        SkvllpvnkzHideout = ISkvllpvnkz(skvllpvnkzAddress);
    }
    
    function purchaseBundle(uint256 skvllpvnkId) external payable nonReentrant {
        require( _publicSale, "Sale paused" );
        require( !usedSkvllpvnkz[skvllpvnkId].isUsed, "This Skvllpvnk has already been used");
        require( msg.sender == SkvllpvnkzHideout.ownerOf( skvllpvnkId ), "You do not own this Skvllpvnk");
        require( msg.value >= _bundlePrice, "Not enough ETH");
        usedSkvllpvnkz[skvllpvnkId] = Skvllpvnk(true, msg.sender);
        orders[msg.sender].push(Order(false, skvllpvnkId));
    }

    function publicSale(bool val) external onlyOwner {
        _publicSale = val;
        if (val) {
            emit PublicSaleStarted();
        } else {
            emit PublicSalePaused();
        }
    }
    
    function unclaimedSkvllpvnkzCountIDs(address _owner) external view returns (uint256[] memory){
        uint256[] memory tokenIds = SkvllpvnkzHideout.walletOfOwner( _owner );
        uint256[] memory unusedTokenIds = new uint256[](unclaimedSkvllpvnkzCount(_owner));
        uint256 j = 0;
        for (uint256 i=0; i < tokenIds.length; i++){
            if (!usedSkvllpvnkz[tokenIds[i]].isUsed) {
                unusedTokenIds[j] = tokenIds[i];
                j++;
            }
        }
        return unusedTokenIds;
    }
    
    function unclaimedSkvllpvnkzCount(address _owner) public view returns (uint256){
        uint256[] memory tokenIds = SkvllpvnkzHideout.walletOfOwner( _owner );
        uint256 count = 0;
        for (uint256 i=0; i < tokenIds.length; i++){
            if (!usedSkvllpvnkz[tokenIds[i]].isUsed) count++;
        }
        return count;
    }
    
    function setPrice(uint256 price) external onlyOwner{
        _bundlePrice = price;
    }
    
    function getPrice() external view returns (uint256){
        return _bundlePrice;
    }
    
    function isClaimed(uint256 skvllpvnkId) external view returns(bool){
        return usedSkvllpvnkz[skvllpvnkId].isUsed;
    }
    
    function getUsedSkvllpvnk(uint256 skvllpvnkId) external view returns(Skvllpvnk memory){
        return usedSkvllpvnkz[skvllpvnkId];
    }
    
    function getOrder(address owner) external view returns (Order[] memory){
        return orders[owner];
    }
    
    function cancelOrder(uint256 skvllpvnkId, address owner) external onlyOwner{
        for (uint256 i=0; i < orders[owner].length-1; i++){
            if (orders[owner][i].skvllpvnkId == skvllpvnkId){
                orders[owner][i].isCancelled = true;
            }
        }
        usedSkvllpvnkz[skvllpvnkId].isUsed = false;
    }
    
    function setSkvllpvnkzContractAddress(address _address) external onlyOwner {
        SkvllpvnkzHideout = ISkvllpvnkz(_address);
    }

    function withdraw(uint256 amount) external payable onlyOwner {
        require(payable(msg.sender).send(amount));
    }
    
}
