pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
    address public owner;
    address public secondOwner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == secondOwner);
        _;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract CryptoGodFather is ERC20Interface, Ownable {

    string public constant name = "CryptoGodFather";

    string public constant symbol = "CRYPTO";

    uint32 public constant decimals = 8;

    using SafeMath for uint256;

    address public exchangeContract;
    address public rewardSystemContract;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint)) allowed; 

    uint256 totalSupply_;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);

    constructor() public{
        totalSupply_ = 100000000 * (10 ** uint256(decimals));
        balances[this] = totalSupply_;
    }

    /**
    * @dev return all tokens supply
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }





    //!NEW! (05.07.18)
    //Функция позволяет переводить токены владельцу токенов
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    //!NEW! (05.07.18)
    //Функция разрешает стороннми контрактам переводить токены
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    //!NEW! (10.07.18)
    //Функция выполняет перевод токенов вызванный сторонним контрактом
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    //!NEW! (12.07.18)
    //Функция отвечает за перевод токенов клиента на контракт депозита
    function transferFromStockExchange(address from, uint tokens) external{
      //Смотрим, что обращается именно биржа
      require(msg.sender == exchangeContract);
      balances[from] = balances[from].sub(tokens);
      balances[msg.sender] = balances[msg.sender].add(tokens);
      emit Transfer(from, msg.sender, tokens);  
    }

    //Функция отвечает за перевод токенов клиента на контракт системы вознаграждений
    function transferFromRewardSystem(address from, uint tokens) external{
      require(msg.sender == rewardSystemContract);
      balances[from] = balances[from].sub(tokens);
      balances[msg.sender] = balances[msg.sender].add(tokens);
      emit Transfer(from, msg.sender, tokens);
    }



    //!NEW! (12.07.18)
    //Функция отвечает за управлением токенами владельцами контракта
    function transferToOwner(uint tokens) onlyOwner external{
      balances[this] = balances[this].sub(tokens);
      balances[msg.sender] = balances[msg.sender].add(tokens);
      emit Transfer(this, msg.sender, tokens);
    }


    //!NEW! (05.07.18)
    //Функция возвращает количество токенов, доступных для стороннего контракта
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     /**
     * @dev Gets the balance of the specified address.
     * @param _address The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
     function balanceOf(address _address) public view returns (uint256 balance) {
         return balances[_address];
     }

    function addOwner(address _addressowner) onlyOwner external {
        secondOwner = _addressowner;
    }
     

    //!NEW! (10.07.18)
    //Функция задает контракт депозита, который может распоряжаться токенами держателя токенов
    function setExchangeContract(address addressExchangeContract) onlyOwner external{
      exchangeContract = addressExchangeContract;
    }

    function setRewardSystemContract(address newRewardSystemContract) onlyOwner external{
      rewardSystemContract = newRewardSystemContract;
    }



    function mintTokens(uint _value) onlyOwner external {
        uint tokens = _value;
        _mint(tokens);
    }

    function burnTokens(uint _value) onlyOwner external {
        uint tokens = _value;
        _burn(tokens);
    }

    /**
     * @dev Internal function to mint tokens
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mint(uint256 _amount) onlyOwner internal returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[this] = balances[this].add(_amount);
        emit Mint(this, _amount);
        emit Transfer(msg.sender, this, _amount);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function _burn(uint256 _value) onlyOwner internal {
        require(_value <= balances[this]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = this;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(msg.sender, burner, _value);
     }


      //Функция возвращает количество decimals у токена
      function getDecimals() onlyOwner external view returns(uint){
        return decimals;
      }

}
