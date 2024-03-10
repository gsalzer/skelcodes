
// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import "./Interfaces.sol";




contract BPTDistribute is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public bal = address(0xba100000625a3754423978a60c9317c58a424e3D);
    address constant public chiAddress = address(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    address public balancer;
    address public balswap;
    address public defaultDepositToken;

    address[10] public accounts;
    

    constructor() public {
    	balancer = address(0xc409D34aCcb279620B1acDc05E408e287d543d17); //wbtc/ren/weth bpt
        balswap = address(0x59A19D8c652FA0284f44113D0ff9aBa70bd46fB4); //weth/bal pool

        defaultDepositToken = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //default weth

        IERC20(defaultDepositToken).approve(balancer,uint(-1));
        IERC20(bal).approve(balswap,uint(-1));
    }

    
    function setup(address _poolAddress, address _swapAddress, address _defaultToken) onlyOwner external {
        balancer = _poolAddress;
        balswap = _swapAddress;
        defaultDepositToken = _defaultToken;
        IERC20(defaultDepositToken).approve(balancer,uint(-1));
        IERC20(bal).approve(balswap,uint(-1));
    }

    function setAccount(address _address, uint _index) onlyOwner external {
        require(_index < accounts.length, "index too high");
        accounts[_index] = _address;
    }

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        Chi(chiAddress).freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function dumpBalWithChi() discountCHI public{
        dumpBal();
    }
    
    function dumpBal() public{
    	uint[] memory userValues = new uint[](accounts.length);

    	//grab all bal from accounts
    	for (uint i = 0; i < accounts.length; i++) {
	    	if(accounts[i] == address(0)) break;

	    	uint allowance = IERC20(bal).allowance(accounts[i],address(this));
	    	uint balance = IERC20(bal).balanceOf(accounts[i]);
	    	if (balance > 0 && allowance >= balance){
	    		userValues[i] = balance;
		    	IERC20(bal).transferFrom(accounts[i],address(this),balance);
		    }	
	    }
	    uint totalBal = IERC20(bal).balanceOf(address(this));

        require(totalBal > 0, "no bal to convert");

	    //change bal into token we want to deposit
        Balancer(balswap).swapExactAmountIn(bal, totalBal, defaultDepositToken, uint(0), uint(-1));

        uint depositTokenBalance = IERC20(defaultDepositToken).balanceOf(address(this));

        //deposit to bpt
        Balancer(balancer).joinswapExternAmountIn(defaultDepositToken, depositTokenBalance, 0);

        //total bpt gained
        uint bptBalance = IERC20(balancer).balanceOf(address(this));

        //distribute
        for (uint i = 0; i < accounts.length; i++) {
	    	if(accounts[i] == address(0)) break;

	    	//share = bpt * (user bal amount / total bal)
	    	uint bptAmount = bptBalance.mul(userValues[i]).div(totalBal);
	    	IERC20(balancer).transfer(accounts[i],bptAmount);
	    }
    }

	// incase of half-way error
	function inCaseTokenGetsStuck(IERC20 _TokenAddress) onlyOwner public {
	  uint qty = _TokenAddress.balanceOf(address(this));
	  _TokenAddress.safeTransfer(msg.sender, qty);
	}

	// incase of half-way error
	function inCaseETHGetsStuck() onlyOwner public{
		(bool result, ) = msg.sender.call.value(address(this).balance)("");
		require(result, "transfer of ETH failed");
	}
}
