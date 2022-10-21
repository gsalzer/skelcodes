pragma solidity <= 0.5.4;

import 'SafeMath.sol';
import 'SafeERC20.sol';
import 'Address.sol';
import 'Ownable.sol';
import 'IERC20.sol';

contract TristersLightMinterV2 is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    IERC20 public TLC;
    address public feeAddress;
    address[] public tokens;
    mapping (address => uint256) public stakes;

    mapping (address => uint256) private _tokens;
    mapping (address => mapping (address => uint256)) private _balances;
    mapping (address => mapping (address => uint256)) private _stakes;

    event Deposit(address indexed user, uint256 indexed tokenId, uint256 indexed amount, uint256 stake, uint256 gas, uint256 hashrate, uint256 orderId);
    event Withdraw(address indexed user, uint256 indexed tokenId, uint256 indexed amount, uint256 stake, uint256 gas, uint256 orderId);

    constructor(address tlcAddress) public {
        TLC = IERC20(tlcAddress);
        feeAddress = msg.sender;
    }

    function deposit(address tokenAddress, uint256 tokenId, uint256 amount, uint256 stake, uint256 gas, uint256 hashrate, uint256 orderId) public payable {
        require(amount > 0, "TristersLightMinterV2: amount must be greater than zero");
        require(stake > 0, "TristersLightMinterV2: stake must be greater than zero");
        require(msg.value >= gas, "TristersLightMinterV2: value must be greater than gas");

        if (tokenAddress == address(0)) {
            require(msg.value >= amount.add(gas), "TristersLightMinterV2: value must be greater than amoutn + gas");
        } else {
            require(_tokens[tokenAddress] > 0, "TristersLightMinterV2: token is not supported");
            require(tokenAddress.isContract(), "TristersLightMinterV2: tokenAddress is not contract");

            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        }
        
        TLC.safeTransferFrom(msg.sender, address(this), stake);
        if (gas > 0) feeAddress.toPayable().transfer(gas);

        stakes[msg.sender] = stakes[msg.sender].add(stake);
        _stakes[msg.sender][tokenAddress] = _stakes[msg.sender][tokenAddress].add(stake);
        _balances[msg.sender][tokenAddress] = _balances[msg.sender][tokenAddress].add(amount);

        emit Deposit(msg.sender, tokenId, amount, stake, gas, hashrate, orderId);
    }

    function withdraw(address tokenAddress, uint256 tokenId, uint256 amount, uint256 gas, uint256 orderId) public payable {
        require(amount > 0, "TristersLightMinterV2: amount must be greater than zero");
        require(msg.value >= gas, "TristersLightMinterV2: value must be greater than gas");

        uint256 balance = _balances[msg.sender][tokenAddress];
        require(balance >= amount, "TristersLightMinterV2: insufficient balance");
        _balances[msg.sender][tokenAddress] = _balances[msg.sender][tokenAddress].sub(amount);

        uint256 _stake = _stakes[msg.sender][tokenAddress];
        uint256 stake = _stake.mul(amount).div(balance);
        if (_stake < stake) stake = _stake;
        require(stake > 0, "TristersLightMinterV2: insufficient stake");
        stakes[msg.sender] = stakes[msg.sender].sub(stake);
        _stakes[msg.sender][tokenAddress] = _stakes[msg.sender][tokenAddress].sub(stake);

        if (tokenAddress == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(_tokens[tokenAddress] > 0, "TristersLightMinterV2: token is not supported");
            require(tokenAddress.isContract(), "TristersLightMinterV2: tokenAddress is not contract");

            IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        }
        
        TLC.safeTransfer(msg.sender, stake);
        if (gas > 0) feeAddress.toPayable().transfer(gas);

        emit Withdraw(msg.sender, tokenId, amount, stake, gas, orderId);
    }

    function getBalance(address user, address token) public view returns (uint256) {
        return _balances[user][token];
    }

    function addToken(address token) public onlyOwner {
        require(token != address(0), "TristersLightMinterV2: token the zero address");
        require(token.isContract(), "TristersLightMinterV2: token is not contract");
        if (_tokens[token] == 0) _tokens[token] = tokens.push(token);
    }

    function removeToken(address token) public onlyOwner {
        require(token != address(0), "TristersLightMinterV2: token the zero address");

        if (_tokens[token] == 0) return;
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance == 0, "TristersLightMinterV2: token balance must be equal to zero");

        delete tokens[_tokens[token].sub(1)];
        delete _tokens[token];
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "TristersLightMinterV2: new feeAddress the zero address");
        feeAddress = _feeAddress;
    }

    function() external payable {
        revert("TristersLightMinterV2: does not accept payments");
    }

}
