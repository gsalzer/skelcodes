/**
 *Submitted for verification at Etherscan.io on 2021-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function name() external view returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Controller {
    function vaults(address) external view returns (address);
    function rewards() external view returns (address);
}

/*

 A strategy must implement the following calls;

 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()

 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller

*/

interface CurveDeposit{
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function claimable_tokens(address) external view returns (uint256);
}
interface CurveMinter{
    function mint(address) external;
}

interface yERC20 {
  function deposit(uint256 _amount) external;
  function depositAll(uint256[] calldata,address[] calldata)external;
  function withdraw(uint256 _amount) external;
  function getPricePerFullShare() external view returns (uint);
}

interface pERC20 {
  function stake(uint256 ) external;
  function withdraw(uint256 ) external;
  function balanceOf(address) external view returns(uint);
  function earned(address) external view returns (uint);
  function getReward()external;
    function exit() external;
}

interface UniswapRouter {
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

}

interface ZAPPER {
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _allowanceTarget,
        address _swapTarget,
        bytes calldata swapData
    ) external payable returns (uint256);
}

contract StrategyUSDCSLPFarm  {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;


    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address constant public bt = address(0x76c5449F4950f6338A393F53CdA8b53B0cd3Ca3a);

    address constant public want = address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);  //ETH_USDC SLP

    address constant public Harvest = address(0xF8ce90c2710713552fb564869694B2505Bfc0846);
	address constant public fSLP = address(0x01bd09A1124960d9bE04b638b142Df9DF942b04a);
	address constant public pool = address(0x6B4e1E0656Dd38F36c318b077134487B9b0cf7a6);

    address constant public Farm = address(0xa0246c9032bC3A600820415aE600c6388619A14D);

    address constant public zapper = address(0xfF350eDc2242Ca4d7252A64746aec4A5487a852B);
    address constant public pair = address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);  //ETH_USDC SLP
    address constant public swap = address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF);

    address public governance;
    address public controller;

    uint256 public redeliverynum = 100 * 1e18;

    modifier onlyController {
        require(msg.sender == controller, "!controller");
        _;
    }

    constructor() public {
        governance = tx.origin;
        controller = 0x03D2079c54967f463Fd6e89E76012F74EBC62615;
        doApprove();
    }

	function doApprove () internal{
        IERC20(Farm).approve(unirouter, uint(-1));
    }

    function deposit() public {
		uint256 _want = IERC20(want).balanceOf(address(this));
		if (_want > 0)
		{
		    IERC20(want).safeApprove(Harvest, 0);
            IERC20(want).safeApprove(Harvest, _want);
            uint256[] memory amounts;
            address[] memory vadds;
            amounts = new uint256[](1);
            vadds = new address[](1);
            amounts[0] = _want;
            vadds[0] = fSLP;
		    yERC20(Harvest).depositAll(amounts,vadds);
		}
		uint256 _fslp = IERC20(fSLP).balanceOf(address(this));
		if (_fslp >0)
		{
		    IERC20(fSLP).safeApprove(pool,0);
		    IERC20(fSLP).safeApprove(pool, _fslp);
		    pERC20(pool).stake(_fslp);
		}
    }


    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external onlyController
	{
		uint amount = _withdraw(_amount);

		address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault");
        IERC20(want).safeTransfer(_vault, amount);
	}


    function _withdraw(uint _amount) internal returns(uint) {
		uint amount = IERC20(want).balanceOf(address(this));
		if (amount < _amount) {
			_withdrawSome(_amount.sub(amount));
			amount = IERC20(want).balanceOf(address(this));
            if (amount < _amount){
                return amount;
            }
        }
		return _amount;
    }

    function _withdrawSome(uint _amount) internal
    {
        uint256 _fslp = _amount.mul(1e18).div(yERC20(fSLP).getPricePerFullShare());
		uint _before = IERC20(fSLP).balanceOf(address(this));
		if (_before < _fslp) {
			_fslp = _fslp.sub(_before);
			//require(_fweth <= IERC20(pool).balanceOf(address(this)),"Insufficient Balance");
            if(_fslp >= IERC20(pool).balanceOf(address(this))){
                pERC20(pool).exit();
            } else {
			    pERC20(pool).withdraw(_fslp);
            }
		}

		_fslp = IERC20(fSLP).balanceOf(address(this));
		yERC20(fSLP).withdraw(_fslp);
    }

	function withdrawAll() external onlyController returns (uint balance){
		uint amount = balanceOf();
		balance = _withdraw(amount);

		address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault");
        IERC20(want).safeTransfer(_vault, balance);
	}

	function balanceOfwant() public view returns (uint256) {
		return IERC20(want).balanceOf(address(this));
	}

	function balanceOfFSLP() public view returns (uint256) {
	    uint256 _ftoken = IERC20(fSLP).balanceOf(address(this));
		return _ftoken.add(IERC20(pool).balanceOf(address(this)));
	}


    function balanceOf() public view returns (uint256) {
        return balanceOfwant().add(balanceOfFSLP().mul(yERC20(fSLP).getPricePerFullShare()).div(1e18));
    }

    function getPending() public view returns (uint256) {
        return pERC20(pool).earned(address(this));
    }

	function getFarm() public view returns(uint256)
	{
		return IERC20(Farm).balanceOf(address(this));
	}

    function harvest() public
    {
        pERC20(pool).getReward();
        redelivery();
    }

    function redelivery() internal {
        uint256 reward = IERC20(Farm).balanceOf(address(this));
        if (reward > redeliverynum) {
            uint256 _2weth = reward.mul(80).div(100); //80%
		    uint256 _2bt = reward.sub(_2weth);  //20%
		    _swapUniswap(Farm,weth, _2weth);
			_redelivery();
		    _swapUniswap(Farm,bt,_2bt);
            IERC20(bt).safeTransfer(Controller(controller).rewards(), IERC20(bt).balanceOf(address(this)));
		}
        deposit();
    }

    function _redelivery() internal
    {
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            IERC20(weth).safeApprove(zapper,0);
		    IERC20(weth).safeApprove(zapper, _weth);
            ZAPPER(zapper).ZapIn(
                weth,
                pair,
                _weth,
                0,
                swap,
                swap,
                new bytes(0));
        }
    }

     function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        // Swap with uniswap
        IERC20(_from).safeApprove(unirouter, 0);
        IERC20(_from).safeApprove(unirouter, _amount);

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouter(unirouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(1800)
        );
    }

    function setredeliverynum(uint256 value) public
    {
        require(msg.sender == governance, "!governance");
        redeliverynum = value;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}
