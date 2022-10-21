//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IDexRouter.sol";
import "./BaseConfig.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Types.sol";
import "./libs/LibStorage.sol";

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract Settlement is BaseConfig {

    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint128;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    //============= EVENT DEFS =================/
    event TraderPenalized(address indexed trader, 
                          uint256 penalty, 
                          uint256 gasPaid, 
                          string reason);
    event SwapFailed(address indexed trader, 
                     string reason, 
                     IERC20 feeToken, 
                     uint gasFeePaid);
    event SwapSuccess(address indexed trader,
                       uint inputAmount,
                       uint outputAmount,
                       IERC20 feeToken,
                       uint gasFee,
                       uint bpsFee);
    event ReceivedETH(address indexed sender, uint amount);
    event WithdrewETH(address indexed receiver, uint amount);
    event PaidGasFunds(address indexed relay, uint amount);
    event InsufficientGasFunds(address indexed relay, uint amount);

    //============== CONSTANTS ==============/
    //gas needed after action executes
    uint256 constant OP_GAS = 40_000;

    //for final transfers and events
    uint256 constant GAS_OVERHEAD = 50_000;

    struct BalTracking {
        uint256 beforeIn;
        uint256 beforeOut;
        uint256 afterIn;
        uint256 afterOut;
    }

    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }

    /**
     * Fill an order using the given router and forwarded call data.
     */
    function fill(Types.Order memory order, IDexRouter router, bytes calldata data) public onlyRelay nonReentrant {

        uint256 startGas = gasleft();
        //pre-trade condition checks
        BalTracking memory _tracker = _preCheck(order);

        //make adjustments to order input if fee token is sell-side
        Types.Order memory adjusted = _preAdjustOrder(order);

        //execute fill
        (bool success, string memory failReason) = performFill(adjusted, router, data);

        //post-trade condition check
        _postCheck(order, _tracker, success);

        //post-trade actions to transfer fees, etc.
        _postActions(order, success, failReason, _tracker, startGas);
    } 

    /**
     * Team's ability to withdraw ETH balance from the contract.
     */
    function withdraw(uint amount) public onlyAdmin {
        require(amount <= address(this).balance, "Insufficient balance to make transfer");
        _msgSender().transfer(amount);
        emit WithdrewETH(_msgSender(), amount);
    }

    // @dev initialize the settlement contract 
    function initialize(Types.Config memory config) public initializer {
        BaseConfig.initConfig(config);
    }

    // @dev whether the trader has a token balance to support input side of order
    function _hasTokens(Types.Order memory order) internal view returns (bool) {
        bool b = order.input.token.balanceOf(order.trader) >= order.input.amount;
        return b;
    }

    // @dev whether the trader has approved this contract to spend enought for order
    function _canSpend(Types.Order memory order) internal view returns (bool) {
        bool b = order.input.token.allowance(order.trader, address(this)) >= order.input.amount;
        return b;
    }

    // @dev make sure trader has token balance and allowance to cover order
    function _preCheck(Types.Order memory order) internal view returns (BalTracking memory) {
        //require(_hasFunds(order, tx.gasprice), "Insufficient gas tank funds");
        require(_hasTokens(order), "Insufficient input token balance to trade");
        require(_canSpend(order), "Insufficient spend allowance on input token");
        //before balances
        return BalTracking(
            order.input.token.balanceOf(order.trader),
            order.output.token.balanceOf(address(this)),
            0,0
        );
    }

    
    // @dev compute the gas and BPS fee for an order
    function _computeFees(Types.Order memory order, uint gasUsed) internal view returns (uint gasFee, uint bpsFee) {
        console.log("---- Computing Fees -----");
        uint estGasCost = tx.gasprice * gasUsed;
        console.log("Estimated gas cost", estGasCost);
        uint decs = IERC20Metadata(address(order.feeToken)).decimals();
        gasFee = (estGasCost.mul(10**decs)).div(order.feeTokenETHPrice);
        console.log("Gas portion in fee token", gasFee);
        if(order.feeToken == order.input.token) {
            bpsFee = (order.input.amount.mul(LibStorage.getConfigStorage().minFee)).div(10000); //in bps
        } else {
            bpsFee = (order.output.amount.mul(LibStorage.getConfigStorage().minFee)).div(10000);
        }
        console.log("BPS fee", bpsFee); 
        console.log("---- End compute fees ----");   
    }

    // @dev make adjustments to input amount if the fee token is the sell-side token
    function _preAdjustOrder(Types.Order memory order) internal view returns (Types.Order memory) {
        if(order.feeToken == order.input.token) {
            console.log("Taking fee from output token");
            uint newInput = 0;
            {
                //compute gas and bps fees
                (uint gasPortion, uint bpsPortion) = _computeFees(order, order.gasEstimate);

                //take out fees before swap
                newInput = order.input.amount.sub(gasPortion.add(bpsPortion));
                console.log("Old input amount", order.input.amount);
                console.log("New input amount", newInput);
            }

            //create new order using most of same info except new input amount
            return Types.Order({trader: order.trader, 
                feeToken: order.feeToken,
                feeTokenETHPrice: order.feeTokenETHPrice,
                gasEstimate: order.gasEstimate,
                input: Types.TokenAmount({
                    token: order.input.token,
                    amount: uint112(newInput)
                }),
                output: order.output
            });
        } 
        //output fee does not need to make any adjustments. Everything is done after swap
        return order;  
    }

    // @dev perform the actual token swap, catching any problems along the way so we can handle
    // gas reimbursements correctly
    function performFill(Types.Order memory order, IDexRouter router, bytes calldata data) internal returns (bool success, string memory failReason) {
        //execute action. This is critical that we use our own internal call to actually
        //perform swap inside trycatch. This way, transferred funds to router are 
        //reverted if swap fails

        try this._trySwap{
            gas: gasleft().sub(OP_GAS)
        }(order, router, data) returns (bool _success, string memory _failReason) {
            if(!_success) {
                console.log("FailReason", _failReason);
            }
            return (_success, _failReason);
        } catch Error(string memory err) {
            success = false;
            failReason = err;
            console.log("FailReason", err);
        } catch {
            success = false;
            failReason = "Unknown fail reason";
        }
        
        
    }

    // @dev perform any pre-swap actions, like transferring tokens to router
    function _preActions(Types.Order memory order, IDexRouter router) internal {
        //transfer input tokens to router so it can perform dex trades
        console.log("Transfering to router:", order.input.amount);
        order.input.token.safeTransferFrom(order.trader, address(router), order.input.amount);
    }

    // @dev try making the swap through router.
    function _trySwap(Types.Order calldata order, IDexRouter router, bytes calldata data) external returns (bool success, string memory failReason) {
        require(msg.sender == address(this), "Can only be called by settlement contract");
        _preActions(order, router);
        (bool s, string memory err) = router.fill(order, data);
        if(!s) {
            revert(err);
        }
        return (s, err);
    }

    // @dev after swap, check if expected balances match
    function _postCheck(Types.Order memory order, BalTracking memory _tracking, bool success) internal view {
        
        _tracking.afterIn = order.input.token.balanceOf(order.trader);

        if(!success) {
            //have to revert if funds were not refunded in order to roll everything back.
            //in this case, the router is at fault, which is Dexible's fault and therefore 
            //Dexible relay address should eat the cost of failure
            console.log("Input bal b4", _tracking.beforeIn);
            console.log("Input bal after", _tracking.afterIn);
            require(_tracking.afterIn == _tracking.beforeIn, "failed trade action did not refund input funds");
        } else {
            _tracking.afterOut = order.output.token.balanceOf(address(this));
            //if the in/out amounts don't line up, then transfers weren't made properly in the
            //router.

            console.log("Output token balance before swap", _tracking.beforeOut);
            console.log("Output balance after swap", _tracking.afterOut);
            require(_tracking.afterOut.sub(_tracking.beforeOut) >= order.output.amount, "Trade action did not transfer output tokens to trader");
            require(_tracking.beforeIn.sub(_tracking.afterIn) <= order.input.amount, "Used too many input tokens");
        }
    }

    // @dev carry out post-swap actions, transferring funds, etc.
    function _postActions(Types.Order memory order, 
                          bool success, 
                          string memory failReason, 
                          BalTracking memory _tracking,
                          uint startGas) internal {

        //reimburse relay estimated gas fees. Add a little overhead for the remaining
        //ops in this function
        uint256 totalGasUsed = startGas.sub(gasleft()).add(GAS_OVERHEAD);
        console.log("Total gas used", totalGasUsed);

        uint256 gasFee = totalGasUsed.mul(tx.gasprice);
        console.log("Gas fee", gasFee);

        //compute post-swap fees again now that we have a better idea of actual gas usage
        (uint gasInFeeToken, uint bpsFee) = _computeFees(order, totalGasUsed);
        
        //if there is ETH in the contract, reimburse the relay that called the fill function
        if(address(this).balance < gasFee) {
            console.log("Cannot reimburse relay since do not have enough funds");
            emit InsufficientGasFunds(_msgSender(), gasFee);
        } else {
            console.log("Transfering gas fee to relay");
            _msgSender().transfer(gasFee);
            emit PaidGasFunds(_msgSender(), gasFee);
        }
       
        uint fees = 0;
        if(!success) {
            //we still owe the gas fees to the team/relay even though the swap failed. This is because
            //the trader may have set slippage too low, thus increasing the chance of failure.
            fees = (gasInFeeToken);
            console.log("Failed gas fee", fees);
            if(order.feeToken == order.input.token) {
                console.log("Transferring partial input token to devteam for failure gas fees");
                order.feeToken.safeTransferFrom(order.trader, LibStorage.getConfigStorage().devTeam, fees);
                emit SwapFailed(order.trader,failReason, order.feeToken, fees);
            } else {
                console.log("Fee token is output; therefore cannot reimburse team for failure gas fees");
                emit SwapFailed(order.trader,failReason, order.feeToken, 0);
            }
            
            //tell trader it failed
            console.log("Swap failed");
            
        } else {
            //on success, the gas and bps fee are paid to the dev team
            fees = gasInFeeToken.add(bpsFee);

            //gross is delta between starting/ending balance before/after swap
            uint grossOut = _tracking.afterOut.sub(_tracking.beforeOut);
            console.log("Gross output amount", grossOut);

            uint toTrader = 0;
            if(order.feeToken == order.input.token) {
                //if we take fees from the input token,
                //the trader gets all output 
                toTrader = grossOut;
                console.log("Transferring fees from input token to devTeam", fees);
                order.feeToken.safeTransferFrom(order.trader, LibStorage.getConfigStorage().devTeam, fees);
            } else {
                //otherwise, trader gets a portion of the output
                //and team gets rest
                console.log("Reducing output by fees", fees);
                toTrader = grossOut.sub(fees);
                
                //output comes from this contract, not trader for fees
                console.log("Sending fees from output token to team", fees);
                order.feeToken.safeTransfer(LibStorage.getConfigStorage().devTeam, fees);
            }
            
            console.log("Sending total output to trader", toTrader);
            order.output.token.safeTransfer(order.trader, toTrader);

            emit SwapSuccess(order.trader,
                        order.input.amount,
                        toTrader, 
                        order.feeToken,
                        gasInFeeToken,
                        bpsFee); 
            console.log("Finished swap");
        }
    }
}
