pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./BlackholePrevention.sol";

contract DTOVesting is Initializable, Ownable, BlackholePrevention {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct VestingInfo {
        bool isPrivateA;
        uint256 releasedAmount;
        uint256 totalAmount;
    }

    IERC20 public token;
    mapping(address => VestingInfo[]) public vestings;
    uint256 public startVestingTime;
    uint256 public PRIVATE_A_DURATION = 15 * 30.5 days;
    uint256 public PRIVATE_B_DURATION = 8 * 30.5 days;

    event Lock(address user, uint256 amount, bool isPrivateA);
    event Unlock(address user, uint256 amount);

    function initialize(address _token, uint256 _startVestingTime)
        public
        initializer
    {
        token = IERC20(_token);
        startVestingTime = _startVestingTime == 0
            ? block.timestamp
            : _startVestingTime;
    }

    function addVesting(
        address[] memory _addrs,
        uint256[] memory _amounts,
        bool _isPrivateA
    ) external onlyOwner {
        require(_addrs.length == _amounts.length, "Invalid input length");
        for (uint256 i = 0; i < _addrs.length; i++) {
            vestings[_addrs[i]].push(
                VestingInfo({
                    isPrivateA: _isPrivateA,
                    releasedAmount: 0,
                    totalAmount: _amounts[i]
                })
            );
            emit Lock(_addrs[i], _amounts[i], _isPrivateA);
        }
    }

    function unlock(address _addr) public {
        require(startVestingTime < block.timestamp, "not claimable yet");
        uint256 l = vestings[_addr].length;
        for (uint256 i = 0; i < l; i++) {
            uint256 unlockable = getUnlockableVesting(_addr, i);
            if (unlockable > 0) {
                vestings[_addr][i].releasedAmount = vestings[_addr][i]
                    .releasedAmount
                    .add(unlockable);
                token.safeTransfer(_addr, unlockable);
                emit Unlock(_addr, unlockable);
            }
        }
    }

    function getUnlockable(address _addr) public view returns (uint256) {
        uint256 ret = 0;
        uint256 l = vestings[_addr].length;
        for (uint256 i = 0; i < l; i++) {
            ret = ret.add(getUnlockableVesting(_addr, i));
        }
        return ret;
    }

    function getUnlockableVesting(address _addr, uint256 _index)
        public
        view
        returns (uint256)
    {
        if (_index >= vestings[_addr].length) return 0;
        VestingInfo memory vesting = vestings[_addr][_index];
        if (vesting.totalAmount == 0) {
            return 0;
        }

        if (startVestingTime > block.timestamp) return 0;

        uint256 period = getVestingDuration(vesting.isPrivateA);
        uint256 timeElapsed = block.timestamp.sub(startVestingTime);

        uint256 releasable = timeElapsed.mul(vesting.totalAmount).div(period);
        if (releasable > vesting.totalAmount) {
            releasable = vesting.totalAmount;
        }
        return releasable.sub(vesting.releasedAmount);
    }

    function getLockedInfo(address _addr)
        external
        view
        returns (uint256 _locked, uint256 _releasable)
    {
        _releasable = getUnlockable(_addr);
        uint256 remainLocked = 0;
        uint256 l = vestings[_addr].length;
        for (uint256 i = 0; i < l; i++) {
            remainLocked = remainLocked.add(
                vestings[_addr][i].totalAmount -
                    vestings[_addr][i].releasedAmount
            );
        }
        _locked = remainLocked.sub(_releasable);
    }

    function getVestingDuration(bool isPrivateA)
        internal
        view
        returns (uint256)
    {
        return isPrivateA ? PRIVATE_A_DURATION : PRIVATE_B_DURATION;
    }

    function revoke(address payable _to) external onlyOwner {
        withdrawERC20(_to, address(token), token.balanceOf(address(this)));
    }

    function setVestingDuration(uint256 _a, uint256 _b) external onlyOwner {
        PRIVATE_A_DURATION = _a;
        PRIVATE_B_DURATION = _b;
    }

    function withdrawEther(address payable receiver, uint256 amount)
        external
        virtual
        onlyOwner
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) public virtual onlyOwner {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) external virtual onlyOwner {
        _withdrawERC721(receiver, tokenAddress, tokenId);
    }
}

