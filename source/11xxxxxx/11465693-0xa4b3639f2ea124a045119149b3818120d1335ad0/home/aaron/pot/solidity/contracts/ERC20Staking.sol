// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.8;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./TheCannabisCommunity.sol";
import "./CROPr.sol";
import "./NFTStaking.sol";

contract ERC20Staking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event Claimed(address indexed to, uint256 amount);
    event RoundReset();

    TheCannabisCommunity public token;
    CROPr public minted;
    NFTStaking nftStaking;

    struct AccountInfo {
        // Staked TCC token balance
        uint256 balance;
        uint256 withdrawTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
    }
    mapping(address => AccountInfo) private accountInfos;

    // Staked NFT Total ValueLP token total supply
    uint256 private _totalValue = 0;

    uint256 public constant ROUND_DURATION = 30 days;
    uint256 public rewardAllocation = 23760 * 1e18;
    uint256 public resetTimestamp = 0;
    uint256 public lastUpdateTimestamp = 0;

    uint256 public rewardRate = 0;
    uint256 public rewardPerTokenStored = 0;

    // Farming will be open on this timestamp
    // Thu, 03 Dec 2020 12PM EST
    uint256 public farmingStartTimestamp = 1608141600;
    bool public farmingStarted = false;
    bool public claimStarted = false;

    constructor(address _token) public {
        token = TheCannabisCommunity(_token);
        // Calc reward rate
        rewardRate = rewardAllocation.div(ROUND_DURATION);
    }

    function setMinted(address _minted) external onlyOwner {
        require(address(minted) == address(0), "Only Once");
        minted = CROPr(_minted);
    }

    function setNFTStaking(address _nftStaking) external onlyOwner {
        require(address(nftStaking) == address(0), "Only once");
        nftStaking = NFTStaking(_nftStaking);
    }

    function toggleClaim() external onlyOwner {
        claimStarted = !claimStarted;
    }

    function stake(uint256 _amount) external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);


        require(!address(msg.sender).isContract(), 'Please use your individual account');
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _totalValue = _totalValue.add(_amount);

        // Add to balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.add(_amount);

        // Set stake timestamp as withdraw timestamp
        // to prevent withdraw immediately after first staking
        if (accountInfos[msg.sender].withdrawTimestamp == 0) {
            accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        }

        emit Staked(msg.sender, _amount);
    }

    function stakeFor(address _account, uint256 _amount) external {
        _checkFarming();
        _updateReward(msg.sender);

        require(msg.sender == address(nftStaking), 'Only nftStaking can stakeFor');
        //Tokens are minted directly to the contract.
        _totalValue = _totalValue.add(_amount);

        // Add to balance
        accountInfos[_account].balance = accountInfos[_account].balance.add(_amount);

        // Set stake timestamp as withdraw timestamp
        // to prevent withdraw immediately after first staking
        if (accountInfos[_account].withdrawTimestamp == 0) {
            accountInfos[_account].withdrawTimestamp = block.timestamp;
        }

        emit Staked(_account, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        require(accountInfos[msg.sender].balance > 0, 'Cannot withdraw 0');
        require(_amount <= accountInfos[msg.sender].balance, "INSUFFICENT BALANCE");

        if(_amount == 0) _amount = accountInfos[msg.sender].balance;
        // Reduce totalValue
        _totalValue = _totalValue.sub(_amount);
        // Reduce balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.sub(_amount);
        // Set timestamp
        accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        
        IERC20(token).safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function claim() public nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);

        uint256 reward = accountInfos[msg.sender].reward;
        if(!claimStarted) reward = 0;

        if (reward > 0) {
            // Reduce first
            accountInfos[msg.sender].reward = 0;

            // Send reward
            minted.mint(msg.sender, reward);
            emit Claimed(msg.sender, reward);
        }
    }

    function claimAndCompound() external {
        claim();
        nftStaking.compound(msg.sender);
    }
        
    function totalValue() external view returns (uint256) {
        return _totalValue;
    }

    function balanceOf(address account) external view returns (uint256) {
        return accountInfos[account].balance;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalValue == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored
        .add(
            lastRewardTimestamp()
            .sub(lastUpdateTimestamp)
            .mul(rewardRate) //rate per second
            .mul(1e18)
            .div(_totalValue)
        );
    }

    function lastRewardTimestamp() public view returns (uint256) {
        return Math.min(block.timestamp, resetTimestamp);
    }

    function rewardEarned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            rewardPerToken().sub(accountInfos[account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].reward);
    }

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTimestamp = lastRewardTimestamp();
        if (account != address(0)) {
            accountInfos[account].reward = rewardEarned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    // Announce Round Reset
    function _reset() internal {
        if (block.timestamp >= resetTimestamp) {
            rewardAllocation = 0;
            _updateReward(msg.sender);
            emit RoundReset();
        }
    }

    // Check if farming is started
    function _checkFarming() internal {
        require(farmingStartTimestamp <= block.timestamp, 'Please wait until farming started');
        if (!farmingStarted) {
            farmingStarted = true;
            resetTimestamp = block.timestamp.add(ROUND_DURATION);
            lastUpdateTimestamp = block.timestamp;
        }
    }
}
