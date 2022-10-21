// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
//Import job interfaces and helper interfaces
import '../interfaces/ITrinity.sol';
import '../interfaces/Keep3r/IKeep3rV1Mini.sol';
import '../interfaces/Keep3r/IKeep3rV1Helper.sol';
import '../interfaces/Uniswap/IWETH.sol';
import '../interfaces/Uniswap/IUniswapV2Router.sol';
import "../interfaces/IChi.sol";

interface iTRI is ITrinity,IERC20 {}
interface iRLR is IKeep3rV1Mini {
    function KPRH() external returns (IKeep3rV1Helper);
    function workReceipt(address,uint) external;
}

contract TrinityAlchemizer is Ownable {
    using SafeMath for uint256;
    address[] internal TriTokens;
    address internal CHI = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    bool disableJob = false;

    iRLR public RLR;
    IUniswapV2Router internal router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    iCHI public chi = iCHI(CHI);

    address internal WETH = router.WETH();

    uint256 public BASE = 10000;
    uint256 public REDUCFACT = 5000;

    receive() external payable {}

    modifier upkeep() {
        require(RLR.isKeeper(msg.sender), "::isKeeper: relayer is not registered");

        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 *
                           msg.data.length;
        if(chi.balanceOf(address(this)) > 0)
            chi.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);

        uint reward = RLR.KPRH().getQuoteLimit(gasSpent).mul(REDUCFACT).div(BASE);
        RLR.workReceipt(msg.sender,reward);
    }

    //Init interfaces with addresses
    constructor (address token) public {
        RLR = iRLR(token);
        require(chi.approve(address(this), uint256(-1)));
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

    function addTrinityToken(address token) public onlyOwner {
        TriTokens.push(token);
    }

    function setReductionRate(uint256 newred) public onlyOwner {
        REDUCFACT = newred;
    }

    function toggleJob() public onlyOwner {
        disableJob = !disableJob;
    }

    function canAlchemize(address token) public view returns (bool) {
        iTRI tokeni = iTRI(token);
        return block.timestamp > tokeni.getLastAlchemy().add(tokeni.getAlchemyInterval());
    }

    function getAlchemizeableCount() public view returns (uint256 count) {
        count = 0;
        for(uint i=0;i<TriTokens.length;i++) {
            if(canAlchemize(TriTokens[i]) && getTokenBalance(TriTokens[i]) >iTRI(TriTokens[i]).getMinTokenForAlchemy()) { count++;}
        }
    }

    function getAlchemizeableTokens() public view returns (address[] memory arr) {
        arr = new address[](getAlchemizeableCount());
        uint256 index =0;
        for(uint i=0;i<TriTokens.length;i++) {
            if(canAlchemize(TriTokens[i]) && getTokenBalance(TriTokens[i]) > iTRI(TriTokens[i]).getMinTokenForAlchemy()){
                arr[index] = TriTokens[i];
                index++;
            }
        }
    }

    function getTrinityTokens() public view returns (address[] memory) {
        return TriTokens;
    }

    function getExcess(iTRI tokenint) public view returns (uint256) {
        return tokenint.balanceOf(address(this)) > tokenint.getMinTokenForAlchemy() ? tokenint.balanceOf(address(this)).sub(tokenint.getMinTokenForAlchemy()) : 0;
    }

    function workable() public view returns (bool) {
        return getAlchemizeableCount() > 0 && !disableJob;
    }

    function work(address token) public upkeep {
        iTRI tokeni = iTRI(token);
        tokeni.alchemy();
        //We have tri in contract,swap them to eth and send to relayer
        //Approve before swap
        uint256 currTokenBal = getExcess(tokeni);
        tokeni.approve(address(router),currTokenBal);
        //Swap 90% to ETH
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                currTokenBal.mul(9).div(10),
                0,
                getSellPath(token),
                address(this),
                block.timestamp.add(200)
        );
        //Send 90%
        msg.sender.transfer(address(this).balance.mul(9).div(10));
        //Send 10% of ETH to owner
        payable(owner()).transfer(address(this).balance);
        //Get path from tri->eth->chi
        address[] memory pathtoCHI = new address[](3);
        pathtoCHI[0] = token;
        pathtoCHI[1] =  WETH;
        pathtoCHI[2] =  CHI;
        //Swap  tri->eth->chi,send them to rebalancer contract to refill chi balance
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                getExcess(tokeni),//Swap 10% of tri to chi and send to rebalancer for use
                0,
                pathtoCHI,
                address(this),
                block.timestamp.add(200)
        );
    }

    function recoverERC20(address token) public onlyOwner {
        sendERC20(token,owner());
    }

    function sendExcess(uint256 index) public onlyOwner {
        iTRI tokeni = iTRI(TriTokens[index]);
        tokeni.transfer(owner(),getExcess(tokeni));
    }

    //Helper functions for handling sending of reward token
    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function sendERC20(address tokenAddress,address receiver) internal {
        IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
    }
}
