// EraswapToken is pasted below for Interface requirement from https://github.com/KMPARDS/EraSwapSmartContracts/blob/master/Eraswap/contracts/EraswapToken/EraswapToken.sol

pragma solidity ^0.5.9;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract EraswapERC20 is DetailedERC20, BurnableToken, CappedToken {
  string private name = "Eraswap";
  string private symbol = "EST";
  uint8 private decimals = 18;
  uint256 private cap = 9100000000000000000000000000;

  /**
  * @dev Constructor
  */

  constructor() internal DetailedERC20("Eraswap", "EST", 18) CappedToken(cap){
    mint(msg.sender, 910000000000000000000000000);
  }

}

contract NRTManager is Ownable, EraswapERC20{

  using SafeMath for uint256;

  uint256 public LastNRTRelease;              // variable to store last release date
  uint256 public MonthlyNRTAmount;            // variable to store Monthly NRT amount to be released
  uint256 public AnnualNRTAmount;             // variable to store Annual NRT amount to be released
  uint256 public MonthCount;                  // variable to store the count of months from the intial date
  uint256 public luckPoolBal;                 // Luckpool Balance
  uint256 public burnTokenBal;                // tokens to be burned

  // different pool address
  address public newTalentsAndPartnerships;
  address public platformMaintenance;
  address public marketingAndRNR;
  address public kmPards;
  address public contingencyFunds;
  address public researchAndDevelopment;
  address public buzzCafe;
  address public timeSwappers;                 // which include powerToken , curators ,timeTraders , daySwappers
  address public TimeAlly;                     //address of TimeAlly Contract

  uint256 public newTalentsAndPartnershipsBal; // variable to store last NRT released to the address;
  uint256 public platformMaintenanceBal;       // variable to store last NRT released to the address;
  uint256 public marketingAndRNRBal;           // variable to store last NRT released to the address;
  uint256 public kmPardsBal;                   // variable to store last NRT released to the address;
  uint256 public contingencyFundsBal;          // variable to store last NRT released to the address;
  uint256 public researchAndDevelopmentBal;    // variable to store last NRT released to the address;
  uint256 public buzzCafeNRT;                  // variable to store last NRT released to the address;
  uint256 public TimeAllyNRT;                   // variable to store last NRT released to the address;
  uint256 public timeSwappersNRT;              // variable to store last NRT released to the address;


    // Event to watch NRT distribution
    // @param NRTReleased The amount of NRT released in the month
    event NRTDistributed(uint256 NRTReleased);

    /**
    * Event to watch Transfer of NRT to different Pool
    * @param pool - The pool name
    * @param sendAddress - The address of pool
    * @param value - The value of NRT released
    **/
    event NRTTransfer(string pool, address sendAddress, uint256 value);


    // Event to watch Tokens Burned
    // @param amount The amount burned
    event TokensBurned(uint256 amount);



    /**
    * @dev Should burn tokens according to the total circulation
    * @return true if success
    */

    function burnTokens() internal returns (bool){
      if(burnTokenBal == 0){
        return true;
      }
      else{
        uint MaxAmount = ((totalSupply()).mul(2)).div(100);   // max amount permitted to burn in a month
        if(MaxAmount >= burnTokenBal ){
          burn(burnTokenBal);
          burnTokenBal = 0;
        }
        else{
          burnTokenBal = burnTokenBal.sub(MaxAmount);
          burn(MaxAmount);
        }
        return true;
      }
    }

    /**
    * @dev To invoke monthly release
    * @return true if success
    */

    function MonthlyNRTRelease() external returns (bool) {
      require(now.sub(LastNRTRelease)> 2592000);
      uint256 NRTBal = MonthlyNRTAmount.add(luckPoolBal);        // Total NRT available.

      // Calculating NRT to be released to each of the pools
      newTalentsAndPartnershipsBal = (NRTBal.mul(5)).div(100);
      platformMaintenanceBal = (NRTBal.mul(10)).div(100);
      marketingAndRNRBal = (NRTBal.mul(10)).div(100);
      kmPardsBal = (NRTBal.mul(10)).div(100);
      contingencyFundsBal = (NRTBal.mul(10)).div(100);
      researchAndDevelopmentBal = (NRTBal.mul(5)).div(100);
      buzzCafeNRT = (NRTBal.mul(25)).div(1000);
      TimeAllyNRT = (NRTBal.mul(15)).div(100);
      timeSwappersNRT = (NRTBal.mul(325)).div(1000);

      // sending tokens to respective wallets and emitting events
      mint(newTalentsAndPartnerships,newTalentsAndPartnershipsBal);
      emit NRTTransfer("newTalentsAndPartnerships", newTalentsAndPartnerships, newTalentsAndPartnershipsBal);
      mint(platformMaintenance,platformMaintenanceBal);
      emit NRTTransfer("platformMaintenance", platformMaintenance, platformMaintenanceBal);
      mint(marketingAndRNR,marketingAndRNRBal);
      emit NRTTransfer("marketingAndRNR", marketingAndRNR, marketingAndRNRBal);
      mint(kmPards,kmPardsBal);
      emit NRTTransfer("kmPards", kmPards, kmPardsBal);
      mint(contingencyFunds,contingencyFundsBal);
      emit NRTTransfer("contingencyFunds", contingencyFunds, contingencyFundsBal);
      mint(researchAndDevelopment,researchAndDevelopmentBal);
      emit NRTTransfer("researchAndDevelopment", researchAndDevelopment, researchAndDevelopmentBal);
      mint(buzzCafe,buzzCafeNRT);
      emit NRTTransfer("buzzCafe", buzzCafe, buzzCafeNRT);
      mint(TimeAlly,TimeAllyNRT);
      emit NRTTransfer("stakingContract", TimeAlly, TimeAllyNRT);
      mint(timeSwappers,timeSwappersNRT);
      emit NRTTransfer("timeSwappers", timeSwappers, timeSwappersNRT);

      // Reseting NRT
      emit NRTDistributed(NRTBal);
      luckPoolBal = 0;
      LastNRTRelease = LastNRTRelease.add(30 days); // resetting release date again
      burnTokens();                                 // burning burnTokenBal
      emit TokensBurned(burnTokenBal);


      if(MonthCount == 11){
        MonthCount = 0;
        AnnualNRTAmount = (AnnualNRTAmount.mul(9)).div(10);
        MonthlyNRTAmount = MonthlyNRTAmount.div(12);
      }
      else{
        MonthCount = MonthCount.add(1);
      }
      return true;
    }


  /**
  * @dev Constructor
  */

  constructor() public{
    LastNRTRelease = now;
    AnnualNRTAmount = 819000000000000000000000000;
    MonthlyNRTAmount = AnnualNRTAmount.div(uint256(12));
    MonthCount = 0;
  }

}

