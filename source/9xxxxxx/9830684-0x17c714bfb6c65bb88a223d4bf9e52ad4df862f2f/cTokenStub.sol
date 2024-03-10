pragma solidity ^0.4.24;
import "./SafeMath.sol";

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract cTokenStub {
    using SafeMath for uint256;

    uint256 public exchangeRateCurrent = 210074678802943;
    ERC20 public theToken;
    mapping(address => uint256) public balanceOf;

    constructor(address _theToken) {
        theToken = ERC20(_theToken);
    }

    function balanceOfUnderlying(address owner) public returns(uint256) {
        return balanceOf[owner].mul(exchangeRateCurrent).div(10**18);
    }

    function mint(uint256 theTokenAmount) public payable returns(uint256) {
        require(theToken.transferFrom(msg.sender, address(this), theTokenAmount));
        balanceOf[msg.sender] = theTokenAmount.mul(10**18).div(exchangeRateCurrent);
        return 0;
    }

    function redeem(uint256 cTokenAmount) public returns(uint256) {
        uint256 theTokenAmount = cTokenAmount.mul(exchangeRateCurrent).div(10**18);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(cTokenAmount);
        require(theToken.transfer(msg.sender, theTokenAmount));
        return 0;
    }
}

