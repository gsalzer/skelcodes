// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import '@openzeppelin/contracts/access/Ownable.sol';
import "../libraries/UniswapV2Library.sol";
import '../interfaces/Keep3r/IKeep3rV1Mini.sol';

enum OrderState {Placed, Cancelled, Executed}

interface UnitradeInterface {
    function cancelOrder(uint256 orderId) external returns (bool);

    function executeOrder(uint256 orderId)
        external
        returns (uint256[] memory amounts);

    function feeDiv() external view returns (uint16);

    function feeMul() external view returns (uint16);

    function getActiveOrderId(uint256 index) external view returns (uint256);

    function getActiveOrdersLength() external view returns (uint256);

    function getOrder(uint256 orderId)
        external
        view
        returns (
            uint8 orderType,
            address maker,
            address tokenIn,
            address tokenOut,
            uint256 amountInOffered,
            uint256 amountOutExpected,
            uint256 executorFee,
            uint256 totalEthDeposited,
            OrderState orderState,
            bool deflationary
        );

    function getOrderIdForAddress(address _address, uint256 index)
        external
        view
        returns (uint256);

    function getOrdersForAddressLength(address _address)
        external
        view
        returns (uint256);

    function incinerator() external view returns (address);

    function owner() external view returns (address);

    function placeOrder(
        uint8 orderType,
        address tokenIn,
        address tokenOut,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    ) external returns (uint256);

    function renounceOwnership() external;

    function splitDiv() external view returns (uint16);

    function splitMul() external view returns (uint16);

    function staker() external view returns (address);

    function transferOwnership(address newOwner) external;

    function uniswapV2Factory() external view returns (address);

    function uniswapV2Router() external view returns (address);

    function updateFee(uint16 _feeMul, uint16 _feeDiv) external;

    function updateOrder(
        uint256 orderId,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    ) external returns (bool);

    function updateSplit(uint16 _splitMul, uint16 _splitDiv) external;

    function updateStaker(address newStaker) external;
}

contract UnitradeExecutorRLRv2 is Ownable{

    UnitradeInterface iUniTrade = UnitradeInterface(
        0xC1bF1B4929DA9303773eCEa5E251fDEc22cC6828
    );

    //change this to relay3r on deploy
    IKeep3rV1Mini public RLR;

    bool TryDeflationaryOrders = false;
    bool public payoutETH = true;
    bool public payoutRLR = true;

    constructor(address keepertoken) public {
        RLR = IKeep3rV1Mini(keepertoken);
    }

    modifier upkeep() {
        require(RLR.isKeeper(msg.sender), "::isKeeper: relayer is not registered");
        _;
        if(payoutETH){
            //Payout ETH
            RLR.workedETH(msg.sender);
        }
        if(payoutRLR) {
            //Payout RLR
            RLR.worked(msg.sender);
        }
    }

    function togglePayETH() public onlyOwner {
        payoutETH = !payoutETH;
    }

    function togglePayRLR() public onlyOwner {
        payoutRLR = !payoutRLR;
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

    function setTryBurnabletokens(bool fTry) public onlyOwner{
        TryDeflationaryOrders = fTry;
    }


    function getIfExecuteable(uint256 i) public view returns (bool) {
        (
            ,
            ,
            address tokenIn,
            address tokenOut,
            uint256 amountInOffered,
            uint256 amountOutExpected,
            uint256 executorFee,
            ,
            OrderState orderState,
            bool deflationary
        ) = iUniTrade.getOrder(i);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        if(executorFee <= 0) return false;//Dont execute unprofitable orders
        if(deflationary && !TryDeflationaryOrders) return false;//Skip deflationary token orders as it is not supported atm
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            iUniTrade.uniswapV2Factory(),
            amountInOffered,
            path
        );
        if (
            amounts[1] >= amountOutExpected && orderState == OrderState.Placed
        ) {
            return true;
        }
        return false;
    }

    function hasExecutableOrdersPending() public view returns (bool) {
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength() - 1; i++) {
            if (getIfExecuteable(iUniTrade.getActiveOrderId(i))) {
                return true;
            }
        }
        return false;
    }

    //Get count of executable orders
    function getExectuableOrdersCount() public view returns (uint count){
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength() - 1; i++) {
            if (getIfExecuteable(iUniTrade.getActiveOrderId(i))) {
                count++;
            }
        }
    }

    function getExecutableOrdersList() public view returns (uint[] memory) {
        uint[] memory orderArr = new uint[](getExectuableOrdersCount());
        uint index = 0;
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength() - 1; i++) {
            if (getIfExecuteable(iUniTrade.getActiveOrderId(i))) {
                orderArr[index] = iUniTrade.getActiveOrderId(i);
                index++;
            }
        }
        return orderArr;
    }

    receive() external payable {
        if(payoutETH){
            //Add any eth received
            RLR.addCreditETH{value:msg.value}(address(this));
        }
        else {
            //Transfer received eth to treasury
            (bool success,  ) = payable(owner()).call{value : address(this).balance}("");
            require(success,"Pay ETH to Treasury failed");
        }

    }

    function workable() public view returns (bool) {
        return hasExecutableOrdersPending();
    }

    function work() public upkeep{
        require(workable(),"No executable trades");
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength() - 1; i++) {
            if (getIfExecuteable(iUniTrade.getActiveOrderId(i))) {
                iUniTrade.executeOrder(i);
            }
        }
    }

    //Use this to save on gas
    function workBatch(uint[] memory orderList) public upkeep {
        require(workable(),"No executable trades");
        for (uint256 i = 0; i < orderList.length; i++) {
            iUniTrade.executeOrder(orderList[i]);
        }
    }
}

