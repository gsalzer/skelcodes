// File: openzeppelin-solidity/contracts/ownership/Secondary.sol

pragma solidity ^0.5.2;

/**
 * @title Secondary
 * @dev A Secondary contract can only be used by its primary account (the one that created it)
 */
contract Secondary {
    address private _primary;

    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(msg.sender == _primary);
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0));
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/CharityVault.sol

pragma solidity ^0.5.2;



/**
 * @title CharityVault
 * @dev Vault which holds the assets until the community leader(s) decide to transfer
 * them to the actual charity destination.
 * Deposit and withdrawal calls come only from the actual community contract
 */
contract CharityVault is Secondary {
    using SafeMath for uint256;

    mapping(address => uint256) private deposits;
    uint256 public sumStats;

    event LogEthReceived(
        uint256 amount,
        address indexed account
    );
    event LogEthSent(
        uint256 amount,
        address indexed account
    );

    /**
    * @dev fallback, 'anonymous' donation
    **/
    function() external payable {
        sumStats.add(msg.value);
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param _payee The destination address of the funds.
     */
    function deposit(address _payee) public onlyPrimary payable {
        uint256 _amount = msg.value;
        deposits[_payee] = deposits[_payee].add(_amount);
        sumStats = sumStats.add(_amount);
        emit LogEthReceived(_amount, _payee);
    }

    /**
     * @dev Withdraw some of accumulated balance for a _payee.
     */
    function withdraw(address payable _payee, uint256 _payment) public onlyPrimary {
        require(_payment > 0 && address(this).balance >= _payment, "Insufficient funds in the charity fund");
        _payee.transfer(_payment);
        emit LogEthSent(_payment, _payee);
    }

    function depositsOf(address payee) public view returns (uint256) {
        return deposits[payee];
    }
}
