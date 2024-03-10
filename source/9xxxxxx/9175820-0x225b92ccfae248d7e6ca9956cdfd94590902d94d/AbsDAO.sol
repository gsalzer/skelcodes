/*
❤ https://cryptohands.org - first open MLM smart-contract without comission
❤ https://doubleway.io - high-income binary matrix from the creators of CryptoHands
 

____0000000000______0000000000_____
__000________000__000________000___
_000___________0000___________000__
000_____________00_____________000_
000____________________________000_
000____________________________000_
_000________CRYPTOHANDS_______000__
__000________DOUBLEWAY_______000___
___000_____________________000____
_____000__________________000______
_______000______________000________
_________000__________000__________
____________000____000_____________
______________000000_______________
________________00_________________
*/
pragma solidity ^0.5.7;
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
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, 'Invalid values');
        return c;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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
        require(b <= a, 'Substraction result smaller than zero');
        return a - b;
    }

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
        require(c >= a, 'Invalid values');
        return c;
    }
}

contract Ownable {
    address public owner;
    address public manager;
    address public ownerWallet;
    address public adminWallet;
    uint adminPersent;

    constructor() public {
        owner = msg.sender;
        manager = msg.sender;
        adminWallet = 0xcFebf7C3Ec7B407DFf17aa20a2631c95c8ff508c;
        ownerWallet = 0xcFebf7C3Ec7B407DFf17aa20a2631c95c8ff508c;
        adminPersent = 10;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only for owner");
        _;
    }

    modifier onlyOwnerOrManager() {
        require((msg.sender == owner)||(msg.sender == manager), "only for owner or manager");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setManager(address _manager) public onlyOwnerOrManager {
        manager = _manager;
    }

    function setAdminWallet(address _admin) public onlyOwner {
        adminWallet = _admin;
    }
}


contract WalletOnly {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

contract AbsDAO is Ownable, WalletOnly {
    // events
    event TransferPie(address indexed _from, address indexed _to, uint _value);
    event NewHolder(address indexed _addr, uint _index);
    event HolderChanged(address indexed _from, address indexed _to, uint _index);
    event PaymentReceived(address indexed _from, uint _value);
    event PaymentForHolder(address indexed _addr, uint _index, uint _value);
    event PaymentForHolderLost(address indexed _addr, uint _index, uint _value);

    struct Holder {
        bool isExist;
        uint id;
        uint value;
        address payable addr;
    }

    mapping(address => Holder) public holders;
    mapping(uint=>address payable) holderAddrs;

    uint holderCount;
    uint _initialPie = 100;

    using SafeMath for uint;

    constructor() public {
        // creating root hoder
        holderCount = 1;
        holders[msg.sender] = Holder({
            isExist: true,
            id: 1,
            value: _initialPie,
            addr: msg.sender
        });

        holderAddrs[1] = msg.sender;
    }

    function () external payable {
        require(!isContract(msg.sender), 'This contract cannot support payments from other contracts');

        emit PaymentReceived(msg.sender, msg.value);

        for (uint i = 1; i <= holderCount; i++) {
            if (holders[holderAddrs[i]].value > 0) {
                uint payValue = msg.value.div(100).mul(holders[holderAddrs[i]].value);
                holderAddrs[i].transfer(payValue);
                emit PaymentForHolder(holderAddrs[i], i, payValue);
            } else {
                emit PaymentForHolderLost(holderAddrs[i], i, holders[holderAddrs[i]].value);
            }
        }
    }

    function getHolderPieAt(uint i) public view returns(uint) {
        return holders[holderAddrs[i]].value;
    }

    function getHolder(uint i) public view returns(address payable) {
        return holderAddrs[i];
    }

    function getHolderCount() public view returns(uint) {
        return holderCount;
    }

    function transferPie(uint _amount, address payable _to) public {
        require(holders[msg.sender].isExist, 'Holder not found');
        require(_amount > 0 && _amount <= holders[msg.sender].value, 'Invalid amount');

        if (_amount == holders[msg.sender].value) {
            uint id = holders[msg.sender].id;
            delete holders[msg.sender];

            holders[_to] = Holder({
                isExist: true,
                id: id,
                value: _amount,
                addr: _to
            });

            holderAddrs[id] = _to;

            emit HolderChanged(msg.sender, _to, id);
        } else {
            if (holders[_to].isExist) {
                holders[msg.sender].value -= _amount;
                holders[_to].value += _amount;
            } else if (holderCount < 20) {
                holderCount += 1;
                holders[msg.sender].value -= _amount;
                holders[_to] = Holder({
                    isExist: true,
                    id: holderCount,
                    value: _amount,
                    addr: _to
                });

                holderAddrs[holderCount] = _to;

                emit NewHolder(_to, holderCount);
            } else {
                revert('Holder limit excised');
            }
        }

        emit TransferPie(msg.sender, _to, _amount);
    }
}
