contract GVolDaoTreasury {
	// State variables
	address payable public owner;
	uint256 public registrationFee;
	uint256 public subscriptionLength;

	// Address to expiration mapping for customers
	mapping(address => uint256) public customers;

	//@Dev Constructor setting intital owwner set to contract deployer & initializes regestration Fee to .1ETH.
	constructor() {
		owner = payable(msg.sender);
		registrationFee = .1 ether;
		subscriptionLength = 183 days;
	}

	//@Dev modifier: OnlyOwner requirement for admin functions.
	modifier onlyOwner() {
		require(msg.sender == owner, 'Only Owner Can Perform this function');
		_;
	}
    
    event newSubscription (address indexed _subscriber, uint indexed _subscriptionDate, uint _fee);
    
	//@dev Customer subscription function. Checks if customer exists first then adds to customers array, if sufficient payment was provided
	function subscribe() public payable {
		require(msg.value >= registrationFee, 'Insufficient funds sent');

		uint256 exp = customers[msg.sender];
		require(exp != type(uint256).max, 'You are a whitelisted user');
		customers[msg.sender] = (exp > block.timestamp ? exp : block.timestamp) + subscriptionLength ; 
		emit newSubscription(msg.sender, block.timestamp, msg.value);
	}

	//@dev checks if a user has an active subscription
	function isActive(address user) public view returns (bool) {
		return customers[user] > block.timestamp;
	}

	function untilExpiration(address user) public view returns (uint256) {
		return customers[user] < block.timestamp ? 0 : customers[user] - block.timestamp;
	}

	// ADMIN FUNCTIONS
	// @dev sets new `owner` state variable. Granting new owner control to admin functions.
	// @param address.New address to be set.
	function setNewOwner(address payable newOwner) public onlyOwner {
		owner = newOwner;
	}

	// @dev sets new `registrationFee` state variable. Owner can set access price.
	// @param  value to set new registration fee. Remember to set value to approiate decimal places. 1 ETH = 1000000000000000000, .069 ETH = 69000000000000000
	function setNewRegistrationFee(uint256 newFee) public onlyOwner {
		registrationFee = newFee;
	}
	
		// @dev sets new `subscriptionLenght` state variable. Owner can set access price.
	// @param  value to set new subscription length. Number of days in Epoch time.  1 Day = 86400
	function setNewSubscriptionLength(uint256 newSubscriptionLength) public onlyOwner {
		subscriptionLength = newSubscriptionLength;
	}

	//@Dev Allow Owner of the contract to withdraw the balances to themselves.
	function withdrawToOwner() public onlyOwner {
		owner.transfer(address(this).balance);
	}

	// @Dev Allow Owner of the contract to withdraw a specified amount to a different address.
	// @Notice Could be used for funding a New Dao contract, another dApp, or gitcoin Grant.
	function withdrawToAddress(address payable recipient, uint256 amount) public onlyOwner {
		recipient.transfer(amount);
	}

	//@Dev Allow owner of the contract to set an address to True in mapping without payment.
	function freeAccount(address _address) public onlyOwner {
		customers[_address] = type(uint256).max;
	}

	//@Dev Allow owner of the contract to set an address to True in mapping without payment.
	function resetUser(address _address) public onlyOwner {
		customers[_address] = 0;
	}

	//fallback
	fallback() external payable {
		owner.transfer(msg.value);
	}
}
