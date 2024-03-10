// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract CyOpProtocol is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) private bots;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100e12 * 10**9; //100 trillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public zeroFee; //0%
    uint256 public treasury1Fee = 4; //4%
    uint256 public treasury2Fee = 6; //6%
    uint256 public protocolFee = 10; //gowth hacking(4%) + protocol(6%)
    uint256 private prevProtocolFee; //gowth hacking(4%) + protocol(6%)
    address payable public treasury1; //4%
    address payable public treasury2; //6%
    
    string private constant _name = "CyOp | Protocol";
    string private constant _symbol = "CyOp";
    uint8 private constant _decimals = 9;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private inSwap;
    bool public sellingEnabled;
    
    uint256 public contractStartTime;
    uint256 public maxTxAmount = _tTotal;
    
    event MaxTxAmountUpdated(uint maxTxAmount);
    event SellingEnabled(bool enabled);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address _treasury1, address _treasury2) {
    	uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        treasury1 = payable(_treasury1);
        treasury2 = payable(_treasury2);
        contractStartTime = block.timestamp;
        _rOwned[_msgSender()] = _rTotal;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[treasury1] = true;
        isExcludedFromFee[treasury2] = true;
        emit Transfer(address(0x0000000000000000000000000000000000000000), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
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

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require (owner == Ownable.owner() || (sellingEnabled && block.timestamp > contractStartTime + 20 minutes), "Selling is disabled.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            require(amount <= maxTxAmount);

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && contractTokenBalance > 0) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToTreasury(contractETHBalance);
                }
            }
        }

        bool takeFee = true;

        //if any account belongs to isExcludedFromFee account then remove the fee
        if(isExcludedFromFee[from] || isExcludedFromFee[to]){
            takeFee = false;
        }

        if(!takeFee)
            removeAllFee();
		
        _tokenTransfer(from,to,amount);

        if(!takeFee)
            restoreAllFee();
    }

    function removeAllFee() private {
        if(protocolFee == 0) return;
        
        prevProtocolFee = protocolFee;
        protocolFee = 0;
    }

    function restoreAllFee() private {
        protocolFee = prevProtocolFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
        
    function sendETHToTreasury(uint256 amount) private {
        treasury1.transfer((amount.mul(treasury1Fee).mul(100).div(protocolFee)).div(100));
        treasury2.transfer((amount.mul(treasury2Fee).mul(100).div(protocolFee)).div(100));
    }

    function setFee(uint256 _treasury1Fee, uint256 _treasury2Fee) public onlyOwner {
        treasury1Fee = _treasury1Fee;
        treasury2Fee = _treasury2Fee;
        protocolFee = treasury1Fee + treasury2Fee;
    }

    function updateTreasury(address _treasury1, address _treasury2) public onlyOwner {
        treasury1 = payable(_treasury1);
        treasury2 = payable(_treasury2);
    }

    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    //in percentages
    function setMaxTxLimit(uint256 _maxPercent) public onlyOwner {
        maxTxAmount = (_tTotal * _maxPercent) / 100;
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function enableSelling(bool enabled) external onlyOwner {	
	    sellingEnabled = enabled;	
	    emit SellingEnabled(enabled);	
    }

    function setPairAddress(address _uniswapV2Pair) external onlyOwner {	
	    uniswapV2Pair = _uniswapV2Pair;	
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tProtocol) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeProtocol(tProtocol);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeProtocol(uint256 tProtocol) private {
        uint256 currentRate =  _getRate();
        uint256 rProtocol = tProtocol.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rProtocol);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function manualswapTreasury() external {
        require(_msgSender() == treasury1 || _msgSender() == treasury2);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
        manualsend();
    }
    
    function manualsend() internal {
        uint256 contractETHBalance = address(this).balance;
        sendETHToTreasury(contractETHBalance);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tProtocol) = _getTValues(tAmount, zeroFee, protocolFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tProtocol, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tProtocol);
    }

    function _getTValues(uint256 _tAmount, uint256 taxFee, uint256 _protocolFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = _tAmount.mul(taxFee).div(100);
        uint256 tProtocol = _tAmount.mul(_protocolFee).div(100);
        uint256 tTransferAmount = _tAmount.sub(tFee).sub(tProtocol);
        return (tTransferAmount, tFee, tProtocol);
    }

    function _getRValues(uint256 _tAmount, uint256 _tFee, uint256 _tProtocol, uint256 _currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = _tAmount.mul(_currentRate);
        uint256 rFee = _tFee.mul(_currentRate);
        uint256 rProtocol = _tProtocol.mul(_currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rProtocol);
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
