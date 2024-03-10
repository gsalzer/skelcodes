/**
 * MKDS Token Smart Contract.
 * Copyright (c) 2020 by owner.
 */
pragma solidity ^0.4.20;

import "SafeMath.sol";
import "Token.sol";

/**
 * MKDS Token Smart Contract: EIP-20 compatible token smart contract that
 * manages MKDS tokens.
 */
contract MKDSToken is SafeMath {
  string constant public contact = "cryp10grapher@protonmail.com";
  string constant public name = "MKDS Token - Стабилизиран со Македонски Денар";
  string constant public symbol = "MKDS";
  uint8 constant public decimals = 3;
  Token constant targetToken = Token(address(0xdB25f211AB05b1c97D595516F45794528a807ad8));
  address public owner;
  address public beneficiary;
  uint256 constant conversionRateNumerator = 6160000 * 10; // MKDS/EURS; * 10 because MKDS is 3 decimals and EURS is 2
  uint256 constant denominator = 100000;
  uint256 transferFeeMin = 1000; // transfer fee minimum in 1/100's of a MKDS, since MKDS token has 3 decimals
  uint256 transferFeeMax = 1000; // transfer fee maximum in 1/100's of a MKDS, since MKDS token has 3 decimals
  uint256 transferFeeFactorNumerator = 100; // transfer fee factor; (initialized for 0.1%); actual factor is obtained by dividing this by denominator

  mapping(address => uint256) private balances;
  mapping(address => mapping (address => uint256)) private allowances;

  /**
   * Create MKDS Token smart contract with message sender as an owner.
   */
  function MKDSToken() public {
    owner = msg.sender;
    beneficiary = owner;
  }

  /**
   * Make sure the modified function can be executed only by the owner.
   */
   modifier onlyOwner() {
    require(0 != owner);
    require(msg.sender == owner);
    _;
  }

  /**
   * Transfer ownership of this smart contract to a new address.
   *
   * @param _owner address of the new owner. If set to 0, the owner loses control of the contract.
   */
  function setOwner(address _owner) external onlyOwner() {
    owner = _owner; // If set to 0, owner loses control of the contract
  }

  /**
   * Set new beneficiary.
   *
   * @param _beneficiary address of the new beneficiary.
   */
  function setBeneficiary(address _beneficiary) external onlyOwner() {
    beneficiary = _beneficiary; // If set to 0, there is no oracle
  }

  /**
   * Destroy the smart contract and return all EURS and ETH to the owner.
   */
  function destroy() external onlyOwner() { // Only for alpha version - refund of holders would have to be done manually
    // if (!targetToken.transfer.value(0)(msg.sender, targetToken.balanceOf(this))) return; // does not work due to Solidity issue thus the next line
    if (!address(targetToken).call.value(0)(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, targetToken.balanceOf(this)))) return;
    else selfdestruct(msg.sender);
  }

  /**
   * Convert from EURS to MKDS.
   *
   * @param value amount of EURS
   * @return countervalue in MKDS
   */
  function toMKDS(uint256 value) public pure returns(uint256) {
    return safeMul(value, conversionRateNumerator) / denominator; // there should be no rounding as 0.01 EURS = 0.616 MKDS or internally 1 EURS would be 616 MKDS
  }

  /**
   * Convert from MKDS to EURS.
   *
   * @param value amount of MKDS
   * @return countervalue in EURS
   */
  function toEURS(uint256 value) public pure returns(uint256) {
    return safeMul(value, denominator) / conversionRateNumerator;
    // uint256 v = safeMul(value, denominator);
    // uint256 r = v/conversionRateNumerator; // round down
    // if (v%conversionRateNumerator > uint256(0)) return safeAdd(r, uint256(1)); else return r; // round up to cover the value in EURS
  }

  /**
   * Set new transfer fee parameters.
   *
   * @param _transferFeeMin // new transfer fee minimum in 1/100's of a MKDS, since MKDS token has 2 decimals
   * @param _transferFeeMax // new transfer fee maximum in 1/100's of a MKDS, since MKDS token has 2 decimals
   * @param _transferFeeFactorNumerator // new transfer fee factor numerator - actual factor is derived by dividing this by denominator
   */
  function setTranactionFeeParameters(
    uint256 _transferFeeMin,
    uint256 _transferFeeMax,
    uint256 _transferFeeFactorNumerator) external onlyOwner() { // In this version onlyOwner() but in the future set governance by voting
    transferFeeMin = _transferFeeMin;
    transferFeeMax = _transferFeeMax;
    transferFeeFactorNumerator = _transferFeeFactorNumerator;
  }

  /** Calculates the transaction fee for transfers.
   *
   * @param value the transfer amount
   * @return fee in MKDS
   */
  function transferFee(uint256 value) public view returns(uint256) {
    uint256 fee = safeMul(value, transferFeeFactorNumerator) / denominator; // round down
    if (fee < transferFeeMin) return transferFeeMin;
    else if (fee > transferFeeMax) return transferFeeMax;
    else return fee;
  }

  /**
   * Make deposit.
   * Depositor must first call approve(<address ofMKDSToken>,<amount in EURS>),
   * and then call this function to complete the deposit.
   */
  function deposit() public payable {
    // depositor sets allowance by calling EURS.approve(MKDS, value)
    uint256 _value = targetToken.allowance(msg.sender, address(this));
    if (targetToken.transferFrom.value(0)(msg.sender, address(this), _value)) {
      balances[msg.sender] += toMKDS(_value);
    }
  }

  /**
   * Make sure cannot receive ETH.
   */
  function () public {
    revert();
  }

  /**
   * Withdraw.
   */
  function withdraw() public {
    uint256 amount = toEURS(balances[msg.sender]);
    balances[msg.sender] = safeSub(balances[msg.sender], toMKDS(amount)); // May leave small reminder
    // require(targetToken.transfer.value()(msg.sender, amount)); does not work because of Solidity issue, thus next line
    require(address(targetToken).call.value(0)(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount)));
  }

  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply() public view returns (uint256) {
    return toMKDS(address(this).balance);
  }

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
   function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address excluding fees
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer(address _to, uint256 _value)
  public returns (bool) {
    uint256 fee = transferFee(_value);
    uint256 out = safeAdd(_value, fee);
    if (balances[msg.sender] < out) return false;
    balances[msg.sender] -= out;
    balances[_to] += _value;
    balances[beneficiary] += fee;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * Transfer given number of tokens from given owner to given recipient.
   * @dev Permissioning is delegated to the targetToken.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom(address _from, address _to, uint256 _value)
  public returns (bool) {
    if (0 == _value) return false; // To avoid draining through fees
    if (allowances[_from][msg.sender] < _value) return false;
    allowances[_from][msg.sender] -= _value;

    uint256 fee = transferFee(_value);
    uint256 out = safeAdd(_value, fee);
    if (balances[_from] < safeAdd(_value, fee)) return false;
    balances[_from] -= out;
    balances[_to] += _value;
    balances[beneficiary] += fee;
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   * @dev Permissioning is delegated to the targetToken.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value)
  public returns (bool success) {
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining) {
      return allowances[_owner][_spender];
  }

  /**
   * Logged when tokens were transferred from one owner to another.
   *
   * @param _from address of the owner, tokens were transferred from
   * @param _to address of the owner, tokens were transferred to
   * @param _value number of tokens transferred
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * Logged when owner approved his tokens to be transferred by some spender.
   *
   * @param _owner owner who approved his tokens to be transferred
   * @param _spender spender who were allowed to transfer the tokens belonging
   *        to the owner
   * @param _value number of tokens belonging to the owner, approved to be
   *        transferred by the spender
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

