//Be name khoda

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./AccessControl.sol";
import "./SafeMath.sol";

interface CoinbaseToken {
    function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
}
interface DEUSToken {
	function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract StaticPriceSale is AccessControl{

    using SafeMath for uint256;

	event Buy(address user, uint256 coinbaseTokenAmount, uint256 deusAmount, uint256 feeAmount);
	event Sell(address user, uint256 deusAmount, uint256 coinbaseTokenAmount, uint256 feeAmount);

	struct User {
        uint256 usedCap;
        uint256 maxCap;
		bool inited;
    }

	mapping (address => User) public users;

	bytes32 public constant CAP_CONTROLLER_ROLE = keccak256("CAP_CONTROLLER_ROLE");

	uint256 public totalUsedCap;
	uint256 public totalMaxCap;

    uint256 public endBlock;

	uint256 public spread;
	uint256 public price;
	uint256 public initialUserMaxCap;

	address public feeWallet;

    CoinbaseToken public coinbaseToken;
	DEUSToken public deusToken;

    constructor (
		address _coinbaseToken,
		address _deusToken,
		address _feeWallet,
		uint256 _endBlock,
		uint256 _spread,
		uint256 _price,
		uint256 _initialUserMaxCap,
		uint256 _totalMaxCap
	) public {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

		coinbaseToken = CoinbaseToken(_coinbaseToken);
		deusToken = DEUSToken(_deusToken);
		feeWallet = _feeWallet;
		endBlock = _endBlock;
		spread = _spread;
		price = _price;
		initialUserMaxCap = _initialUserMaxCap;
		totalMaxCap = _totalMaxCap;
    }

    function setEndBlock(uint256 _endBlock) public{
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        endBlock = _endBlock;
    }

	function setSpreadAndPrice(uint256 _spread, uint256 _price) public{
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        spread = _spread;
		price = _price;
    }

	function setFeeWallet(address _feeWallet) public{
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        feeWallet = _feeWallet;
    }

	function setTotalMaxCap(uint256 _totalMaxCap, uint256 _initialUserMaxCap) public{
		require(hasRole(CAP_CONTROLLER_ROLE, msg.sender), "Caller is not an admin");
        totalMaxCap = _totalMaxCap;
		initialUserMaxCap = _initialUserMaxCap;
    }

	function setUserMaxCap(address user, uint256 userMaxCap) public{
		require(hasRole(CAP_CONTROLLER_ROLE, msg.sender), "Caller is not an cap controller");
        users[user].maxCap = userMaxCap;
    }


	function calculatePurchaseReturn(uint256 deusAmount) public view returns (uint256, uint256) {
		uint256 feeAmount = deusAmount.mul(spread).div(1e18);
		return (deusAmount.sub(feeAmount).mul(1e18).div(price), feeAmount);
	}

    function buyFor(address _user, uint256 coinbaseTokenAmount, uint256 deusAmount) public {
        require(block.number <= endBlock, 'static price sale has been finished');
		(uint256 purchasedAmount, uint256 feeAmount) = calculatePurchaseReturn(deusAmount);
		require (coinbaseTokenAmount <= purchasedAmount, 'wrong price');

		User storage user = users[_user];

		if (!user.inited){
			user.maxCap = initialUserMaxCap;
		}

		user.usedCap = user.usedCap.add(purchasedAmount);
		require(user.usedCap <= user.maxCap, "the bought amount exceeds the user buy cap");

		totalUsedCap = totalUsedCap.add(purchasedAmount);
		require(totalUsedCap <= totalMaxCap, "the bought amount exceeds the total buy cap");
		
		deusToken.transferFrom(address(msg.sender), address(this), deusAmount);
		deusToken.transfer(feeWallet, feeAmount);

        coinbaseToken.mint(_user, purchasedAmount);

		emit Buy(_user, purchasedAmount, deusAmount, feeAmount);
    }

	function buy(uint256 coinbaseTokenAmount, uint256 deusAmount) public {
		buyFor(msg.sender, coinbaseTokenAmount, deusAmount);
	}

	function calculateSaleReturn(uint256 coinbaseTokenAmount) public view returns (uint256, uint256) {
		uint256 deusAmount = coinbaseTokenAmount.mul(price).div(1e18);
		uint256 feeAmount = deusAmount.mul(spread).div(1e18);
		return (deusAmount.sub(feeAmount), feeAmount);
	}

	function sellFor(address _user, uint256 coinbaseTokenAmount, uint256 deusAmount) public {
        require(block.number <= endBlock, 'static price sale has been finished');
		(uint256 returnedDeusAmount, uint256 feeAmount) = calculateSaleReturn(coinbaseTokenAmount);
		require ( deusAmount <= returnedDeusAmount, 'wrong price');

		User storage user = users[_user];

		user.usedCap = user.usedCap.sub(coinbaseTokenAmount);
		totalUsedCap = totalUsedCap.sub(coinbaseTokenAmount);

        coinbaseToken.burn(msg.sender, coinbaseTokenAmount);
		deusToken.transfer(_user, returnedDeusAmount);
		deusToken.transfer(feeWallet, feeAmount);

		emit Sell(_user, returnedDeusAmount, coinbaseTokenAmount, feeAmount);
    }

	function sell(uint256 coinbaseTokenAmount, uint256 deusAmount) public {
		sellFor(msg.sender, coinbaseTokenAmount, deusAmount);
	}

	function withdraw(address payable to, uint256 amount) public{
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        deusToken.transfer(to, amount);
    }

}

//Dar panah khoda
