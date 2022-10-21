pragma solidity 0.7.0;
// SPDX-License-Identifier: MIT
 
import '../@openzeppelin/contracts/math/Math.sol';
import '../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '../@interface/ICHIToken.sol';
import './SafeOwnable.sol';
 
contract RobotLimit is SafeOwnable{
     
     mapping(address=>bool) robots;

     function setRobot(address robot,bool active) public onlyOwner{
         robots[robot] = active;
     }

     function isBotActive(address bot) public view returns(bool){
         return robots[bot];
     }

     modifier onlyRobot() {
         require(robots[msg.sender],"!auth");
         _;
     }
     
}






