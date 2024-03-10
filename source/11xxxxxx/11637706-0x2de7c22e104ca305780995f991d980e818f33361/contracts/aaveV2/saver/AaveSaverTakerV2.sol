pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../auth/AdminAuth.sol";
import "../../auth/ProxyPermission.sol";
import "../../utils/DydxFlashLoanBase.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../exchangeV3/DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
/// @dev Contract needs to have enough wei in WETH for all transactions (2 WETH wei per transaction)
contract AaveSaverTakerV2 is DydxFlashLoanBase, ProxyPermission, GasBurner, DFSExchangeData {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable public constant AAVE_RECEIVER = 0x817B2e0293cb75022e7E527bDB7274b87564e0Ca;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    function repay(address _market, ExchangeData memory _data, uint _rateMode, uint256 _gasCost, uint _flAmount) public payable {
        _flashLoan(_market, _data, _rateMode,_gasCost, true, _flAmount);
    }

    function boost(address _market, ExchangeData memory _data, uint _rateMode, uint256 _gasCost, uint _flAmount) public payable {
        _flashLoan(_market, _data, _rateMode, _gasCost, false, _flAmount);
    }

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must send 2 wei with this transaction
    function _flashLoan(address _market, ExchangeData memory _data, uint _rateMode, uint _gasCost, bool _isRepay, uint _flAmount) internal {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        uint256 ethAmount = _flAmount;

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(ethAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, ethAmount, AAVE_RECEIVER);
        AAVE_RECEIVER.transfer(msg.value);
        bytes memory encodedData = packExchangeData(_data);
        operations[1] = _getCallAction(
            abi.encode(encodedData, _market, _rateMode, _gasCost, _isRepay, ethAmount, msg.value, proxyOwner(), address(this)),
            AAVE_RECEIVER
        );
        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        givePermission(AAVE_RECEIVER);
        solo.operate(accountInfos, operations);
        removePermission(AAVE_RECEIVER);
    }
}

