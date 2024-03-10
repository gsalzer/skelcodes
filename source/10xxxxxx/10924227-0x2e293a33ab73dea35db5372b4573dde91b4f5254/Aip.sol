pragma solidity ^0.5.0;

import "./IERC20.sol";

contract Pool2 is IERC20 {
    function stake(uint256 amount) external returns (bool);

    function getReward() external returns (bool);

    function withdraw(uint256 amount) external returns (bool);

    function exit() external returns (bool);
}

contract BptToken is IERC20 {
    function getBalance(address token) external returns (uint256);

    function calcOutGivenIn(uint256 tokenBalanceIn, uint256 tokenWeightIn, uint256 tokenBalanceOut, uint256 tokenWeightOut, uint256 tokenAmountIn, uint256 swapFee) external returns (uint256);

    function calcSpotPrice(uint256 tokenBalanceIn, uint256 tokenWeightIn, uint256 tokenBalanceOut, uint256 tokenWeightOut, uint256 swapFee) external returns (uint256);

    function joinswapExternAmountIn(address tokenIn, uint256 tokenAmountIn, uint256 minPoolAmountOut) external returns (uint256);

    function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn) external returns (uint256);

    function swapExactAmountIn(address tokenIn, uint256 tokenAmountIn, address tokenOut, uint256 minAmountOut, uint256 maxPrice) external returns (bool);
}

contract WETHToken is IERC20 {
    function deposit() public payable ;
}

