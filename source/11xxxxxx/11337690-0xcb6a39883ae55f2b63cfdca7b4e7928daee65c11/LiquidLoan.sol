pragma solidity ^0.6.12;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract LiquidLoan is Ownable {
    using SafeMath for uint256;

    event Borrow(address indexed user, uint256 lptAmount, uint256 ethAmount);
    event Repay(address indexed user, uint256 tokenAmount, uint256 ethAmount);

    address internal _lpToken;
    uint256 internal _loanRate; // = eth/(10000 * lpt)
    mapping(address => uint256) internal _loanLpt;
    mapping(address => uint256) internal _loanEth;

    function lpToken() public view returns (address) {
        return _lpToken;
    }

    function loanRate() public view returns (uint256) {
        return _loanRate;
    }

    function userLoanLpt(address user) public view returns (uint256) {
        return _loanLpt[user];
    }

    function userLoanEth(address user) public view returns (uint256) {
        return _loanEth[user];
    }

    function setLpToken(address lp) public onlyOwner {
        // require(lp != address(0), "zero address is not allowed.");
        _lpToken = lp;
    }

    function setLoanRate(uint256 rate) public onlyOwner {
        _loanRate = rate;
    }

    function _borrowAll(address payable user) internal {
        require(_lpToken != address(0) && _loanRate != 0, "Loan is not ready");
        _borrow(user, IERC20(_lpToken).balanceOf(user));
    }

    function _borrow(address payable user, uint256 lptAmount) internal {
        require(_lpToken != address(0) && _loanRate != 0, "Loan is not ready");
        require(lptAmount > 0, "Can not borrow with 0");
        require(IERC20(_lpToken).transferFrom(user, address(this), lptAmount), "transferFrom failed");
        uint256 ethAmount = lptAmount.mul(_loanRate).div(10000);
        require(ethAmount > 0, "Borrow too little");
        require(ethAmount <= address(this).balance, "Eth pool is not enough");
        _loanEth[user] = _loanEth[user].add(ethAmount);
        _loanLpt[user] = _loanLpt[user].add(lptAmount);
        user.transfer(ethAmount);
        emit Borrow(user, lptAmount, ethAmount);
    }

    function repay(address payable user) internal {
        require(_lpToken != address(0), "Loan is not ready");
        uint256 ethLoan = _loanEth[user];
        require(ethLoan > 0, "No eth to repay");
        uint256 ethAmount = msg.value;
        if (ethAmount > ethLoan) {
            ethAmount = ethLoan;
        }
        uint256 lptAmount = _loanLpt[user].mul(ethAmount).div(ethLoan);
        _loanLpt[user] = _loanLpt[user].sub(lptAmount);
        _loanEth[user] = _loanEth[user].sub(ethAmount);
        IERC20(_lpToken).transfer(user, lptAmount);
        if (msg.value > ethAmount) {
            user.transfer(msg.value.sub(ethAmount));
        }
        emit Repay(user, lptAmount, ethAmount);
    }
}
