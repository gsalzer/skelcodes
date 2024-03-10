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
import "./ERC20Staking.sol";


contract NFTStaking is ReentrancyGuard, Ownable, ERC1155Holder {
    using EnumerableSet for EnumerableSet.UintSet;

    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amountETH, uint256 tokenID);
    event Withdrawn(address indexed to, uint256 amountETH, uint256 tokenID);
    event Claimed(address indexed to, uint256 amount);
    event Compounded(address indexed to, uint256 amount);

    event RoundReset();

    TheCannabisCommunity public token;
    uint256 public nftokenID;
    IERC1155 public nftoken;
    ERC20Staking public compounder;

    struct AccountInfo {
        // Staked LP token balance
        //all their NFTs
        uint256 balance;
        uint256 withdrawTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
    }
    mapping(address => AccountInfo) private accountInfos;

    // Staked NFT Total ValueLP token total supply
    uint256 private _totalValue = 0;

    uint256 public constant ROUND_DURATION = 365 days;
    uint256 public rewardAllocation = 7810 * 1e18;
    uint256 public resetTimestamp = 0;
    uint256 public lastUpdateTimestamp = 0;

    uint256 public rewardRate = 0;
    uint256 public rewardPerTokenStored = 0;

    // Farming will be open on this timestamp
    // Thu, 03 Dec 2020 12PM EST
    uint256 public farmingStartTimestamp = 1608141600;
    bool public farmingStarted = false;

    constructor(uint256 _id, address _nft) public {
        nftokenID = _id;
        nftoken = IERC1155(_nft);
        // Calc reward rate
        rewardRate = rewardAllocation.div(ROUND_DURATION);
    }

    function setMinted(address _token) external onlyOwner {
        require(address(token) == address(0), "Only Once");
        token = TheCannabisCommunity(_token);
    }

    function setCompounder(address _compounder) external onlyOwner {
        require(address(compounder) == address(0), "Only Once");
        compounder = ERC20Staking(_compounder);
    }

    function stake() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _reset();

        require(!address(msg.sender).isContract(), 'Please use your individual account');
        nftoken.safeTransferFrom(msg.sender, address(this), nftokenID, 1, "");

        uint256 _amount = 1 ether;
        _totalValue = _totalValue.add(_amount);
        // Add to balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.add(_amount);

        // Set stake timestamp as withdraw timestamp
        // to prevent withdraw immediately after first staking
        if (accountInfos[msg.sender].withdrawTimestamp == 0) {
            accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        }

        emit Staked(msg.sender, _amount, nftokenID);
    }

    function withdraw() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _reset();

        require(accountInfos[msg.sender].balance > 0, 'Cannot withdraw 0');

        //Get the NFT Value
        uint256 _amount = 1 ether;
        // Reduce totalValue
        _totalValue = _totalValue.sub(_amount);
        // Reduce balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.sub(_amount);
        // Set timestamp
        accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        
        nftoken.safeTransferFrom(address(this), msg.sender, nftokenID, 1, "");
        emit Withdrawn(msg.sender, _amount, nftokenID);
    }

    function claim() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _reset();

        uint256 reward = accountInfos[msg.sender].reward;
        require(reward > 0, 'There is no reward to claim');
        // Reduce first
        accountInfos[msg.sender].reward = 0;

        // Send reward
        token.mint(msg.sender, reward);
        emit Claimed(msg.sender, reward);

    }


    function compound(address _account) external nonReentrant {
        require(msg.sender == address(compounder), "Only compounder can compound.");
        _checkFarming();
        _updateReward(_account);
        _reset();

        uint256 reward = accountInfos[_account].reward;
        if (reward > 0) {
            // Reduce first
            accountInfos[_account].reward = 0;

            // Send reward

            token.mint(address(compounder), reward);
            compounder.stakeFor(_account, reward);
            emit Compounded(_account, reward);
        }
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
