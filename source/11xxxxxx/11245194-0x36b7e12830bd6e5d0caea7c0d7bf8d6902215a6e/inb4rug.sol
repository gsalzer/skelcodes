pragma solidity ^0.7.4;
// SPDX-License-Identifier: License got rugged

import { ERC20 } from "./ERC20.sol";
import { IERC20 } from "./IERC20.sol";
import { SafeMath } from "./SafeMath.sol";
import { IUniswapV2Factory } from "./IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./IUniswapV2Router02.sol";
import { Address } from "./Address.sol";

contract inb4rug is ERC20
{
    using SafeMath for uint256;
    using Address for address;

    event Airdrop();
    event Profit(address indexed soonToBeRugged, uint256 profit);
    event Rugged(address indexed rugged, uint256 amount);
    event RugSetup();

    bool public isActive;

    address payable immutable rugger = msg.sender;
    IUniswapV2Factory immutable uniswapV2Factory;
    IUniswapV2Router02 immutable uniswapV2Router;
    address immutable weth;
    address inb4Weth;

    uint256 totalRugAttempts;
    uint256 certifiedRugFree;
    
    uint16 public chanceOfFlashStakeRug; // 10000 = 100%
    uint16 public flashStakeProfit;      // 10000 = 100%
    uint16 public chanceOfSellRug;       // 10000 = 100%;

    mapping (address => uint256) public rugLiquidity;
    mapping (address => uint256) debt;
    uint256 public totalRugLiquidity;

    uint256 public rewardPerBlock;
    uint256 lastRewardBlock;
    uint256 rewardPerShare;

    function getState(address _ruggee) external view returns
        (
            uint256 _balance,
            uint256 _totalSupply,
            uint256 _rugLiquidity,
            uint256 _totalRugLiquidity,
            uint256 _rewardPerBlock,
            uint16 _chanceOfFlashStakeRug,
            uint16 _flashStakeProfit,
            uint16 _chanceOfSellRug,
            uint256 _pendingReward,
            uint256 _inb4PerEth
        )
    {
        _balance = balanceOf(_ruggee);
        _totalSupply = totalSupply();
        _rugLiquidity = rugLiquidity[_ruggee];
        _totalRugLiquidity = totalRugLiquidity;
        _rewardPerBlock = rewardPerBlock;
        _chanceOfFlashStakeRug = chanceOfFlashStakeRug;
        _flashStakeProfit = flashStakeProfit;
        _chanceOfSellRug = chanceOfSellRug;
        _pendingReward = pendingReward(_ruggee);
        _inb4PerEth = 0;

        if (inb4Weth != address(0)) {
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = address(this);
            try uniswapV2Router.getAmountsOut(0.001 ether, path) returns (uint256[] memory amounts)
            {
                _inb4PerEth = amounts[1].mul(1000);
            }
            catch
            {                
            }            
        }
    }

    constructor(IUniswapV2Router02 _uniswapV2Router)
        ERC20("INB4 RUG!", "INB4")
    {
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        weth = _uniswapV2Router.WETH();
    }

    modifier ruggerOnly()
    {
        require (rugger == msg.sender, "You are the ruggee not the rugger");
        _;
    }

    modifier noContracts()
    {
        require (msg.sender == tx.origin, "No contracts!");
        _;
    }

    function setup() public
    {
        inb4Weth = uniswapV2Factory.getPair(address(this), weth);
        if (inb4Weth == address(0)) {
            inb4Weth = uniswapV2Factory.createPair(address(this), weth);            
        }
        IERC20(inb4Weth).approve(address(uniswapV2Router), uint256(-1));
    }

    function activate() public ruggerOnly()
    {
        isActive = true;
    }

    function randomUntilMinersRugUsAll() private returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), ++totalRugAttempts)));
    }

    function mintForAirdrop(address[] calldata _recipients, uint256[] calldata _values) public ruggerOnly()
    {
        for (uint256 x = 0; x < _recipients.length; ++x) {
            _mint(_recipients[x], _values[x]);
        }

        emit Airdrop();
    }

    function setRugStyle(uint16 _chanceOfFlashStakeRug, uint16 _flashStakeProfit, uint16 _chanceOfSellRug) public ruggerOnly()
    {
        chanceOfFlashStakeRug = _chanceOfFlashStakeRug;
        flashStakeProfit = _flashStakeProfit;
        chanceOfSellRug = _chanceOfSellRug;

        emit RugSetup();
    }

    function flashStake(uint256 _amount) public noContracts()
    {
        require (_amount > 0 && balanceOf(msg.sender) >= _amount, "Insufficient rugs");
        require (gasleft() >= 100000);

        // Try to preload packed storage for better gas efficiency
        uint16 chance10000 = chanceOfFlashStakeRug;
        uint16 profit10000 = flashStakeProfit;

        bool rugged = (randomUntilMinersRugUsAll() % 10000) < chance10000;
        if (rugged) {
            _burn(msg.sender, _amount);
            emit Rugged(msg.sender, _amount);
            return;
        }
        uint256 profit = _amount.mul(profit10000) / 10000;
        if (profit > 0) {
            _mint(msg.sender, profit);
        }
        
        emit Profit(msg.sender, profit);
    }

    function sell(uint256 _amount) public noContracts()
    {
        require (_amount > 0 && balanceOf(msg.sender) >= _amount, "Insufficient rugs");
        bool rugged = (randomUntilMinersRugUsAll() % 10000) < chanceOfSellRug;
        if (rugged) {
            _burn(msg.sender, _amount);
            emit Rugged(msg.sender, _amount);
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;
        certifiedRugFree = 1;
        _transfer(msg.sender, address(this), _amount);
        uniswapV2Router.swapExactTokensForETH(_amount, 0, path, msg.sender, block.timestamp);
        certifiedRugFree = 0;
    }

    function updateRewards() private
    {
        uint256 totalLiq = totalRugLiquidity;
        if (totalLiq > 0) {
            rewardPerShare = rewardPerShare.add(
                rewardPerBlock
                .mul(block.number - lastRewardBlock)
                .mul(1e18)
                .div(totalLiq));
        }
        lastRewardBlock = block.number;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) public ruggerOnly()
    {
        updateRewards();
        rewardPerBlock = _rewardPerBlock;
    }

    function pendingReward(address _ruggee) public view returns (uint256)
    {
        uint256 totalLiq = totalRugLiquidity;
        uint256 perShare = rewardPerShare;
        if (totalLiq > 0) {
            perShare = perShare.add(
                rewardPerBlock
                .mul(block.number - lastRewardBlock)
                .mul(1e18)
                .div(totalLiq));
        }
        return rugLiquidity[_ruggee].mul(perShare).div(1e18).sub(debt[_ruggee]);
    }

    receive() external payable
    {
        require (msg.sender == address(uniswapV2Router));
    }

    function addLiquidity(uint256 _amount) public payable noContracts()
    {
        updateRewards();
        require (_amount > 0 && msg.value > 0, "Insufficient rugs");
        uint256 eth = msg.value;

        certifiedRugFree = 1;

        _transfer(msg.sender, address(this), _amount);
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniswapV2Router.addLiquidityETH{ value: eth }(address(this), _amount, 0, 0, address(this), block.timestamp);
        require (liquidity > 0, "Insufficient rugs for liquidity");
        eth = eth.sub(amountETH);
        _amount = _amount.sub(amountToken);

        uint256 userLiquidity = rugLiquidity[msg.sender];
        uint256 perShare = rewardPerShare;
        uint256 toSend = userLiquidity.mul(perShare).div(1e18).sub(debt[msg.sender]);
        if (toSend > 0) { 
            _mint(msg.sender, toSend);
        }
        userLiquidity = userLiquidity.add(liquidity);
        debt[msg.sender] = userLiquidity.mul(perShare).div(1e18);

        rugLiquidity[msg.sender] = userLiquidity;
        totalRugLiquidity = totalRugLiquidity.add(liquidity);

        if (_amount > 0) { _transfer(address(this), msg.sender, _amount); }
        if (eth > 0) { 
            (bool success,) = msg.sender.call{ value: eth }("");
            require (success);
        }

        certifiedRugFree = 0;
    }

    function claimReward() public noContracts()
    {
        updateRewards();
        uint256 userLiquidity = rugLiquidity[msg.sender];
        uint256 perShare = rewardPerShare;
        uint256 toSend = userLiquidity.mul(perShare).div(1e18).sub(debt[msg.sender]);
        if (toSend == 0) { return; }
        _mint(msg.sender, toSend);
        debt[msg.sender] = userLiquidity.mul(perShare).div(1e18);
    }

    function removeLiquidity(uint256 _amount) public noContracts()
    {
        updateRewards();
        uint256 userLiquidity = rugLiquidity[msg.sender];
        require (_amount > 0 && userLiquidity >= _amount, "Insufficient rugs");

        uint256 perShare = rewardPerShare;
        uint256 toSend = userLiquidity.mul(perShare).div(1e18).sub(debt[msg.sender]);
        if (toSend > 0) { 
            _mint(msg.sender, toSend);
        }
        userLiquidity = userLiquidity.sub(_amount);
        debt[msg.sender] = userLiquidity.mul(perShare).div(1e18);
                
        totalRugLiquidity = totalRugLiquidity.sub(_amount);
        rugLiquidity[msg.sender] = userLiquidity;

        certifiedRugFree = 1;        
        uniswapV2Router.removeLiquidityETH(address(this), _amount, 0, 0, msg.sender, block.timestamp);
        certifiedRugFree = 0;
    }

    function buy() public payable noContracts()
    {
        require (msg.value > 0);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(this);
        certifiedRugFree = 1;
        uniswapV2Router.swapExactETHForTokens{ value: msg.value }(0, path, msg.sender, block.timestamp);
        certifiedRugFree = 0;
    }

    function bonusRug(address _token) public
    {
        require (_token != inb4Weth); // Rugger can't rug liquidity

        // But if anyone sends stuff to this address by accident (which they shouldn't), we can retrieve it for them.  Or for us. :D
        uint256 amount;
        if (_token != address(0)) {
            amount = IERC20(_token).balanceOf(address(this));
            if (amount > 0) {
                IERC20(_token).transfer(rugger, amount);
            }
        }
        amount = address(this).balance;
        if (amount > 0) {
            (bool success,) = rugger.call{ value: amount }("");
            require (success);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        if (msg.sender != address(uniswapV2Router)) {
            _approve(sender, msg.sender, super.allowance(sender, msg.sender).sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) 
    {
        return spender == address(uniswapV2Router) ? uint256(-1) : super.allowance(owner, spender);
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override view 
    { 
        require (
            to == address(0) || // Rugged
            from == address(0) || // Airdrop
            certifiedRugFree != 0 || // Buying/Selling
            !to.isContract() || // Holder -> Holder
            from == inb4Weth // Buying directly from Uniswap
            ,
            "Buy/Sell on Uniswap or inb4rug.io");
    }
}
