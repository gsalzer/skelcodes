//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./Ownable.sol";

contract Mona__Token is IERC20, Context, Ownable {
    
    using SafeMath for uint;
    using Address for address;
 
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    
    uint public _totalSupply             = 70000 ether;
    uint256 public presaleTokens         = 27500 ether;
    uint256 public poolMoliMoliTokens    = 10000 ether;
    uint256 public poolMoliEthTokens     = 22000 ether;
    uint256 public poolWBTCTokens         = 1500 ether;
    uint256 public poolWETHTokens         = 1500 ether;
    uint256 public devMaxSuply            = 7500 ether;
    uint256 public devDailyFund             = 25 ether;
    
    uint256 public TokenListedTime;
    uint256 public lastDevGetFounds         = 0;
    uint256 public devGetFundsTimelock      = 1 days;
    
    address public presaleAccount;
    address public poolAccountMoliMoli;
    address public poolAccountMoliEth;
    address public poolAccountWBTC;
    address public poolAccountWETH;
    
    address public _uniswapAddress;
    
    bool public txispaused = true;

    mapping(address => uint) _balances;
    mapping (address => bool) public _whitelistedAddress;
    mapping (address => bool) public _farmingAddress;
    
    mapping(address => mapping(address => uint)) _allowances;
    
    constructor() {
        _symbol = "MOLI";
        _name = "mona.finance";
        _decimals = 18;
        
        _whitelistedAddress[ address(0) ] = true;
        _whitelistedAddress[ address(this) ] = true;
        _whitelistedAddress[ _owner ] = true;
        
        TokenListedTime = block.timestamp;
        
        lastDevGetFounds = block.timestamp.add( devGetFundsTimelock );
        devMaxSuply = devMaxSuply.sub( devDailyFund ); 
        _balances[_owner] = devDailyFund;
        
        emit Transfer(address(0), _owner, devDailyFund);
    }

    receive() external payable {
        revert();
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function burn(uint amount) public {
        require(amount > 0);
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, txBurn( amount, _msgSender(), recipient ) );
        return true;
    }

    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, txBurn( amount, sender, recipient ));
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public  onlyOwner{
        IERC20(tokenAddress).transfer(_owner, tokenAmount);
    }

    function registerPresale( address _presaleAccount ) public onlyOwner returns (bool) {
        require( presaleAccount == address(0), "registerPresale: has already been done");
        
        presaleAccount = _presaleAccount; 
        _balances[presaleAccount] = presaleTokens;
        
        emit Transfer(address(0), presaleAccount, presaleTokens);
        
        return true;
    }
    
    function registerPoolMoliMoli( address _poolAccount ) public onlyOwner returns (bool) {
        require( poolAccountMoliMoli == address(0), "registerPoolMoliMoli: has already been done");

        poolAccountMoliMoli = _poolAccount; 
        _balances[ _poolAccount ] = poolMoliMoliTokens;
        _farmingAddress[ _poolAccount ] = true;
        
        emit Transfer(address(0), _poolAccount, poolMoliMoliTokens);
        
        return true;
    }
    function registerPoolMoliEth( address _poolAccount ) public onlyOwner returns (bool) {
        require( poolAccountMoliEth == address(0), "registerPoolMoliEth: has already been done");
        
        poolAccountMoliEth = _poolAccount; 
        _balances[ _poolAccount ] = poolMoliEthTokens;
        _farmingAddress[ _poolAccount ] = true;
        
        emit Transfer(address(0), _poolAccount, poolMoliEthTokens);
        
        return true;
    }
    function registerPoolWBTC( address _poolAccount ) public onlyOwner returns (bool) {
        require( poolAccountWBTC == address(0), "registerPoolWBTC: has already been done");
        
        poolAccountWBTC = _poolAccount; 
        _balances[ _poolAccount ] = poolWBTCTokens;
        _farmingAddress[ _poolAccount ] = true;
        
        emit Transfer(address(0), _poolAccount, poolWBTCTokens);
        
        return true;
    }
    function registerPoolWETH( address _poolAccount ) public onlyOwner returns (bool) {
        require( poolAccountWETH == address(0), "registerPoolMoliEth: has already been done");
        
        poolAccountWETH = _poolAccount; 
        _balances[ _poolAccount ] = poolWETHTokens;
        _farmingAddress[ _poolAccount ] = true;
        
        emit Transfer(address(0), _poolAccount, poolWETHTokens);
        
        return true;
    }
    function registerUniswapPairAddress( address _account ) public onlyOwner returns (bool) { 
        _uniswapAddress = _account; 
        return true;
    }
    
    // FEATURE #1
    function getDevFunds() public onlyOwner returns (bool) {
        
        require(devMaxSuply > 0, 'dev funds is empty');
 
        uint256 sinceLastGetFunds = block.timestamp.add( 1 ).sub( lastDevGetFounds.add( 1 ) );
        uint256 daysCount = sinceLastGetFunds.div( devGetFundsTimelock );
        if(daysCount > 0){
            
            uint256 devAmount = devDailyFund.mul( daysCount );
            
            lastDevGetFounds = lastDevGetFounds.add( daysCount.mul( devGetFundsTimelock ) );
            devMaxSuply = devMaxSuply.sub( devAmount ); 
            
            _balances[ _owner ] = _balances[_owner].add( devAmount );
            
            emit Transfer(address(0), _owner, devAmount);
            
            return true;
        
        }
        
        return false;
        
    }
    
    // FEATURE #9
    function addToWhitelist(address account) public onlyOwner returns (bool) { 
        _whitelistedAddress[ account ] = true;
        return true;
    }
    
    // FEATURE #9
    function removeFromWhitelist(address account) public onlyOwner returns (bool) { 
        _whitelistedAddress[ account ] = false;
        return true;
    }

    // FEATURE #5
    function pauseToken() public onlyOwner returns (bool) { 
        txispaused = true;
    }
    
    // FEATURE #5
    function unPauseToken() public onlyOwner returns (bool) { 
        txispaused = false;
    }
    
    // FEATURE #7, #8
    function txBurn( uint256 _amount, address _from, address _to ) internal returns (uint256) {
        
        if ( _whitelistedAddress[ _from ] ){
            return _amount;
        }
        if ( _whitelistedAddress[ _to ] ){
            return _amount;
        }
        if( presaleAccount == _from ){
            return _amount;
        }
        if( _farmingAddress[ _to ] ){
            return _amount;
        }
        if ( txispaused ) {
            revert("token is paused");
        }
        
        uint256 burnAmount = 0;
        if( _farmingAddress[ _from ] ){
            
            uint256 sinceLaunch = block.timestamp.add( 1 ).sub( TokenListedTime.add( 1 ) );
            uint256 burnPercentage = 10;
            
                 if(sinceLaunch > 12 days){ burnPercentage = 10; }
            else if(sinceLaunch > 11 days){ burnPercentage = 11; }
            else if(sinceLaunch > 10 days){ burnPercentage = 12; }
            else if(sinceLaunch >  9 days){ burnPercentage = 13; }
            else if(sinceLaunch >  8 days){ burnPercentage = 14; }
            else if(sinceLaunch >  7 days){ burnPercentage = 15; }
            else if(sinceLaunch >  6 days){ burnPercentage = 16; }
            else if(sinceLaunch >  5 days){ burnPercentage = 17; }
            else if(sinceLaunch >  4 days){ burnPercentage = 18; }
            else if(sinceLaunch >  3 days){ burnPercentage = 19; }
            else {                          burnPercentage = 20; }
            
            
            burnAmount = _amount.mul( burnPercentage ).div( 100 );
            
        }else if( _to == _uniswapAddress ){ 
            
            uint256 sinceLaunch = block.timestamp.add( 1 ).sub( TokenListedTime.add( 1 ) );
            uint256 burnPercentage = 3;
            
                 if(sinceLaunch > 9 days){ burnPercentage =  3; }
            else if(sinceLaunch > 8 days){ burnPercentage =  4; }
            else if(sinceLaunch > 7 days){ burnPercentage =  5; }
            else if(sinceLaunch > 6 days){ burnPercentage =  6; }
            else if(sinceLaunch > 5 days){ burnPercentage =  7; }
            else if(sinceLaunch > 4 days){ burnPercentage =  8; }
            else if(sinceLaunch > 3 days){ burnPercentage =  9; }
            else {                         burnPercentage = 10; }
             
             
            burnAmount = _amount.mul( burnPercentage ).div( 100 );
            
        }else{
            return _amount;
        }
        
        if( burnAmount > 0){
            _burn( _from, burnAmount);
        }
        
        return _amount.sub( burnAmount );
        
    }
}

