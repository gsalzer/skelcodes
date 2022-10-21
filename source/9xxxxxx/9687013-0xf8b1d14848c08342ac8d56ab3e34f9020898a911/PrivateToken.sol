pragma solidity ^0.4.24;
import "./StandardToken.sol";
import "./DepositFromPrivateToken.sol";

contract PrivateToken is StandardToken {
    using SafeMath for uint256;

    string public name; // Storage slot 3 // solium-disable-line uppercase
    string public symbol; // Storage slot 4 // solium-disable-line uppercase
    uint8 public decimals; // Storage slot 5 // solium-disable-line uppercase

    address public admin; // Storage slot 6
    bool public isPublic; // Storage slot 7
    uint256 public unLockTime; // Storage slot 8
    DepositFromPrivateToken originToken; // Storage slot 9

    event StartPublicSale(uint256 unlockTime);
    event Deposit(address indexed from, uint256 value);
    /**
    *  @dev check if msg.sender is allowed to deposit Origin token.
    */
    function isDepositAllowed() internal view{
      // If the tokens isn't public yet all transfering are limited to origin tokens
      require(isPublic);
      require(msg.sender == admin || block.timestamp > unLockTime);
    }

    /**
    * @dev Deposit msg.sender's origin token to real token
    */
    function deposit(address _depositor) public returns (bool){
      isDepositAllowed();
      uint256 _value;
      _value = balances[_depositor];
      require(_value > 0);
      balances[_depositor] = 0;
      require(originToken.deposit(_depositor, _value));
      emit Deposit(_depositor, _value);

      // This event is for those apps calculate balance from events rather than balanceOf
      emit Transfer(_depositor, address(0), _value);
    }

    /**
    *  @dev Start Public sale and allow admin to deposit the token.
    *  normal users could deposit their tokens after the tokens unlocked
    */
    function startPublicSale(uint256 _unLockTime) public onlyAdmin {
      require(!isPublic);
      isPublic = true;
      unLockTime = _unLockTime;
      emit StartPublicSale(_unLockTime);
    }

    /**
    *  @dev unLock the origin token and start the public sale.
    */
    function unLock() public onlyAdmin{
      require(isPublic);
      unLockTime = block.timestamp;
    }

    modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
    }

    constructor(address _admin, string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public{
      originToken = DepositFromPrivateToken(msg.sender);
      admin = _admin;
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      totalSupply_ = _totalSupply;
      balances[admin] = _totalSupply;
      emit Transfer(address(0), admin, _totalSupply);
    }
}

