pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../../utils/SafeERC20.sol";
import "../../../interfaces/TokenInterface.sol";
import "../../../DS/DSProxy.sol";
import "../../AaveHelperV2.sol";
import "../../../auth/AdminAuth.sol";
import "../../../exchangeV3/DFSExchangeCore.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiverOV2 is AaveHelperV2, AdminAuth, DFSExchangeCore {

    using SafeERC20 for ERC20;

    address public constant AAVE_BASIC_PROXY = 0xc17c8eB12Ba24D62E69fd57cbd504EEf418867f9;

    function boost(ExchangeData memory _exchangeData, address _market, uint256 _gasCost, address _proxy) private {
        (, uint swappedAmount) = _sell(_exchangeData);

        address user = DSAuth(_proxy).owner();
        swappedAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), swappedAmount, user, _gasCost, _exchangeData.destAddr);
 
        // if its eth we need to send it to the basic proxy, if not, we need to approve basic proxy to pull tokens
        uint256 msgValue = 0;
        if (_exchangeData.destAddr == ETH_ADDR) {
            msgValue = swappedAmount;
        } else {
            ERC20(_exchangeData.destAddr).safeApprove(_proxy, swappedAmount);
        }
        // deposit collateral on behalf of user
        DSProxy(payable(_proxy)).execute{value: msgValue}(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "deposit(address,address,uint256)",
                _market,
                _exchangeData.destAddr,
                swappedAmount
                )
            );
    }

    function repay(ExchangeData memory _exchangeData, address _market, uint256 _gasCost, address _proxy, uint256 _rateMode, uint _withdrawValue) private {
        (, uint swappedAmount) = _sell(_exchangeData);

        address user = DSAuth(_proxy).owner();
        swappedAmount -= getGasCost(ILendingPoolAddressesProviderV2(_market).getPriceOracle(), swappedAmount, user, _gasCost, _exchangeData.destAddr);

        // if its eth we need to send it to the basic proxy, if not, we need to approve basic proxy to pull tokens
        uint256 msgValue = 0;
        if (_exchangeData.destAddr == ETH_ADDR) {
            msgValue = swappedAmount;
        } else {
            ERC20(_exchangeData.destAddr).safeApprove(_proxy, swappedAmount);
        }
        // first payback the loan with swapped amount
        DSProxy(payable(_proxy)).execute{value: msgValue}(
            AAVE_BASIC_PROXY,
            abi.encodeWithSignature(
                "payback(address,address,uint256,uint256)",
                _market,
                _exchangeData.destAddr,
                swappedAmount,
                _rateMode
                )
            );

        // pull the amount we flash loaned in collateral to be able to payback the debt
        DSProxy(payable(_proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256)", _market, _exchangeData.srcAddr, _withdrawValue));
    }

    function executeOperation(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) public returns (bool) {
        (
            bytes memory exchangeDataBytes,
            address market,
            uint256 gasCost,
            uint256 rateMode,
            bool isRepay,
            address proxy
        )
        = abi.decode(params, (bytes,address,uint256,uint256,bool,address));

        require(initiator == proxy, "initiator isn't proxy");

        ExchangeData memory exData = unpackExchangeData(exchangeDataBytes);
        exData.user = DSAuth(proxy).owner();    
        exData.dfsFeeDivider = MANUAL_SERVICE_FEE;
        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            exData.dfsFeeDivider = AUTOMATIC_SERVICE_FEE;
        }

        // this is to avoid stack too deep
        uint totalValueToReturn = exData.srcAmount + premiums[0];

        // if its repay, we are using regular flash loan and payback the premiums
        if (isRepay) {
            repay(exData, market, gasCost, proxy, rateMode, totalValueToReturn);
            
            address token = exData.srcAddr;
            if (token == ETH_ADDR) {
                // deposit eth, get weth and return to sender
                TokenInterface(WETH_ADDRESS).deposit.value(totalValueToReturn)();
                token = WETH_ADDRESS;
            }

            ERC20(token).safeApprove(ILendingPoolAddressesProviderV2(market).getLendingPool(), totalValueToReturn);
        } else {
            boost(exData, market, gasCost, proxy);
        }
        
        tx.origin.transfer(address(this).balance);

        return true;
    }

    /// @dev allow contract to receive eth from sell
    receive() external override payable {}
}

