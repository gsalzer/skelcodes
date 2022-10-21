// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;









import "../scriptsV2/ERC20Ownable.sol";
import "../scriptsV2/IUniswapV2Router02.sol";
import "../scriptsV2/IERC20.sol";
import "../scriptsV2/IUniswapV2Factory.sol";
import "../scriptsV2/contextHelper.sol";
import "../scriptsV2/SafeMath.sol";


contract TAMAGOTCHI is IERC20,Context,ERC20Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private uniswapV2Router;
    
    
    mapping (address => uint256) private _ownAmt;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isBlackListed;
    mapping (address => uint) private _setCoolDown;
    mapping (address => bool) private _noFeeList;

    address payable private _taxWallet;
    address private uniswapV2Pair;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e13 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _maxTxAmount = _tTotal;
    uint256 private _tFeeTotal;
    uint256 private _taxFee1;
    uint256 private _taxFee2;
    
    
    bool private OpenTrades;
    bool private inSwap = false;
    bool private enableSwap = false;
    bool private coolDownEnabled = false;

    
    event MaxTxAmountUpdated(uint _maxTxAmount);
    
    modifier swapLock {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    
    
    
    /*
        TOKENS BASIC INFORMATION
        -------------------------
    **/
    
    /*
        TOKENS BASIC INFORMATION
        -------------------------
    **/
    string private constant _name = "TAMAGOTCHI";
    string private constant _symbol = "TAMAGOTCHI";
    uint8 private constant _decimal = 9;
    
    /*
        TOKENS CONSTRUCTOR
        ------------------
    **/
    
    //--------------------------------------------
    
    constructor () {
        _taxWallet = payable(0xeCDf73112EEDa071f330235309A58F7b54144313);
        _ownAmt[_msgSender()] = _rTotal;
        _noFeeList[owner()] = true;
        _noFeeList[address(this)] = true;
        _noFeeList[_taxWallet] = true;
        
        

        
        
        
        
        
        /*
            BLACK LIST OF BOTS
            ------------------
        **/
        
        blackList(0x91B305F0890Fd0534B66D8d479da6529C35A3eeC);
        
    
    
    
    
    
    
        /*
            BLACK LIST OF BOTS
            ------------------
        **/
        
        
        
        
        /*IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        //uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        enableSwap = true;
        coolDownEnabled = true;
        _maxTxAmount = 5e15 * 10**9;
        OpenTrades = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        */
        
        
        /*
            BLACK LIST OF BOTS
            ------------------
        **/
    
        /*
            BLACK LIST OF BOTS
            ------------------
        **/
        openTrading();
        emit Transfer(address(0), address(this), _tTotal);
    }
    
    
    
    
    
    
    
    
    
    
    
    
    receive() external payable {}
    
    
    
    
    
    
    
    
    
    
    function name() public pure returns (string memory) {
        return _name;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    function decimals() public pure returns (uint8) {
        return _decimal;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    function balanceOf(address account) public view override returns (uint256) {
        return tokenReflection(_ownAmt[account]);
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    
    
    
    
    
    
    
    
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function setCooldownEnabled(bool onoff) external onlyOwner() {
        coolDownEnabled = onoff;
    }
    

    
    
    
    
    
    
    
    
    
    
    
   function blackList(address _user) public onlyOwner {
        require(!_isBlackListed[_user], "user already blacklisted");
        _isBlackListed[_user] = true;
    }

    
    
    
    
    
    
    
    
    
    function removeFromBlacklist(address _user) public onlyOwner {
        require(_isBlackListed[_user], "user already whitelisted");
        _isBlackListed[_user] = false;
    }
    
    

    
    
    
    
    
    
    
    
    function tokenReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    
    
    
    
    
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
    
    
    
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _taxFee1 = 2;
        _taxFee2 = 8;
        if (from != owner() && to != owner()) {
            require(!_isBlackListed[to] && !_isBlackListed[from]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _noFeeList[to] && coolDownEnabled) {
                // Cooldown
                require(amount <= _maxTxAmount);
                require(_setCoolDown[to] < block.timestamp);
                _setCoolDown[to] = block.timestamp + (30 seconds);
            }
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _noFeeList[from]) {
                _taxFee1 = 2;
                _taxFee2 = 8;
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && enableSwap) {
                swapTokensForETH(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendTax(address(this).balance);
                }
            }
        }
        _tokenTransfer(from,to,amount);
    }
    
 
    
    
    
    
    function openTrading() public onlyOwner() {
        require(!OpenTrades,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        //uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        enableSwap = true;
        coolDownEnabled = true;
        _maxTxAmount = 1e13 * 10**9;
        OpenTrades = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    
    
    
    
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }
    
    
    
    
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
        _ownAmt[sender] = _ownAmt[sender].sub(rAmount);
        _ownAmt[recipient] = _ownAmt[recipient].add(rTransferAmount); 
        _takeTax(tTax);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    
    
    
    
    function sendTax(uint256 amount) private {
        _taxWallet.transfer(amount.div(2));
        _taxWallet.transfer(amount.div(2));
    }

    
    
    
    function swapTokensForETH(uint256 tokenAmount) private swapLock {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    
    
    
    
    function _takeTax(uint256 tTax) private {
        uint256 currentRate =  _getRate();
        uint256 rTax = tTax.mul(currentRate);
        _ownAmt[address(this)] = _ownAmt[address(this)].add(rTax);
    }
    
    
    
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    

    
    
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getTValues(tAmount, _taxFee1, _taxFee2);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTax, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTax);
    }
    
    
    
    
    
    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 liqTax) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTax = tAmount.mul(liqTax).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTax);
        return (tTransferAmount, tFee, tTax);
    }
    
    
    
    
    
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTax, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTax = tTax.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTax);
        return (rAmount, rTransferAmount, rFee);
    }
    

    
    
    
    
	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
   
    
    
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}
