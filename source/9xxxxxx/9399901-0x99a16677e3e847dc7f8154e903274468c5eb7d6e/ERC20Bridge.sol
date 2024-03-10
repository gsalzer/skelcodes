pragma solidity ^0.4.26;

import "SafeMath.sol";
import "Ownable.sol";
import "ERC20.sol";

/**
 * @title ERC20Bridge
 * @dev Ethereum ERC20 Coin to Charg Network Bridge
 */
contract ERC20Bridge is Ownable {

	using SafeMath for uint;

    uint public validatorsCount = 0;
    uint public validationsRequired = 2;

    ERC20 private erc20Instance;  

    struct Transaction {
		address initiator;
		uint amount;
		uint validated;
		bool completed;
	}

    event FundsReceived(address indexed initiator, uint amount);

    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);

    event Validated(bytes32 indexed txHash, address indexed validator, uint validatedCount, bool completed);

    mapping (address => bool) public isValidator;

    mapping (bytes32 => Transaction) public transactions;
	mapping (bytes32 => mapping (address => bool)) public validatedBy; // is validated by 

	constructor(address _addr) public {
		erc20Instance = ERC20(_addr);
    }

    //fallback
	function() external payable {
		revert();
	}

	function setValidationsRequired( uint value ) onlyOwner public {
        require (value > 0);
        validationsRequired = value;
	}

	function addValidator( address _validator ) onlyOwner public {
        require (!isValidator[_validator]);
        isValidator[_validator] = true;
        validatorsCount = validatorsCount.add(1);
        emit ValidatorAdded(_validator);
	}

	function removeValidator( address _validator ) onlyOwner public {
        require (isValidator[_validator]);
        isValidator[_validator] = false;
        validatorsCount = validatorsCount.sub(1);
        emit ValidatorRemoved(_validator);
	}

	function validate(bytes32 _txHash, address _initiator, uint _amount) public {
        
        require (isValidator[msg.sender]);
        require ( !transactions[_txHash].completed );
        require ( !validatedBy[_txHash][msg.sender] );

        if ( transactions[_txHash].initiator == address(0) ) {
            require ( _amount > 0 && erc20Instance.balanceOf(address(this)) > _amount );
            transactions[_txHash].initiator = _initiator;
            transactions[_txHash].amount = _amount;
            transactions[_txHash].validated = 1;

        } else {
            require ( transactions[_txHash].amount > 0 );
            require ( erc20Instance.balanceOf(address(this)) > transactions[_txHash].amount );
            require ( _initiator == transactions[_txHash].initiator );
            require ( transactions[_txHash].validated < validationsRequired );
            transactions[_txHash].validated = transactions[_txHash].validated.add(1);
        }
        validatedBy[_txHash][msg.sender] = true;
        if (transactions[_txHash].validated >= validationsRequired) {
    		//_initiator.transfer(_amount);
            erc20Instance.transfer(_initiator, _amount);
            transactions[_txHash].completed = true;
        }
        emit Validated(_txHash, msg.sender, transactions[_txHash].validated, transactions[_txHash].completed);
	}
}
