// File: localhost/interfaces/IToken.sol

pragma solidity ^0.5.16;

interface IToken {
    function decimals() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function deposit() external payable;
    function withdraw(uint amount) external;
}
// File: localhost/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: localhost/utils/SafeERC20.sol

pragma solidity ^0.5.16;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

// import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IToken token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IToken token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IToken token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IToken token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: localhost/utils/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: localhost/utils/UniversalERC20.sol

pragma solidity ^0.5.16;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";




library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IToken;

    IToken private constant ZERO_ADDRESS = IToken(0x0000000000000000000000000000000000000000);
    IToken private constant ETH_ADDRESS = IToken(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IToken token, address to, uint256 amount) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(IToken token, address to, uint256 amount, bool mayFail) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            if (mayFail) {
                return address(uint160(to)).send(amount);
            } else {
                address(uint160(to)).transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalApprove(IToken token, address to, uint256 amount) internal {
        if (token != ZERO_ADDRESS && token != ETH_ADDRESS) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(IToken token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(uint256(msg.value).sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IToken token, address who) internal view returns (uint256) {
        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}
// File: localhost/nonupgradable/Ownable.sol

pragma solidity ^0.5.16;

contract Ownable {
    address payable public owner;
    address payable internal newOwnerCandidate;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }
}
// File: localhost/nonupgradable/FundsMgr.sol

pragma solidity ^0.5.16;



contract FundsMgr is Ownable {
    using UniversalERC20 for IToken;

    function withdraw(address token, uint256 amount) onlyOwner public  {
        require(msg.sender == owner);

        if (token == address(0x0)) {
            owner.transfer(amount);
        } else {
            IToken(token).universalTransfer(owner, amount);
        }
    }
    function withdrawAll(address[] memory tokens) onlyOwner public  {
        for(uint256 i = 0; i < tokens.length;i++) {
            withdraw(tokens[i], IToken(tokens[i]).universalBalanceOf(address(this)));
        }
    }
}
// File: localhost/DfAirdrop.sol

pragma solidity ^0.5.16;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
// import "./utils/SafeMath.sol";



// INTERFACES

interface IFinanceMgr {
    function userWipeAndClose(bytes32 cup,uint256 etherNeeded, bytes calldata _saiData, bytes calldata _usdData, uint256 minAmountAllowed) external payable;
    function usdToken() external returns(IToken);
}

interface IFinanceMgrOpenCdp  {
    function deal(address newOwner, uint256 coef, uint8 profitPercent, bytes calldata data, uint256 saiToBuyEther, uint8 ethType) external payable returns(bytes32);
    function dfManagerAddress() external returns(IFinanceMgr);
}


contract DfAirdrop is FundsMgr {
    using SafeMath for uint256;

    struct User {
        bool isReg;
        bool isWithdrawn;
    }

    uint256 public maxCountUsers;

    mapping (address => bool) admins;
    bool public isDealOpen;
    bool public isFinalized;

    IFinanceMgrOpenCdp public dfFinance;

    uint256 public depositedEth;
    uint256 public profitUsdPerUser;

    mapping (address => User) public users;
    uint256 public countRegUsers;
    uint256 public countWithdrawUsers;

    event RegNewUser (address indexed user);


    constructor() public {
        dfFinance = IFinanceMgrOpenCdp(0xD757EBb746167495716Ef3f11942c429203DBB75); //set dfFinance contract address
    }

    // USER FUNCTIONS

    function regUser(uint256 maxAllowedDatetime, uint8 v, bytes32 r, bytes32 s) public {
        require(countRegUsers < maxCountUsers);
        require(msg.sender == tx.origin);
        require(!users[msg.sender].isReg);
        require(now < maxAllowedDatetime);

        bytes32 hash = sha256(abi.encodePacked(this, msg.sender, maxAllowedDatetime));
        address src = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);
        require(admins[src] == true);

        users[msg.sender].isReg = true;
        countRegUsers = countRegUsers.add(1);

        emit RegNewUser(msg.sender);
    }

    function withdrawUserProfit() public {
        require(isFinalized);
        require(users[msg.sender].isReg && !users[msg.sender].isWithdrawn);

        // Set states
        countWithdrawUsers = countWithdrawUsers.add(1);
        users[msg.sender].isWithdrawn = true;

        // Transfer USDT
        dfFinance.dfManagerAddress().usdToken().universalTransfer(msg.sender, profitUsdPerUser);
    }


    // ONLY_OWNER FUNCTIONS
    function setAdmin(address newAdmin, bool active) onlyOwner public {
        admins[newAdmin] = active;
    }

    function financeMgrCall(address to, bytes memory _data, uint256 amountEther) onlyOwner public {
        bytes32 response;
        assembly {
            let succeeded := call(sub(gas, 5000), to, amountEther, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)
            switch iszero(succeeded)
            case 1 {
                revert(0, 0)
            }
        }
    }

    function run(uint256 coef, uint8 profitPercent, bytes memory data, uint256 saiToBuyEther, uint8 ethType, uint256 maxUsers) onlyOwner public payable {
        require(!isDealOpen && !isFinalized);
        require(maxUsers > 0);

        // Set states
        depositedEth = msg.value;
        isDealOpen = true;
        maxCountUsers = maxUsers;

        dfFinance.deal.value(msg.value)(address(this), coef, profitPercent, data, saiToBuyEther, ethType);
    }

    function stop(bytes32 cup, uint256 etherNeeded, bytes memory _saiData, bytes memory _usdData, uint256 minAmountAllowed) onlyOwner public payable {
        require(isDealOpen);

        dfFinance.dfManagerAddress().userWipeAndClose(cup, etherNeeded, _saiData, _usdData, minAmountAllowed);
    }

    // depositedUSD == our USDT for withdrawal (our deposit in ETH)
    function finalize(uint256 depositedUSD) onlyOwner public {
        require(isDealOpen);

        // check profit
        uint256 profitPerUser = dfFinance.dfManagerAddress().usdToken().balanceOf(address(this)).sub(depositedUSD).div(maxCountUsers);
        require(profitPerUser > 0);

        // Set states
        profitUsdPerUser = profitPerUser;
        isDealOpen = false;
        isFinalized = true;
    }

    function() external payable {}
}
