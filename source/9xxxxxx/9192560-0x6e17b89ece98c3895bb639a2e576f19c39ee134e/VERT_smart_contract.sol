pragma solidity ^0.5.7;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        
	return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20Standard{
	using SafeMath for uint256;
    uint public totalSupply;
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;
	uint totalReward;
    uint lastDivideRewardTime = 1609372800;
    uint restReward;
    uint256 public balance;
        
    struct TokenHolder {
        uint256 shares;
        uint       BalanceUpdateTime;
        uint       rewardWithdrawTime;
    }
    mapping(address => TokenHolder) holders;
    mapping (address => uint256) public shares;
      uint totalTokens = totalSupply;
	
	mapping (address => mapping (address => uint)) allowed;

	//Fix for short address attack against ERC20
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

	function balanceOf(address _owner) public view returns (uint sharesOf) {
		return shares[_owner];
	}

	function transfer(address _recipient, uint _value) public onlyPayloadSize(2*32) {
	    require(shares[msg.sender] >= _value && _value > 0);
	    shares[msg.sender] = shares[msg.sender].sub(_value);
	    shares[_recipient] = shares[_recipient].add(_value);
	    emit Transfer(msg.sender, _recipient, _value);        
        }

	function transferFrom(address _from, address _to, uint _value) public  returns (bool success){
	    require(shares[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
            shares[_to] = shares[_to].add(_value);
            shares[_from] = shares[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        }

	function  approve(address _spender, uint _value) public {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) public view returns (uint sharesOf) {
		return allowed[_owner][_spender];
	}

	//Event which is triggered to log all transfers to this contract's event log
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
	//Event which is triggered whenever an owner approves a new allowance for a spender.
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);

function reward() view public returns(uint) {
        return totalReward * holders[msg.sender].shares / totalTokens;
    }

    function withdrawReward() public returns(uint) {
        uint value = reward();
        if (value == 0) {
            return 0;
        }
        if (!msg.sender.send(value)) {
            return 0;
        }
        if (shares[msg.sender] == 0) {
            // garbage collector
            delete holders[msg.sender];
        } else {
            holders[msg.sender].rewardWithdrawTime = now;
        }
        return value;
    }

    // Divide up reward and make it accesible for withdraw
    function divideUpReward() public onlyPayloadSize(2*32){
        require (lastDivideRewardTime + 30 days > now);
        lastDivideRewardTime = now;
        uint share = shares[msg.sender];
        shares[msg.sender] = 0;
        msg.sender.transfer(share);
    }

    function beforeBalanceChanges(address _who) public {
        if (holders[_who].BalanceUpdateTime <= lastDivideRewardTime) {
            holders[_who].BalanceUpdateTime = now;
            holders[_who].shares = shares[_who];
        }
    }
}



