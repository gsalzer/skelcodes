pragma solidity ^ 0.5.2;

library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		require(b > 0);
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		require(b <= a);
		uint256 c = a - b;
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a);
		return c;
	}

}

contract Ownable {

	address internal owner_;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed previousOwner);

	constructor() internal {
		owner_ = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner_);
		_;
	}

	function owner() public view returns(address) {
		return owner_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));

		emit OwnershipTransferred(owner_, newOwner);
		owner_ = newOwner;
	}

    function renounceOwnership() onlyOwner public {
        emit OwnershipRenounced(owner_);
        owner_ = address(0);
    }

}

contract Pausable is Ownable {

	bool internal paused_;

	event Pause();
	event Unpause();

	modifier whenNotPaused() {
		require(!paused_);
		_;
	}

	modifier whenPaused() {
		require(paused_);
		_;
	}

	function pause() onlyOwner whenNotPaused public {
		paused_ = true;
		emit Pause();
	}

	function unpause() onlyOwner whenPaused public {
		paused_ = false;
		emit Unpause();
	}

}

contract ERC20Basic is Pausable {

	using SafeMath for uint256;

	string internal name_;
	string internal symbol_;
	uint8 internal decimals_;
	uint256 internal totalSupply_;
	mapping(address => uint256) internal balances_;
	mapping(address => mapping(address => uint256)) internal allowances_;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
	modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length >= size + 4);
        _;
    }

	function name() public view returns(string memory) {
		return name_;
	}

	function symbol() public view returns(string memory) {
		return symbol_;
	}

	function decimals() public view returns(uint8) {
		return decimals_;
	}

	function totalSupply() public view returns(uint256) {
		return totalSupply_;
	}

	function balanceOf(address owner) public view returns(uint256) {
		return balances_[owner];
	}

	function allowance(address owner, address spender) public view returns(uint256) {
		return allowances_[owner][spender];
	}

	function transfer(address to, uint256 value) public onlyPayloadSize(2 * 32) whenNotPaused returns(bool) {
		require(to != address(0));

		balances_[msg.sender] = balances_[msg.sender].sub(value);
		balances_[to] = balances_[to].add(value);
		emit Transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(address from, address to, uint256 value) public onlyPayloadSize(3 * 32) whenNotPaused returns(bool) {
		require(from != address(0));
		require(to != address(0));

		balances_[from] = balances_[from].sub(value);
		balances_[to] = balances_[to].add(value);
		allowances_[from][msg.sender] = allowances_[from][msg.sender].sub(value);
		emit Transfer(from, to, value);
		return true;
	}

	function approve(address spender, uint256 value) public onlyPayloadSize(2 * 32) whenNotPaused returns(bool) {
		require(spender != address(0));
		require(value == 0 || allowances_[msg.sender][spender] == 0);

		allowances_[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

}

contract StandardToken is ERC20Basic {

	function increaseApproval(address spender, uint256 addedValue) public onlyPayloadSize(2 * 32) whenNotPaused returns(bool) {
		require(spender != address(0));

		allowances_[msg.sender][spender] = allowances_[msg.sender][spender].add(addedValue);
		emit Approval(msg.sender, spender, allowances_[msg.sender][spender]);
		return true;
	}

	function decreaseApproval(address spender, uint256 subtractedValue) public onlyPayloadSize(2 * 32) whenNotPaused returns(bool) {
		uint oldValue = allowances_[msg.sender][spender];
		if (subtractedValue >= oldValue) {
			allowances_[msg.sender][spender] = 0;
		} else {
			allowances_[msg.sender][spender] = oldValue.sub(subtractedValue);
		}
		emit Approval(msg.sender, spender, allowances_[msg.sender][spender]);
		return true;
	}

	function batchTransfer(address[] memory tos, uint256[] memory values) public onlyOwner whenNotPaused returns(bool) {
		require(tos.length == values.length);

		for (uint32 i = 0; i < tos.length; i++) {
			super.transfer(tos[i], values[i]);
		}
		return true;
	}

}

contract MintableToken is StandardToken {

	event Burn(address indexed from, uint256 value);
	event Issue(address indexed from, uint256 value);

	function burn(uint256 value) whenNotPaused public returns(bool) {
		balances_[msg.sender] = balances_[msg.sender].sub(value);
		totalSupply_ = totalSupply_.sub(value);
		emit Burn(msg.sender, value);
		return true;
	}

	function issue(uint256 value) onlyOwner whenNotPaused public returns(bool) {
		balances_[msg.sender] = balances_[msg.sender].add(value);
		totalSupply_ = totalSupply_.add(value);
		emit Issue(msg.sender, value);
		return true;
	}

}

contract FreezableToken is MintableToken {

	mapping(address => uint256) internal freezes_;

	event Freeze(address indexed from, uint256 value);
	event Unfreeze(address indexed from, uint256 value);

	function freezeOf(address owner) public view returns(uint256) {
		return freezes_[owner];
	}

	function freeze(uint256 value) whenNotPaused public returns(bool) {
		balances_[msg.sender] = balances_[msg.sender].sub(value);
		freezes_[msg.sender] = freezes_[msg.sender].add(value);
		emit Freeze(msg.sender, value);
		return true;
	}

	function unfreeze(uint256 value) whenNotPaused public returns(bool) {
		freezes_[msg.sender] = freezes_[msg.sender].sub(value);
		balances_[msg.sender] = balances_[msg.sender].add(value);
		emit Unfreeze(msg.sender, value);
		return true;
	}

}

contract ANCToken is FreezableToken {

	constructor() public {
		name_ = "Asset Network Coin";
		symbol_ = "ANC";
		decimals_ = 18;
		totalSupply_ = 100_0000_0000 * (10 ** uint256(decimals_));

		balances_[msg.sender] = totalSupply_;
		emit Transfer(address(0), msg.sender, totalSupply_);
	}

	function() payable external {
		revert();
	}
	
}
