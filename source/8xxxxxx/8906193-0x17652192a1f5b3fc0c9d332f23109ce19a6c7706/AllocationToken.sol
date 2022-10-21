/**
 *Submitted for verification at Etherscan.io on 2019-07-19
*/

pragma solidity ^0.5.7;

// File: contracts/Math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/Ownable/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/AllocationToken/IAllocationToken.sol

/**
@title IAllocationToken
@notice This contract provides an interface for AllocationToken
 */
contract IAllocationToken {
    /**
    @dev fired on exchange contract's updation
    @param exchangeContract the address of exchange contract
     */
    event ExchangeContractUpdated(address exchangeContract);

    /**
    @dev fired on investment contract's updation
    @param investmentContract the address of investment contract
     */
    event InvestmentContractUpdated(address investmentContract);

    /**
    @dev updates exchange contract's address
    @param _exchangeContract the address of updated exchange contract
     */
    function updateExchangeContract(address _exchangeContract) external;

    /**
    @dev updates the investment contract's address
    @param _investmentContract the address of updated innvestment contract
     */
    function updateInvestmentContract(address _investmentContract) external;

    /**
    @notice Allows to mint new AT tokens
    @dev Only owner or exchange contract can call this function
    @param _holder The address to mint the tokens to
    @param _tokens The amount of tokens to mint
     */
    function mint(address _holder, uint256 _tokens) public;

    /**
    @notice Allows to burn AT tokens
    @dev Only Investment contract contract can call this function
    @param _address The address to burn the tokens from
    @param _value The amount of tokens to burn
    */
    function burn(address _address, uint256 _value) public;
}

// File: contracts/AllocationToken/AllocationToken.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value)
        internal
    {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
  * @dev total number of tokens in existence
  */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue)
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/// @title OpenZeppelinERC20
/// @author Applicature
/// @notice Open Zeppelin implementation of standart ERC20
/// @dev Base class
contract OpenZeppelinERC20 is StandardToken, Ownable {
    using SafeMath for uint256;

    uint8 public decimals;
    string public name;
    string public symbol;

    constructor(
        uint256 _totalSupply,
        string memory _tokenName,
        uint8 _decimals,
        string memory _tokenSymbol
    ) public {
        totalSupply_ = _totalSupply;
        balances[msg.sender] = _totalSupply;

        name = _tokenName;
        // Set the name for display purposes
        symbol = _tokenSymbol;
        // Set the symbol for display purposes
        decimals = _decimals;
    }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

    /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
    function burn(address _address, uint256 _value) public {
        _burn(_address, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(
            _value <= balances[_who],
            "Does not have enough balance to burn"
        );

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

/// @title MintableToken
/// @author Applicature
/// @notice allow to mint tokens
/// @dev Base class
contract MintableToken is BasicToken {
    using SafeMath for uint256;

    event Minted(address receiver, uint256 tokens);

    /// @notice allow to mint tokens
    function mint(address _holder, uint256 _tokens) public {
        totalSupply_ = totalSupply_.add(_tokens);

        balances[_holder] = balanceOf(_holder).add(_tokens);

        emit Transfer(address(0), _holder, _tokens);
        emit Minted(_holder, _tokens);
    }

}

/**
@title AllocationToken
@dev most derived class
 */
contract AllocationToken is
    IAllocationToken,
    OpenZeppelinERC20,
    MintableToken,
    BurnableToken
{
    address public exchangeContract; // address of exchange contract
    address public investmentContract; // address of investment contract

    /**
    @notice constructor of Allocation token contract
     */
    constructor() public OpenZeppelinERC20(0, "AllocationToken", 18, "ALT") {}

    /**
    @notice only addresses allowed to mint new tokens pass it
     */
    modifier allowedToMint() {
        require(
            msg.sender == owner() || msg.sender == exchangeContract,
            "Sender is not allowed to mint tokens."
        );
        _;
    }

    /**
    @notice only addresses allowed to burn tokens pass it
     */
    modifier allowedToBurn() {
        require(
            msg.sender == investmentContract,
            "Sender is not allowed to burn tokens."
        );
        _;
    }

    /**
    @dev updates exchange contract's address
    @param _exchangeContract the address of updated exchange contract
     */
    function updateExchangeContract(address _exchangeContract)
        external
        onlyOwner
    {
        require(
            _exchangeContract != address(0x0),
            "Exchange contract address is not valid."
        );
        exchangeContract = _exchangeContract;

        emit ExchangeContractUpdated(exchangeContract);
    }

    /**
    @dev updates the investment contract's address
    @param _investmentContract the address of updated innvestment contract
     */
    function updateInvestmentContract(address _investmentContract)
        external
        onlyOwner
    {
        require(
            _investmentContract != address(0x0),
            "Investment contract address is not valid."
        );
        investmentContract = _investmentContract;

        emit InvestmentContractUpdated(investmentContract);
    }

    function transfer(address _to, uint256 _tokens) public returns (bool) {
        revert("This operation is not allowed"); // transfer is not allowed
    }

    function transferFrom(address _holder, address _to, uint256 _tokens)
        public
        returns (bool)
    {
        revert("This operation is not allowed"); // transferFrom is not allowed
    }

    /**
    @notice Allows to mint new AT tokens
    @dev Only owner or exchange contract can call this function
    @param _holder The address to mint the tokens to
    @param _tokens The amount of tokens to mint
     */
    function mint(address _holder, uint256 _tokens) public allowedToMint {
        super.mint(_holder, _tokens); // call mint function on the base contract
    }

    /**
    @notice Allows to burn AT tokens
    @dev Only Investment contract contract can call this function
    @param _address The address to burn the tokens from
    @param _value The amount of tokens to burn
    */
    function burn(address _address, uint256 _value) public allowedToBurn {
        super.burn(_address, _value); // call burn function on the base contract
    }

}
