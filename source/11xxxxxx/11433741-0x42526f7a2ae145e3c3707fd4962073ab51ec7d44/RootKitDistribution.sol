// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./IRootKitDistribution.sol";
import "./Owned.sol";
import "./RootKit.sol";
import "./RootKitTransferGate.sol";
import "./TokensRecoverable.sol";
import "./SafeMath.sol";
import "./KETH.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IWrappedERC20.sol";

/*
Phases:
    Initializing
        Call setupKethRootKit() and setupWbtcRootKit()
        Call completeSetup()
        
    Call distribute() to:
        Transfer all RootKit to this contract
        Take all ETH + RootKit and create a market
        Play jenga
        Buy RootKit
        Buy wBTC
        Create RootKit/wBTC market
        Buy RootKit for the group
        Distribute funds

    Complete
        Everyone can call claim() to receive their tokens (via the liquidity generation contract)
*/

contract RootKitDistribution is TokensRecoverable, IRootKitDistribution
{
    using SafeMath for uint256;

    bool public override distributionComplete;

    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    RootKit immutable rootKit;
    KETH immutable keth;
    IERC20 immutable weth;
    IERC20 immutable wbtc;
    address immutable vault;

    IUniswapV2Pair kethRootKit;
    IUniswapV2Pair wbtcRootKit;
    IWrappedERC20 wrappedKethRootKit;
    IWrappedERC20 wrappedWbtcRootKit;

    uint256 public totalEthCollected;
    uint256 public totalRootKitBought;
    uint256 public totalWbtcRootKit;
    uint256 public totalKethRootKit;
    address rootKitLiquidityGeneration;
    uint256 recoveryDate = block.timestamp + 2592000; // 1 Month

    uint8 public jengaCount;
    
    // 10000 = 100%
    uint16 constant public vaultPercent = 2500; // Proportionate amount used to seed the vault
    uint16 constant public buyPercent = 2500; // Proportionate amount used to group buy RootKit for distribution to participants
    uint16 constant public wbtcPercent = 2500; // Proportionate amount used to create wBTC/RootKit pool

    constructor(RootKit _rootKit, IUniswapV2Router02 _uniswapV2Router, KETH _keth, IERC20 _wbtc, address _vault)
    {
        require (address(_rootKit) != address(0));
        require (address(_wbtc) != address(0));
        require (address(_vault) != address(0));

        rootKit = _rootKit;
        uniswapV2Router = _uniswapV2Router;
        keth = _keth;
        wbtc = _wbtc;
        vault = _vault;

        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        weth = _keth.wrappedToken();
    }

    function setupKethRootKit() public
    {
        kethRootKit = IUniswapV2Pair(uniswapV2Factory.getPair(address(keth), address(rootKit)));
        if (address(kethRootKit) == address(0)) {
            kethRootKit = IUniswapV2Pair(uniswapV2Factory.createPair(address(keth), address(rootKit)));
            require (address(kethRootKit) != address(0));
        }
    }
    function setupWbtcRootKit() public
    {
        wbtcRootKit = IUniswapV2Pair(uniswapV2Factory.getPair(address(wbtc), address(rootKit)));
        if (address(wbtcRootKit) == address(0)) {
            wbtcRootKit = IUniswapV2Pair(uniswapV2Factory.createPair(address(wbtc), address(rootKit)));
            require (address(wbtcRootKit) != address(0));
        }
    }
    function completeSetup(IWrappedERC20 _wrappedKethRootKit, IWrappedERC20 _wrappedWbtcRootKit) public ownerOnly()
    {        
        require (address(_wrappedKethRootKit.wrappedToken()) == address(kethRootKit), "Wrong LP Wrapper");
        require (address(_wrappedWbtcRootKit.wrappedToken()) == address(wbtcRootKit), "Wrong LP Wrapper");
        wrappedKethRootKit = _wrappedKethRootKit;
        wrappedWbtcRootKit = _wrappedWbtcRootKit;
        keth.approve(address(uniswapV2Router), uint256(-1));
        rootKit.approve(address(uniswapV2Router), uint256(-1));
        weth.approve(address(keth), uint256(-1));
        weth.approve(address(uniswapV2Router), uint256(-1));
        wbtc.approve(address(uniswapV2Router), uint256(-1));
        kethRootKit.approve(address(wrappedKethRootKit), uint256(-1));
        wbtcRootKit.approve(address(wrappedWbtcRootKit), uint256(-1));
    }

    function setJengaCount(uint8 _jengaCount) public ownerOnly()
    {
        jengaCount = _jengaCount;
    }

    function distribute() public override payable
    {
        require (!distributionComplete, "Distribution complete");
        uint256 totalEth = msg.value;
        require (totalEth > 0, "Nothing to distribute");
        distributionComplete = true;
        totalEthCollected = totalEth;
        rootKitLiquidityGeneration = msg.sender;

        rootKit.transferFrom(msg.sender, address(this), rootKit.totalSupply());
        
        RootKitTransferGate gate = RootKitTransferGate(address(rootKit.transferGate()));
        gate.setUnrestricted(true);

        createKethRootKitLiquidity(totalEth);

        jenga(jengaCount);

        sweepFloorToWeth();
        uint256 wethBalance = weth.balanceOf(address(this));

        createWbtcRootKitLiquidity(wethBalance * wbtcPercent / 10000);
        preBuyForGroup(wethBalance * buyPercent / 10000);

        sweepFloorToWeth();
        weth.transfer(vault, wethBalance * vaultPercent / 10000);
        weth.transfer(owner, weth.balanceOf(address(this)));
        kethRootKit.transfer(owner, kethRootKit.balanceOf(address(this)));

        gate.setUnrestricted(false);
    }

    function sweepFloorToWeth() private
    {
        keth.sweepFloor(address(this));
        keth.withdrawTokens(keth.balanceOf(address(this)));
    }
    function createKethRootKitLiquidity(uint256 totalEth) private
    {
        // Create KETH/ROOT LP 
        keth.deposit{ value: totalEth }();
        (,,totalKethRootKit) = uniswapV2Router.addLiquidity(address(keth), address(rootKit), keth.balanceOf(address(this)), rootKit.totalSupply(), 0, 0, address(this), block.timestamp);
        
        // Wrap the KETH/ROOT LP for distribution
        wrappedKethRootKit.depositTokens(totalKethRootKit);  
    }
    function createWbtcRootKitLiquidity(uint256 wethAmount) private
    {
        // Buy ROOT with 1/2 of the funds
        address[] memory path = new address[](2);
        path[0] = address(keth);
        path[1] = address(rootKit);
        keth.depositTokens(wethAmount / 2);
        uint256[] memory amountsRootKit = uniswapV2Router.swapExactTokensForTokens(wethAmount / 2, 0, path, address(this), block.timestamp);

        // Buy WBTC with the other 1/2 of the funds
        path[0] = address(weth);
        path[1] = address(wbtc);
        uint256[] memory amountsWbtc = uniswapV2Router.swapExactTokensForTokens(wethAmount / 2, 0, path, address(this), block.timestamp);
        (,,totalWbtcRootKit) = uniswapV2Router.addLiquidity(address(wbtc), address(rootKit), amountsWbtc[1], amountsRootKit[1], 0, 0, address(this), block.timestamp);

        // Wrap the WBTC/ROOT LP for distribution        
        wrappedWbtcRootKit.depositTokens(totalWbtcRootKit);
    }
    function preBuyForGroup(uint256 wethAmount) private
    {      
        address[] memory path = new address[](2);
        path[0] = address(keth);
        path[1] = address(rootKit);
        keth.depositTokens(wethAmount);
        uint256[] memory amountsRootKit = uniswapV2Router.swapExactTokensForTokens(wethAmount, 0, path, address(this), block.timestamp);
        totalRootKitBought = amountsRootKit[1];
    }
    
    function jenga(uint8 count) private
    {
        address[] memory path = new address[](2);
        path[0] = address(keth);
        path[1] = address(rootKit);
        for (uint x=0; x<count; ++x) {
            keth.depositTokens(keth.sweepFloor(address(this)));
            uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(keth.balanceOf(address(this)) * 2 / 5, 0, path, address(this), block.timestamp);
            keth.depositTokens(keth.sweepFloor(address(this)));
            uniswapV2Router.addLiquidity(address(keth), address(rootKit), keth.balanceOf(address(this)), amounts[1], 0, 0, address(this), block.timestamp);
        }
    }

    function claim(address _to, uint256 _contribution) public override
    {
        require (msg.sender == rootKitLiquidityGeneration, "Unauthorized");
        uint256 totalEth = totalEthCollected;

        // Send KETH/ROOT liquidity tokens
        uint256 share = _contribution.mul(totalKethRootKit) / totalEth;        
        if (share > wrappedKethRootKit.balanceOf(address(this))) {
            share = wrappedKethRootKit.balanceOf(address(this)); // Should never happen, but just being safe.
        }
        wrappedKethRootKit.transfer(_to, share);

        // Send WBTC/ROOT liquidity tokens
        share = _contribution.mul(totalWbtcRootKit) / totalEth;        
        if (share > wrappedWbtcRootKit.balanceOf(address(this))) {
            share = wrappedWbtcRootKit.balanceOf(address(this)); // Should never happen, but just being safe.
        }
        wrappedWbtcRootKit.transfer(_to, share);

        // Send RootKit
        RootKitTransferGate gate = RootKitTransferGate(address(rootKit.transferGate()));
        gate.setUnrestricted(true);

        share = _contribution.mul(totalRootKitBought) / totalEth;
        if (share > rootKit.balanceOf(address(this))) {
            share = rootKit.balanceOf(address(this)); // Should never happen, but just being safe.
        }
        rootKit.transfer(_to, share);

        gate.setUnrestricted(false);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) { 
        return 
            block.timestamp > recoveryDate ||
            (
                token != rootKit && 
                address(token) != address(wrappedKethRootKit) && 
                address(token) != address(wrappedWbtcRootKit)
            );
    }
}
