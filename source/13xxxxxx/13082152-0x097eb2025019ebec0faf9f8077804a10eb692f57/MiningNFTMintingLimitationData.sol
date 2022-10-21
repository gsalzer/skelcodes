pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/*
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

contract Poster is Ownable{
    address public poster;
    event PosterChanged(address originalPoster, address newPoster);

    modifier onlyPoster(){
        require(poster == _msgSender(), "not poster");
        _;
    }

    function setPoster(address _poster) public onlyOwner{
        require(_poster != address(0), "address should not be 0");
        emit PosterChanged(poster, _poster);
        poster = _poster;
    }
}

contract MiningNFTMintingLimitationData is Poster{
    using SafeMath for uint256;

    uint256 public totalMintLimitationInTiB;
    
    mapping(string=>uint) public minerMintAmountLimitation; // in TiB

    event TotalLimitationChanged(uint256 originalLimitation, uint256 newLimitation);
    event MinerMintAmountLimitationChanged(string minerId, uint256 originalLimitation, uint256 newLimitation);

    function setTotalMintLimitationInTiB(uint256 _totalMintLimitationInTiB) public onlyPoster{
        require(_totalMintLimitationInTiB > 0, "value should be >0");
        uint256 originalLimitation = totalMintLimitationInTiB;
        totalMintLimitationInTiB = _totalMintLimitationInTiB;
        emit TotalLimitationChanged(originalLimitation, totalMintLimitationInTiB);
    }

    /**
        increase overall limitation in TiB
     */
    function increaseTotalLimitation(uint256 _limitationDelta) public onlyPoster{
        uint256 originalLimitation = totalMintLimitationInTiB;
        totalMintLimitationInTiB = totalMintLimitationInTiB.add(_limitationDelta);
        emit TotalLimitationChanged(originalLimitation, totalMintLimitationInTiB);
    }

    function decreaseTotalLimitation(uint256 _limitationDelta) public onlyPoster{
        uint256 originalLimitation = totalMintLimitationInTiB;
        if(_limitationDelta <= totalMintLimitationInTiB){
            totalMintLimitationInTiB = totalMintLimitationInTiB.sub(_limitationDelta);
        }else{
            totalMintLimitationInTiB = 0;
        }
        
        emit TotalLimitationChanged(originalLimitation, totalMintLimitationInTiB);
    }

    function increaseMinerLimitation(string memory _minerId, uint256 _minerLimitationDelta) public onlyPoster{
        uint256 originalLimitation = minerMintAmountLimitation[_minerId];
        minerMintAmountLimitation[_minerId] = minerMintAmountLimitation[_minerId].add(_minerLimitationDelta);
        increaseTotalLimitation(_minerLimitationDelta);
        emit MinerMintAmountLimitationChanged(_minerId, originalLimitation, minerMintAmountLimitation[_minerId]);
    }

    function decreaseMinerLimitation(string memory _minerId, uint256 _minerLimitationDelta) public onlyPoster{
        uint originalLimitation = minerMintAmountLimitation[_minerId];
        if(_minerLimitationDelta <= originalLimitation ){
            minerMintAmountLimitation[_minerId] = originalLimitation.sub(_minerLimitationDelta);
        }else{
            minerMintAmountLimitation[_minerId] = 0;
            _minerLimitationDelta = originalLimitation;
        }
        
        emit MinerMintAmountLimitationChanged(_minerId, originalLimitation, minerMintAmountLimitation[_minerId]);
        decreaseTotalLimitation(_minerLimitationDelta);
    }

    function setMinerMintAmountLimitationBatch(string[] memory minerIds, uint256[] memory limitations) public onlyPoster{
        require(minerIds.length==limitations.length, "array length not equal");
        for(uint i=0; i<minerIds.length; i++){
            uint256 originalLimitation = minerMintAmountLimitation[minerIds[i]];
            totalMintLimitationInTiB = totalMintLimitationInTiB.sub(originalLimitation).add(limitations[i]);
            emit TotalLimitationChanged(originalLimitation, totalMintLimitationInTiB);

            minerMintAmountLimitation[minerIds[i]] = limitations[i];
            emit MinerMintAmountLimitationChanged(minerIds[i], originalLimitation, limitations[i]);
        }
    }

    function setMinerMintAmountLimitation(string memory _minerId, uint256 _limitation) public onlyPoster{
        uint256 originalLimitation = minerMintAmountLimitation[_minerId];
        totalMintLimitationInTiB = totalMintLimitationInTiB.sub(originalLimitation).add(_limitation);
        minerMintAmountLimitation[_minerId] = _limitation;
        emit MinerMintAmountLimitationChanged(_minerId, originalLimitation, _limitation);
        emit TotalLimitationChanged(originalLimitation, totalMintLimitationInTiB);
    }

}
