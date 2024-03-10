pragma solidity ^0.5.11;

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		require(c >= a);
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b <= a);
		c = a - b;
	}
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b > 0);
		c = a / b;
	}
}

contract Ownable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () internal {
		_owner = msg.sender;
		emit OwnershipTransferred(address(0), _owner);
	}

	modifier onlyOwner() {
		require(msg.sender == _owner, "Ownable: caller is not the owner");
		_;
	}

	function owner() public view returns (address) {
		return _owner;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0), "Ownable: owner cannot be the zero address");
		require(newOwner != address(this), "Ownable: owner cannot be the contract address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract Bitburn is Ownable {
	using SafeMath for uint256;

	string constant public name = "Bitburn";
	string constant public symbol = "BTU";
	uint8 constant public decimals = 0;
	uint256 private _totalSupply;
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 private burnRate;

	event Approval(address indexed owner, address indexed spender, uint256 amount);
	event Transfer(address indexed sender, address indexed recipient, uint256 amount);
	event Burn(uint256 amount);
	event BurnRateChanged(uint256 previousBurnRate, uint256 newBurnRate);
	event BurnOwnerTokens(uint256 amount);

	constructor (address _distrib, address _owner) public {
		require(_distrib != address(0) && _owner != address(0));

		transferOwnership(_owner);

		_totalSupply = 2000000;
		_balances[_owner] = _totalSupply*3/10;
		_balances[_distrib] = _totalSupply-_balances[_owner];
		emit Transfer(address(0), _distrib, _balances[_distrib]);
		emit Transfer(address(0), _owner, _balances[_owner]);

		burnRate = 20;
		emit BurnRateChanged(0, burnRate);
	}

	/**
	 * @dev returns the burn percentage of transfer amount.
	 *
	 * Note: see also {setBurnRate}.
	 */
	function getBurnRate() public view returns (uint256) {
		return burnRate;
	}

	/**
	 * @dev sets the burn percentage of transfer amount from 0.5% to 5% inclusive.
	 *
	 * Emits a {BurnRateChanged} event.
	 *
	 * Requirement: `_burnRate` must be within [5; 50] (to programmatically escape using fractional numbers).
	 */
	function setBurnRate(uint256 _burnRate) public onlyOwner {
		//Amount multiplier: [0.005; 0.05]
		require(_burnRate >= 5 && _burnRate <= 50, "Burn rate out of bounds");

		emit BurnRateChanged(burnRate, _burnRate);
		burnRate = _burnRate;
	}

	/**
	 * @dev totally burns the whole `_amount` of the contract's owner.
	 *
	 * Emits a {BurnOwnerTokens} event.
	 *
	 * Requirement: the contract's owner must have a balance of at least `_amount`.
	 */
	function burnOwnerTokens(uint256 _amount) public onlyOwner {
		require(_balances[msg.sender] >= _amount, "Burn amount exceeds balance");

		_balances[msg.sender] = _balances[msg.sender].sub(_amount);
		_totalSupply = _totalSupply.sub(_amount);
		emit BurnOwnerTokens(_amount);
	}

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256) {
		return _balances[_owner];
	}

	function transfer(address _recipient, uint256 _amount) public returns (bool) {
		_transfer(msg.sender, _recipient, _amount);
		return true;
	}

	function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
		require(_allowances[_sender][_recipient] >= _amount, "Transfer amount exceeds allowance");

		_transfer(_sender, _recipient, _amount);
		_allowances[_sender][_recipient] = _allowances[_sender][_recipient].sub(_amount);
		return true;
	}

	function _transfer(address _sender, address _recipient, uint256 _amount) internal {
		require(_balances[_sender] >= _amount, "Transfer amount exceeds balance");
		require(_recipient != address(0), "Cannot transfer to the zero address");
		require(_recipient != address(this), "Cannot transfer to the contract address");

		uint256 burnAmount = _amount.mul(burnRate).div(1000);
		uint256 newAmount = _amount.sub(burnAmount);
		_balances[_sender] = _balances[_sender].sub(_amount);
		_balances[_recipient] = _balances[_recipient].add(newAmount);
		_totalSupply = _totalSupply.sub(burnAmount);
		emit Transfer(_sender, _recipient, _amount);
		emit Burn(burnAmount);
	}

	function approve(address _spender, uint256 _amount) public returns (bool) {
		_approve(msg.sender, _spender, _amount);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
		return _allowances[_owner][_spender];
	}

	function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
		_approve(msg.sender, _spender, _allowances[msg.sender][_spender].add(_addedValue));
		return true;
	}

	function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
		_approve(msg.sender, _spender, _allowances[msg.sender][_spender].sub(_subtractedValue));
		return true;
	}

	function _approve(address _owner, address _spender, uint256 _amount) internal {
		require(_spender != address(0), "Cannot approve to the zero address");
		require(_spender != address(this), "Cannot approve to the contract address");

		_allowances[_owner][_spender] = _amount;
		emit Approval(_owner, _spender, _amount);
	}
}
