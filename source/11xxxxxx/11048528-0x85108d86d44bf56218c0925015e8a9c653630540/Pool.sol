// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./Token.sol";
import "./1inch.sol";

contract Pool is ERC20 {
    
    using SafeMath for uint;

	address public constant EXCHANGE_CONTRACT = 0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e;
	address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	address public TMTTokenAddress;

	uint[] public holders;

	address[] public tokens; 
	uint[] public weights;
	uint totalWeight;

	//-----------------------------
	uint[] buf; 
	address[] newTokens;
	uint[] newWeights;

	uint newTotalWeight;
	//-----------------------------

	mapping(address => uint) public tokenBalances;

	bool public active = true; 
	
	mapping(address => bool) public systemAddresses;
	
	modifier systemOnly {
	    require(systemAddresses[msg.sender], "system only");
	    _;
	}

	modifier isActive() { 
		require (active); 
		_; 
	}
	
	event Withdrawn(address indexed from, uint value);
	event WithdrawnToken(address indexed from, address indexed token, uint amount);
	
	function addSystemAddress(address newSystemAddress) public systemOnly {
	    systemAddresses[newSystemAddress] = true;
	}
	
	constructor(string memory name, string memory symbol, address _TMTTokenAddress, address[] memory _tokens, uint[] memory _weights) public ERC20(name, symbol) {
		require (_tokens.length == _weights.length, "invalid config length");
		
		systemAddresses[msg.sender] = true;

		TMTTokenAddress = _TMTTokenAddress;
		
		uint _totalWeight;

		for(uint i = 0; i < _tokens.length; i++) {
			tokens.push(_tokens[i]);
			weights.push(_weights[i]);
			_totalWeight += _weights[i];
		}
	}

	function poolIn(address[] memory _tokens, uint[] memory _values) public payable isActive() {
		// require(IERC20(TMTTokenAddress).balanceOf(msg.sender) > 0, "TMTToken balance must be greater then 0");
		address[] memory returnedTokens;
		uint[] memory returnedAmounts;
		uint ethValue;
		
		if(_tokens.length == 0) {
			require (msg.value > 0.001 ether, "0.001 ether min pool in");
			ethValue = msg.value;

			(returnedTokens, returnedAmounts) = swap(ETH_ADDRESS, ethValue, tokens, weights, totalWeight);
		} else if(_tokens.length == 1) {
			ethValue = calculateTokensForEther(_tokens, _values);
			assert(ethValue > 0.001 ether);

			(returnedTokens, returnedAmounts) = swap(_tokens[0], _values[0], tokens, weights, totalWeight);
		} else {
			ethValue = sellTokensForEther(_tokens, _values);
			assert(ethValue > 0.001 ether);

			(returnedTokens, returnedAmounts) = swap(ETH_ADDRESS, ethValue, tokens, weights, totalWeight);
		}

		for (uint i = 0; i < returnedTokens.length; i++) {
			tokenBalances[returnedTokens[i]] += returnedAmounts[i];
		}

		_mint(msg.sender, ethValue);
	}

	function withdraw() public {
		uint _balance = balanceOf(msg.sender);
		uint localWeight = _balance.mul(1 ether).div(totalSupply());
		require(localWeight > 0, "no balance in this pool");

		_burn(msg.sender, _balance);

		for (uint i = 0; i < tokens.length; i++) {
			uint withdrawBalance = tokenBalances[tokens[i]].mul(localWeight).div(1 ether);
			tokenBalances[tokens[i]] = tokenBalances[tokens[i]].sub(withdrawBalance);
			IERC20(tokens[i]).transfer(msg.sender, withdrawBalance);

			emit WithdrawnToken(msg.sender, tokens[i], withdrawBalance);
		}


		emit Withdrawn(msg.sender, _balance);
	}

	function updatePool(address[] memory _tokens, uint[] memory _weights) public systemOnly {
	    
		require(_tokens.length == _weights.length, "invalid config length");
		
		uint _newTotalWeight;

		for(uint i = 0; i < _tokens.length; i++) {
			require (_tokens[i] != ETH_ADDRESS && _tokens[i] != WETH_ADDRESS);			
			_newTotalWeight += _weights[i];
		}
		
		newTokens = _tokens;
		newWeights = _weights;
		newTotalWeight = _newTotalWeight;

		rebalance();
	}

	function setPoolStatus(bool _active) public systemOnly {
		active = _active;
	}

	function calculateTokensForEther(address[] memory _tokens, uint[] memory _amounts) public view returns(uint) {
		uint _amount;
		uint _totalAmount;
		uint[] memory _distribution;
		for(uint i = 0; i < _tokens.length; i++) {
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_tokens[i]), IERC20(WETH_ADDRESS), _amounts[i], 2, 0);
			_totalAmount += _amount;
		}

		return _totalAmount;
	}
	
	/*
	 * @dev sell array of tokens for ether
	 */
	function sellTokensForEther(address[] memory _tokens, uint[] memory _amounts) internal returns(uint) {
		uint _amount;
		uint _totalAmount;
		uint[] memory _distribution;
		for(uint i = 0; i < _tokens.length; i++) {
		    if (_amounts[i] == 0) {
		        continue;
		    }
		    
		    if (_tokens[i] == WETH_ADDRESS) {
		        _totalAmount += _amounts[i];
		        continue;
		    }
		    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _amounts[i]);
		    
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_tokens[i]), IERC20(WETH_ADDRESS), _amounts[i], 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    
			IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_tokens[i]), IERC20(WETH_ADDRESS), _amounts[i], _amount, _distribution, 0);

			_totalAmount += _amount;
		}

		return _totalAmount;
	}

	function rebalance() internal {
	    
		uint[] memory buf2;
		buf = buf2;

		for (uint i = 0; i < tokens.length; i++) {
			buf.push(tokenBalances[tokens[i]]);
			tokenBalances[tokens[i]] = 0;
		}
		
		
		uint ethValue = sellTokensForEther(tokens, buf);
		

		tokens = newTokens;
		weights = newWeights;
		totalWeight = newTotalWeight;
		
		if (ethValue == 0) {
		    return;
		}
		
		buf = buf2;
		swap2(WETH_ADDRESS, ethValue);
		
		for(uint i = 0; i < tokens.length; i++) {
			tokenBalances[tokens[i]] = buf[i];
		}
	}

	function swap(address _token, uint _value, address[] memory _tokens, uint[] memory _weights, uint _totalWeight) internal returns(address[] memory, uint[] memory) {
		uint _tokenPart;
		uint _amount;
		uint[] memory _distribution;
        
		for(uint i = 0; i < _tokens.length; i++) {
			_tokenPart = _value.mul(_weights[i]).div(_totalWeight);

			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_token), IERC20(_tokens[i]), _tokenPart, 2, 0);

			if (_token == ETH_ADDRESS) {
				IOneSplit(EXCHANGE_CONTRACT).swap.value(_tokenPart)(IERC20(_token), IERC20(_tokens[i]), _tokenPart, _amount, _distribution, 0);
			} else {
			    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _tokenPart);
				IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_token), IERC20(_tokens[i]), _tokenPart, _amount, _distribution, 0);
			}
			
			_weights[i] = _amount;
		}
		
		return (_tokens, _weights);
	}
	
	function swap2(address _token, uint _value) internal {
		uint _tokenPart;
		uint _amount;
		
		uint[] memory _distribution;
		
		IERC20(_token).approve(EXCHANGE_CONTRACT, _value);
		
		for(uint i = 0; i < newTokens.length; i++) {
            
			_tokenPart = _value.mul(newWeights[i]).div(newTotalWeight);
			
			if(_tokenPart == 0) {
			    buf.push(0);
			    continue;
			}
			
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_token), IERC20(newTokens[i]), _tokenPart, 5, 0);
			
			
			IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_token), IERC20(newTokens[i]), _tokenPart, _amount, _distribution, 0);
            buf.push(_amount);
            
            
		}
	}

	function calculateAmountsViaWeights(uint _ethAmount) public view returns(uint[] memory res) {
		for(uint i = 1; i <= tokens.length; i++) {
			res[i] = _ethAmount.mul(weights[i]).div(totalWeight);
		}
	}
}
