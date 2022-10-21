pragma solidity ^0.5.1;

import "./IERC20.sol";
import "./SafeMath.sol";

contract TokenVault {
    using SafeMath for uint256;

    address private deployer;

    address private _beneficiary;

    uint256 private _finalUnlockTime;
    
    uint256 public lockedTokens = 0;
    
    struct Milestone {
        address tokenAddress;
        uint256 unlockableTokens;
        uint256 unlockTime;
        bool released;
    }
    uint256 public milestoneCount = 0;
    mapping (uint256 => Milestone) milestones;
    
    modifier onlyOwner() {
        require(deployer == msg.sender, "Caller is not the owner");
        _;
    }

    constructor (uint256 unlockTime) public {
        require(unlockTime > block.timestamp, "Release time cannot be before current time");
        deployer = msg.sender;
        _beneficiary = msg.sender; // Deployer is beneficiary by default
        _finalUnlockTime = unlockTime;
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        IERC20 _token = IERC20(_tokenAddress);
        return _token.balanceOf(address(this));
    }


    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function finalUnlockTime() public view returns (uint256) {
        return _finalUnlockTime;
    }
    
    
    function unlockable(uint256 _milestoneID) public view returns (bool) {
        require(_milestoneID > 0, "Invalid ID");
        require(_milestoneID <= milestoneCount, "Milestone doesn't exist");
        if(block.timestamp >= milestones[_milestoneID].unlockTime)
            return true;
        return false;
    }

    function createMilestone(address _tokenAddress, uint256 amount, uint256 unlockTime)  public onlyOwner returns (uint milestoneID) {
        require(unlockTime <= _finalUnlockTime, "Milestone can't be after final unlock");
        require(unlockTime >= block.timestamp, "Milestone cannot be in the past");
        IERC20 _token = IERC20(_tokenAddress);
        uint256 availableTokens = _token.balanceOf(address(this)).sub(lockedTokens);
        require(availableTokens >= amount, "Not enough tokens for Milestone");
        milestoneID = ++milestoneCount;
        lockedTokens = lockedTokens.add(amount);
        milestones[milestoneID] = Milestone(_tokenAddress, amount, unlockTime, false);
    }

    function extendMilestone(uint256 milestoneID, uint256 extension) public onlyOwner {
        require(milestoneID <= milestoneCount, "Milestone doesn't exist");
        require(milestoneID > 0, "Invalid ID");
        require(extension > 0, "Extension period must be positive");
        Milestone storage _milestone = milestones[milestoneID];
        require(_milestone.released == false, "Milestone is already released");
        uint256 newTime = _milestone.unlockTime.add(extension);
        require(newTime <= _finalUnlockTime, "Milestones must end before final unlock");
        _milestone.unlockTime = newTime;
        
    }


    function releaseMilestone(uint256 milestoneID) public {
        require(milestoneID <= milestoneCount, "Milestone doesn't exist");
        require(milestoneID > 0, "Invalid ID");
        Milestone storage _milestone = milestones[milestoneID];
        require(block.timestamp >= _milestone.unlockTime, "Milestone not unlocked");
        require(_milestone.released == false, "Milestone already released");
        IERC20 _token = IERC20(_milestone.tokenAddress);
        uint256 amount = _milestone.unlockableTokens;
        milestones[milestoneID].released = true;
        lockedTokens = lockedTokens.sub(amount);
        _token.transfer(_beneficiary, amount);
    }

    function milestoneTokenCount(uint256 milestoneID) public view returns (uint256) {
        require(milestoneID <= milestoneCount, "Milestone doesn't exist");
        require(milestoneID > 0, "Invalid ID");
        return milestones[milestoneID].unlockableTokens;
    }
    
    function milestoneUnlockTime(uint256 milestoneID) public view returns (uint256) {
        require(milestoneID <= milestoneCount, "Milestone doesn't exist");
        require(milestoneID > 0, "Invalid ID");
        return milestones[milestoneID].unlockTime;
    }
    
    function changeBeneficiary(address account) public onlyOwner {
        require(account!= address(0));
        _beneficiary = account;
    }
    
    function changeOwnership(address account) public onlyOwner {
        require(account!= address(0));
        deployer = account;
    }
    
    function extendLockup(uint256 extension) public onlyOwner {
        require(extension > 0, "Extension period must be positive");
        _finalUnlockTime = _finalUnlockTime.add(extension);
    }
    
    function changeFinalUnlockTime(uint256 newTime) public onlyOwner {
        require(newTime > _finalUnlockTime, "Lock period cannot be reduced");
        _finalUnlockTime = newTime;
    }

    function remainderTokens(address _tokenAddress) public view returns (uint256) {
        IERC20 _token = IERC20(_tokenAddress);
        uint256 totalBalance = _token.balanceOf(address(this));
        return totalBalance.sub(lockedTokens);
    }
    
    function releaseRemaining(address _tokenAddress) public {
        require(block.timestamp >= _finalUnlockTime, "Tokens not unlocked yet");
        IERC20 _token = IERC20(_tokenAddress);
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "No tokens to release");
        _token.transfer(_beneficiary, amount);
        
    }
}
