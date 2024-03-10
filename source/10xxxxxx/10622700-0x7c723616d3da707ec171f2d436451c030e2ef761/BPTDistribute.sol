
// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import "./Interfaces.sol";


interface Balancer {
    function joinPool(uint,uint[] calldata) external;
    function exitPool(uint,uint[] calldata) external;
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external returns(uint poolAmountOut);
}

interface OneSplitAudit {
    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags
    )
        external
        payable
        returns(uint256 returnAmount);
    
    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

contract BPTDistribute is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address constant public renbtc = address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    address constant public bal = address(0xba100000625a3754423978a60c9317c58a424e3D);
    address constant public chiAddress = address(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);


    address public balancer;
    address public onesplit;
    uint256 public onesplitParts;

    address[10] public accounts;
    

    constructor() public {
    	balancer = address(0xc409D34aCcb279620B1acDc05E408e287d543d17); //wbtc/ren/weth bpt
    	onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
        onesplitParts = 7;

        IERC20(weth).approve(balancer,uint(-1));
        IERC20(wbtc).approve(balancer,uint(-1));
        IERC20(renbtc).approve(balancer,uint(-1));
    }

    function setOneSplit(address _address, uint256 _parts) onlyOwner external {
    	onesplit = _address;
        onesplitParts = _parts;
    }
    
    function setBalancerPool(address _address) onlyOwner external {
        balancer = _address;
    }

    function setApproval(address _token) onlyOwner external{
    	IERC20(_token).approve(balancer,uint(-1));
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

    function dumpBalWithChi(address _tokenToDeposit) discountCHI public{
        dumpBal(_tokenToDeposit);
    }
    
    function dumpBal(address _tokenToDeposit) public{
    	uint[] memory userValues = new uint[](accounts.length);

    	//grab all bal from accounts
    	for (uint i = 0; i < accounts.length; i++) {
	    	if(accounts[i] == address(0)) break;

	    	uint allowance = IERC20(bal).allowance(accounts[i],address(this));
	    	uint balance = IERC20(bal).balanceOf(accounts[i]);
	    	if (allowance >= balance){
	    		userValues[i] = balance;
		    	IERC20(bal).transferFrom(accounts[i],address(this),balance);
		    }	
	    }
	    uint totalBal = IERC20(bal).balanceOf(address(this));


	    //change bal into token we want to deposit
	    uint[] memory _distribution;
        uint _expected;
        (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(bal, _tokenToDeposit, totalBal, onesplitParts, 0);
        OneSplitAudit(onesplit).swap(bal, _tokenToDeposit, totalBal, _expected, _distribution, 0);

        uint depositTokenBalance = IERC20(_tokenToDeposit).balanceOf(address(this));

        //deposit to bpt
        Balancer(balancer).joinswapExternAmountIn(_tokenToDeposit, depositTokenBalance, 0);


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
