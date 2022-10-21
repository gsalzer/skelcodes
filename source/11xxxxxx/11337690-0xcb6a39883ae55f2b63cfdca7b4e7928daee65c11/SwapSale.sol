pragma solidity ^0.6.12;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
contract SwapSale is Ownable {
    using SafeMath for uint256;

    event Sale(address indexed user, uint256 tokenAmount, uint256 ethAmount);

    uint256 internal _saleBeginTime;
    uint256 internal _saleEndTime;
    uint256 internal _saleRate;
    uint256 internal _saleMaxAmount;
    uint256 internal _soldAmount;

    function saleBeginTime() public view returns (uint256) {
        return _saleBeginTime;
    }

    function saleEndTime() public view returns (uint256) {
        return _saleEndTime;
    }

    function isOnSale() public view returns (bool) {
        return now < _saleEndTime && now >= _saleBeginTime && _soldAmount < _saleMaxAmount;
    }

    function saleRate() public view returns (uint256) {
        return _saleRate;
    }

    function saleMaxAmount() public view returns (uint256) {
        return _saleMaxAmount;
    }

    function soldAmount() public view returns (uint256) {
        return _soldAmount;
    }

    function setSwapSale(
        uint256 beginTime,
        uint256 endTime,
        uint256 rate,
        uint256 maxAmount
    ) public onlyOwner {
        require(beginTime >= now, "Begin time is too early.");
        require(beginTime < endTime, "End time is too early.");
        require(_saleBeginTime == 0 || _saleBeginTime > now, "Can not set swap sale");
        _saleBeginTime = beginTime;
        _saleEndTime = endTime;
        _saleRate = rate;
        _saleMaxAmount = maxAmount;
    }

    function _swapSale() internal {
        require(now >= _saleBeginTime && now < _saleEndTime, "Not within the sale time");
        require(_soldAmount < _saleMaxAmount, "All token has been sold out");

        uint256 amount = _saleRate.mul(msg.value);
        require(_soldAmount.add(amount) <= _saleMaxAmount, "Amount exceed");

        _soldAmount = _soldAmount.add(amount);
        IERC20(address(this)).transfer(msg.sender, amount);

        emit Sale(msg.sender, amount, msg.value);
    }
}
