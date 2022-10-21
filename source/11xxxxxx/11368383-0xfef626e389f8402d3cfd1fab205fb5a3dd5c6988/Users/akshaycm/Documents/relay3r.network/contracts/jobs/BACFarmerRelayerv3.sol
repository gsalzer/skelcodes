// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import "../libraries/TransferHelper.sol";
import '../interfaces/Keep3r/IKeep3rV1Mini.sol';

interface IBACFarmer {
  function getRewards () external;
  function takeProfits () external;
  function takeProfitsWithCHI() external;
}

interface iCHI {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}

contract BACFarmerRelayerv3 is Ownable {
    using SafeMath for uint256;

    IKeep3rV1Mini public RLR;
    IBACFarmer public iBACFarm;
    iCHI public CHI;
    uint256 public lastHarvest = 0;
    uint256 public harvestInterval = 2 hours;

    modifier upkeep() {
        require(RLR.isKeeper(msg.sender), "::isKeeper: relayer is not registered");
        _;
        RLR.worked(msg.sender);
        lastHarvest = block.timestamp;
    }

    modifier discountCHI() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart.sub(gasleft()) + 16 * msg.data.length;
        CHI.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);
    }

    //Use this to depricate this job to move rlr to another job later
    function destructJob() public onlyOwner {
     //Get the credits for this job first
     uint256 currRLRCreds = RLR.credits(address(this),address(RLR));
     uint256 currETHCreds = RLR.credits(address(this),RLR.ETH());
     //Send out RLR Credits if any
     if(currRLRCreds > 0) {
        //Invoke receipt to send all the credits of job to owner
        RLR.receipt(address(RLR),owner(),currRLRCreds);
     }
     //Send out ETH credits if any
     if (currETHCreds > 0) {
        RLR.receiptETH(owner(),currETHCreds);
     }
     //Finally self destruct the contract after sending the credits
     selfdestruct(payable(owner()));
    }

    function recoverERC20(address tokenAddress) public onlyOwner {
        TransferHelper.safeTransfer(tokenAddress,owner(),getTokenBalance(tokenAddress));
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function updateFarmer(address farmer) public onlyOwner {
        iBACFarm = IBACFarmer(farmer);
        lastHarvest = 0;
    }

    function updateHarvestInterval(uint256 newInterval) public onlyOwner {
        harvestInterval = newInterval;
    }

    //Init interfaces with addresses
    constructor (address token,address farmer) public {
        RLR = IKeep3rV1Mini(token);
        iBACFarm = IBACFarmer(farmer);
        CHI = iCHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    }

    function workable() public view returns (bool) {
        return (block.timestamp - lastHarvest) > harvestInterval;
    }

    function work() public upkeep {
        require(workable(),"!workable");
        iBACFarm.takeProfits();
    }

    function workWithChi() public upkeep discountCHI {
        require(workable(),"!workable");
        iBACFarm.takeProfitsWithCHI();
    }

    function workWithChiOwner() public onlyOwner discountCHI{
        iBACFarm.takeProfitsWithCHI();
    }
}