library SafePool2 {
    using SafeMath for uint256;
    using Address for address;

    function safeStake(Pool2 token, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.stake.selector, value));
    }

    function safeGetReward(Pool2 token) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.getReward.selector));
    }

    function safeWithdraw(Pool2 token, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.withdraw.selector, value));
    }

    function safeExit(Pool2 token) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.exit.selector));
    }

    function callOptionalReturn(Pool2 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeBpt {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(BptToken token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function callOptionalReturn(BptToken token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeWETH {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

import "./Math.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract AipRewards is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafePool2 for Pool2;
    using SafeWETH for WETHToken;
    using SafeBpt for BptToken;

    // pool0
    IERC20 public pool0 = IERC20(0xFB594B135A09dD86Bf764fd902a544435091a42A);
    // weth
    WETHToken public weth = WETHToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // kani
    IERC20 public kani = IERC20(0x790aCe920bAF3af2b773D4556A69490e077F6B4A);
    // bpt
    BptToken public bpt = BptToken(0x8B2E66C3B277b2086a976d053f1762119A92D280);
    // pool2
    Pool2 public pool2 = Pool2(0x14d41EAaC22eb027dC9EC49bB7F98b123f9e0c68);

    // weth
    uint256 public constant totalSupply = 500*1e18;
    uint256 public constant dailyJoin = 50*1e18;
    uint256 public totalJoined = 0;
    uint256 public lastJoinTime = 0;

    uint256 public rewardStartTime = 0;
    uint256 public totalReward = 0;
    uint256 public rewardPaid = 0;
    uint256 public bptPaid = 0;
    uint256 public bptReward = 0;
    mapping(address => uint256) public rewardPaids;
    mapping(address => uint256) public bptPaids;

    event JoinPool(address indexed pool, uint256 amount);
    event Staked(address indexed pool, uint256 amount);
    event RewardPaid(address indexed user, address indexed token, uint256 reward);

    function() external payable {
        weth.deposit.value(msg.value)();
    }

    function init() public onlyOwner{
        require(weth.balanceOf(address(this)) >= totalSupply, "balance not enough");
        require(lastJoinTime == 0, "inited");
        lastJoinTime = block.timestamp.sub(1 days);
        rewardStartTime = block.timestamp.add(1 days);
        joinPool();
    }

    /** balancer pool actions */
    // balancer pool : weth <=> kani
    // deposit eth to weth
    // join weth to b-pool and get bpt back
    // stake bpt to pool2
    function joinPool() public {
        require(lastJoinTime > 0, "not start");
        if (block.timestamp.sub(lastJoinTime) >= 1 days
            && totalJoined < totalSupply) {
            totalJoined = totalJoined.add(dailyJoin);
            lastJoinTime = block.timestamp;
            // and liquidity and get bpt
            uint256 reward = dailyJoin.mul(1).div(100);
            weth.approve(address(bpt), dailyJoin.sub(reward));
            uint256 amount = bpt.joinswapExternAmountIn(address(weth), dailyJoin.sub(reward), 0);
            emit JoinPool(address(bpt), dailyJoin.sub(reward));
            // stake bpt to pool2
            stake(amount);
            // get kani reward from pool2
            withdrawKani();
            // reward
            weth.safeTransfer(msg.sender, reward);
        }
    }

    // get weth back from balancer pool
    function exitBPool(uint256 amount) public onlyOwner {
        bpt.exitswapExternAmountOut(address(weth), amount, bpt.balanceOf(address(this)));
    }

    /** pool2 actions */
    // stake bpt to pool2
    function stake(uint256 amount) internal {
        if (amount > 0) {
            bpt.approve(address(pool2), amount);
            pool2.safeStake(amount);
            emit Staked(address(pool2), amount);
        }
    }

    // get kani reward from pool2
    function withdrawKani() internal {
        pool2.safeGetReward();
        totalReward = kani.balanceOf(address(this)).add(rewardPaid);
    }

    // get bpt & kani reward back
    function exitPool2() public onlyOwner {
        pool2.safeExit();
        totalReward = kani.balanceOf(address(this)).add(rewardPaid);
    }

    // get bpt back
    function withdrawBpt(uint256 amount) public onlyOwner {
        require(block.timestamp.sub(rewardStartTime) > 10 days, "not start");
        require(pool2.balanceOf(address(this)) >= amount, "balance not enough");
        pool2.safeWithdraw(amount);
        bptReward = bpt.balanceOf(address(this)).add(bptPaid);
    }

    /** user actions */
    // user get total earned kani
    function kaniEarned(address account) public view returns (uint256) {
        if (block.timestamp < rewardStartTime || totalReward <= 0)  return 0;
        return pool0.balanceOf(account).mul(totalReward).div(totalSupply);
    }

    // user get kani reward
    function getKaniReward() public checkStart {
        uint256 reward = kaniEarned(msg.sender).sub(rewardPaids[msg.sender]);
        if (reward > 0) {
            rewardPaids[msg.sender] = rewardPaids[msg.sender].add(reward);
            kani.safeTransfer(msg.sender, reward);
            rewardPaid = rewardPaid.add(reward);
            emit RewardPaid(msg.sender, address(kani), reward);
        }
    }

    // user get total earned bpt
    function bptEarned(address account) public view returns (uint256) {
        return pool0.balanceOf(account).mul(bptReward).div(totalSupply);
    }

    // user get bpt reward
    function getBptReward() public {
        require(block.timestamp.sub(rewardStartTime) > 10 days, "not start");
        uint256 reward = bptEarned(msg.sender).sub(bptPaids[msg.sender]);
        if (reward > 0) {
            bptPaids[msg.sender] = bptPaids[msg.sender].add(reward);
            bpt.safeTransfer(msg.sender, reward);
            bptPaid = bptPaid.add(reward);
            emit RewardPaid(msg.sender, address(bpt), reward);
        }
    }

    // user add weth to bpt pool, get kani back
    function swapKani(uint256 wethAmount) public onlyOwner {
        weth.approve(address(bpt), wethAmount);
        uint256 wethBalance = bpt.getBalance(address(weth));
        uint256 kaniBalance = bpt.getBalance(address(kani));
        uint256 wethWeight = 49000000000000000000;
        uint256 kaniWeight = 1000000000000000000;
        uint256 swapFee = 2000000000000000;
        uint256 kaniOutAmount = bpt.calcOutGivenIn(wethBalance, wethWeight, kaniBalance, kaniWeight, wethAmount, swapFee);
        wethBalance = wethBalance.add(wethAmount);
        kaniBalance = kaniBalance.sub(kaniOutAmount);
        uint256 spotPrice = bpt.calcSpotPrice(wethBalance, wethWeight, kaniBalance, kaniWeight, swapFee);
        bpt.swapExactAmountIn(address(weth), wethAmount, address(kani), kaniOutAmount, spotPrice);
    }

    modifier checkStart(){
        require(block.timestamp > rewardStartTime,"not start");
        _;
    }

    function exitToken(address token, address payable account, uint256 amount) public onlyOwner {
        IERC20 t = IERC20(token);
        require(t.balanceOf(address(this)) >= amount, "balance not enough");
        t.safeTransfer(account, amount);
    }
}
