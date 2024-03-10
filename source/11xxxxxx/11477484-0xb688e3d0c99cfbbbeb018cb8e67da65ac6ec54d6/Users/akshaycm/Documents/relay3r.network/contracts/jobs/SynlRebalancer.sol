// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
//Import job interfaces and helper interfaces
import '../interfaces/ISyntLayer.sol';
import '../interfaces/Keep3r/IKeep3rV1Mini.sol';
import '../interfaces/Uniswap/IWETH.sol';
import '../interfaces/Uniswap/IUniswapV2Router.sol';

interface iSYNLT is ISyntLayer,IERC20 {}

contract SynlRebalancer is Ownable {
    using SafeMath for uint256;
    IKeep3rV1Mini public RLR;
    iSYNLT public iSYNL;
    IUniswapV2Router internal router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address internal CHI = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    address internal WETH = router.WETH();
    address internal rebalancerAddr = 0x17b4Ef0C9D47B88d30C3b3dd3099f013133934cc;

    receive() external payable {}

    modifier upkeep() {
        require(RLR.isKeeper(msg.sender), "::isKeeper: relayer is not registered");
        _;
        RLR.worked(msg.sender);
    }

    //Init interfaces with addresses
    constructor (address token,address synltoken) public {
        RLR = IKeep3rV1Mini(token);
        iSYNL = iSYNLT(synltoken);
    }

    /** Path stuff **/
    function getPath(address tokent,bool isSell) internal view returns (address[] memory path){
        path = new address[](2);
        path[0] = isSell ? tokent : WETH;
        path[1] = isSell ? WETH : tokent;
        return path;
    }

    function getSellPath(address tokent) public view returns (address[] memory path) {
        path = getPath(tokent,true);
    }

    function getBuyPath(address tokent) public view returns (address[] memory path){
        path = getPath(tokent,false);
    }
    /** Path stuff end **/

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

    function workable() public view returns (bool) {
        return iSYNL.rebalanceable();
    }

    function getExcessSYNL() public view returns (uint256) {
        return iSYNL.balanceOf(address(this)) > iSYNL.minRebalanceAmount() ? iSYNL.balanceOf(address(this)).sub(iSYNL.minRebalanceAmount()) : 0;
    }

    function work() public upkeep {
        require(workable(),"!workable");
        iSYNL.rebalanceLiquidity();
        //We have synl in contract,swap them to eth and send to relayer
        //Approve before swap
        uint256 currSynlbal = getExcessSYNL();
        iSYNL.approve(address(router),currSynlbal);
        //Swap 90% to ETH
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                currSynlbal.mul(90).div(100),
                0,
                getSellPath(address(iSYNL)),
                address(this),
                block.timestamp.add(200)
        );
        //Send eth to relayer
        msg.sender.transfer(address(this).balance);
        //Get path from synl->eth->chi
        address[] memory pathtoCHI = new address[](3);
        pathtoCHI[0] = address(iSYNL);
        pathtoCHI[1] =  WETH;
        pathtoCHI[2] =  CHI;
        //Swap  synl->eth->chi,send them to rebalancer contract to refill chi balance
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                getExcessSYNL(),//Swap 10% of synl to chi and send to rebalancer for use
                0,
                pathtoCHI,
                rebalancerAddr,
                block.timestamp.add(200)
        );
    }

    function recoverERC20(address token) public onlyOwner {
        sendERC20(token,owner());
    }

    function sendExcessSYNL() public onlyOwner {
        iSYNL.transfer(owner(),getExcessSYNL());
    }

    //Helper functions for handling sending of reward token
    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function sendERC20(address tokenAddress,address receiver) internal {
        IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
    }
}