contract PausableEraswap is NRTManager {

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require((now.sub(LastNRTRelease))< 2592000);
    _;
  }


  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract EraswapToken is PausableEraswap {


    /**
    * Event to watch the addition of pool address
    * @param pool - The pool name
    * @param sendAddress - The address of pool
    **/
    event PoolAddressAdded(string pool, address sendAddress);

    // Event to watch LuckPool Updation
    // @param luckPoolBal The current luckPoolBal
    event LuckPoolUpdated(uint256 luckPoolBal);

    // Event to watch BurnTokenBal Updation
    // @param burnTokenBal The current burnTokenBal
    event BurnTokenBalUpdated(uint256 burnTokenBal);

    /**
    * @dev Throws if caller is not TimeAlly
    */
    modifier OnlyTimeAlly() {
      require(msg.sender == TimeAlly);
      _;
    }


    /**
    * @dev To update pool addresses
    * @param  pool - A List of pool addresses
    * Updates if pool address is not already set and if given address is not zero
    * @return true if success
    */

    function UpdateAddresses (address[] memory pool) onlyOwner public returns(bool){

      if((pool[0] != address(0)) && (newTalentsAndPartnerships == address(0))){
        newTalentsAndPartnerships = pool[0];
        emit PoolAddressAdded( "NewTalentsAndPartnerships", newTalentsAndPartnerships);
      }
      if((pool[1] != address(0)) && (platformMaintenance == address(0))){
        platformMaintenance = pool[1];
        emit PoolAddressAdded( "PlatformMaintenance", platformMaintenance);
      }
      if((pool[2] != address(0)) && (marketingAndRNR == address(0))){
        marketingAndRNR = pool[2];
        emit PoolAddressAdded( "MarketingAndRNR", marketingAndRNR);
      }
      if((pool[3] != address(0)) && (kmPards == address(0))){
        kmPards = pool[3];
        emit PoolAddressAdded( "KmPards", kmPards);
      }
      if((pool[4] != address(0)) && (contingencyFunds == address(0))){
        contingencyFunds = pool[4];
        emit PoolAddressAdded( "ContingencyFunds", contingencyFunds);
      }
      if((pool[5] != address(0)) && (researchAndDevelopment == address(0))){
        researchAndDevelopment = pool[5];
        emit PoolAddressAdded( "ResearchAndDevelopment", researchAndDevelopment);
      }
      if((pool[6] != address(0)) && (buzzCafe == address(0))){
        buzzCafe = pool[6];
        emit PoolAddressAdded( "BuzzCafe", buzzCafe);
      }
      if((pool[7] != address(0)) && (timeSwappers == address(0))){
        timeSwappers = pool[7];
        emit PoolAddressAdded( "TimeSwapper", timeSwappers);
      }
      if((pool[8] != address(0)) && (TimeAlly == address(0))){
        TimeAlly = pool[8];
        emit PoolAddressAdded( "TimeAlly", TimeAlly);
      }

      return true;
    }


    /**
    * @dev Function to update luckpool balance
    * @param amount Amount to be updated
    */
    function UpdateLuckpool(uint256 amount) OnlyTimeAlly external returns(bool){
      require(allowance(msg.sender, address(this)) >= amount);
      require(transferFrom(msg.sender,address(this), amount));
      luckPoolBal = luckPoolBal.add(amount);
      emit LuckPoolUpdated(luckPoolBal);
      return true;
    }

    /**
    * @dev Function to trigger to update  for burning of tokens
    * @param amount Amount to be updated
    */
    function UpdateBurnBal(uint256 amount) OnlyTimeAlly external returns(bool){
      require(allowance(msg.sender, address(this)) >= amount);
      require(transferFrom(msg.sender,address(this), amount));
      burnTokenBal = burnTokenBal.add(amount);
      emit BurnTokenBalUpdated(burnTokenBal);
      return true;
    }

    /**
    * @dev Function to trigger balance update of a list of users
    * @param TokenTransferList - List of user addresses
    * @param TokenTransferBalance - Amount of token to be sent
    */
    function UpdateBalance(address[100] calldata TokenTransferList, uint256[100] calldata TokenTransferBalance) OnlyTimeAlly external returns(bool){
        for (uint256 i = 0; i < TokenTransferList.length; i++) {
      require(allowance(msg.sender, address(this)) >= TokenTransferBalance[i]);
      require(transferFrom(msg.sender, TokenTransferList[i], TokenTransferBalance[i]));
      }
      return true;
    }




}

