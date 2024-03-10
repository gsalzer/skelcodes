// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.9;

import "./SafeMath.sol";
import "./Ownable.sol";

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns(bool);
}

interface IValidator {
    function checkBalance(uint256 network, address tokenForeign, address user) external returns(uint256);
}

contract GatewayEth is Ownable {
    using SafeMath for uint256;

    uint256 public constant chain = 56;  // ETH mainnet = 1, Ropsten = 2, BSC_TESTNET = 97, BSC_MAINNET = 56
    
    IBEP20 public token;
    address public foreignGateway;
    string public name;

    uint256 public fee;
    uint256 public claimFee;
    address payable public validator;
    address public system;  // system address mey change fee amount

    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public balanceSwap;

    event Swap(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem() {
        require(msg.sender == system, "Caller is not the system");
        _;
    }

    constructor (address _token, string memory _name, address _system) public {
        token = IBEP20(_token);
        name = _name;
        system = _system;
    }

    function setFee(uint256 _fee) external onlySystem returns(bool) {
        fee = _fee;
        return true;
    }

    function setClaimFee(uint256 _fee) external onlySystem returns(bool) {
        claimFee = _fee;
        return true;
    }

    function setSystem(address _system) external onlyOwner returns(bool) {
        system = _system;
        return true;
    }

    function setValidator(address payable _validator) external onlyOwner returns(bool) {
        validator = _validator;
        return true;
    }

    function setForeignGateway(address _addr) external onlyOwner returns(bool) {
        foreignGateway = _addr;
        return true;
    }

    //user should approve tokens transfer before calling this function.
    function swapToken(uint256 amount) external payable returns (bool) {
        require(msg.value >= fee,"Insufficient fee");
        token.burnFrom(msg.sender, amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        validator.transfer(msg.value); // transfer fee to validator for Oracle payment
        emit Swap(msg.sender, amount);
    }

    function claimToken() external payable returns (bool) {
        require(msg.value >= claimFee,"Insufficient fee");
        validator.transfer(msg.value); // transfer fee to validator for Oracle payment
        IValidator(validator).checkBalance(chain, foreignGateway, msg.sender);
        return true;
    }

    function claimTokenBehalf(address user) external onlySystem returns (bool) {
        IValidator(validator).checkBalance(chain, foreignGateway, user);
        return true;
    }

    // On both side (BEP and ERC) we accumulate user's deposits (balance).
    // If balance on one side it greater then on other, the difference means user deposit.
    function validatorCallback(uint256 requestId, address tokenForeign, address user, uint256 balanceForeign) external returns(bool) {
        require (validator == msg.sender, "Not validator");
        require (tokenForeign == foreignGateway, "Wrong foreign token");
        uint256 balance = balanceSwap[user];    // our records of user balance
        require(balanceForeign > balance, "No BEP20 tokens deposit");
        balanceSwap[user] = balanceForeign; // update balance
        uint256 amount = balanceForeign - balance;
        token.mint(user, amount); // mint deposited amount
        emit Claim(user, amount);
        return true;
    }
}
