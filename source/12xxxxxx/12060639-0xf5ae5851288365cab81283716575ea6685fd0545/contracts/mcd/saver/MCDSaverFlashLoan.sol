pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../exchangeV3/DFSExchangeCore.sol";

/// @title Receiver of Dydx flash loan and performs the fl repay/boost logic
/// @notice Must have a dust amount of WETH on the contract for 2 wei dydx fee
contract MCDSaverFlashLoan is MCDSaverProxy, AdminAuth, FlashLoanReceiverBase {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    struct SaverData {
        uint cdpId;
        uint gasCost;
        uint loanAmount;
        uint fee;
        address joinAddr;
        ManagerType managerType;
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (
            bytes memory exDataBytes,
            uint cdpId,
            uint gasCost,
            address joinAddr,
            bool isRepay,
            uint8 managerType
        )
         = abi.decode(_params, (bytes,uint256,uint256,address,bool,uint8));

        ExchangeData memory exchangeData = unpackExchangeData(exDataBytes);

        SaverData memory saverData = SaverData({
            cdpId: cdpId,
            gasCost: gasCost,
            loanAmount: _amount,
            fee: _fee,
            joinAddr: joinAddr,
            managerType: ManagerType(managerType)
        });

        if (isRepay) {
            repayWithLoan(exchangeData, saverData);
        } else {
            boostWithLoan(exchangeData, saverData);
        }

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function boostWithLoan(
        ExchangeData memory _exchangeData,
        SaverData memory _saverData
    ) internal {

        address managerAddr = getManagerAddr(_saverData.managerType);

        address user = getOwner(Manager(managerAddr), _saverData.cdpId);

        // Draw users Dai
        uint maxDebt = getMaxDebt(managerAddr, _saverData.cdpId, Manager(managerAddr).ilks(_saverData.cdpId));
        uint daiDrawn = drawDai(managerAddr, _saverData.cdpId, Manager(managerAddr).ilks(_saverData.cdpId), maxDebt);

        // Swap
        _exchangeData.srcAmount = daiDrawn + _saverData.loanAmount - takeFee(_saverData.gasCost, daiDrawn + _saverData.loanAmount);
        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        (, uint swapedAmount) = _sell(_exchangeData);

        // Return collateral
        addCollateral(managerAddr, _saverData.cdpId, _saverData.joinAddr, swapedAmount);

        // Draw Dai to repay the flash loan
        drawDai(managerAddr, _saverData.cdpId,  Manager(managerAddr).ilks(_saverData.cdpId), (_saverData.loanAmount + _saverData.fee));

        logger.Log(address(this), msg.sender, "MCDFlashBoost", abi.encode(_saverData.cdpId, user, _exchangeData.srcAmount, swapedAmount));
    }

    function repayWithLoan(
        ExchangeData memory _exchangeData,
        SaverData memory _saverData
    ) internal {

        address managerAddr = getManagerAddr(_saverData.managerType);

        address user = getOwner(Manager(managerAddr), _saverData.cdpId);
        bytes32 ilk = Manager(managerAddr).ilks(_saverData.cdpId);

        // Draw collateral
        uint maxColl = getMaxCollateral(managerAddr, _saverData.cdpId, ilk, _saverData.joinAddr);
        uint collDrawn = drawCollateral(managerAddr, _saverData.cdpId, _saverData.joinAddr, maxColl);

        // Swap
        _exchangeData.srcAmount = (_saverData.loanAmount + collDrawn);
        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        (, uint paybackAmount) = _sell(_exchangeData);

        paybackAmount -= takeFee(_saverData.gasCost, paybackAmount);
        paybackAmount = limitLoanAmount(managerAddr, _saverData.cdpId, ilk, paybackAmount, user);

        // Payback the debt
        paybackDebt(managerAddr, _saverData.cdpId, ilk, paybackAmount, user);

        // Draw collateral to repay the flash loan
        drawCollateral(managerAddr, _saverData.cdpId, _saverData.joinAddr, (_saverData.loanAmount + _saverData.fee));

        logger.Log(address(this), msg.sender, "MCDFlashRepay", abi.encode(_saverData.cdpId, user, _exchangeData.srcAmount, paybackAmount));
    }

    /// @notice Handles that the amount is not bigger than cdp debt and not dust
    function limitLoanAmount(address _managerAddr, uint _cdpId, bytes32 _ilk, uint _paybackAmount, address _owner) internal returns (uint256) {
        uint debt = getAllDebt(address(vat), Manager(_managerAddr).urns(_cdpId), Manager(_managerAddr).urns(_cdpId), _ilk);

        if (_paybackAmount > debt) {
            ERC20(DAI_ADDRESS).transfer(_owner, (_paybackAmount - debt));
            return debt;
        }

        uint debtLeft = debt - _paybackAmount;

        (,,,, uint dust) = vat.ilks(_ilk);
        dust = dust / 10**27;

        // Less than dust value
        if (debtLeft < dust) {
            uint amountOverDust = (dust - debtLeft);

            ERC20(DAI_ADDRESS).transfer(_owner, amountOverDust);

            return (_paybackAmount - amountOverDust);
        }

        return _paybackAmount;
    }

    receive() external override(FlashLoanReceiverBase, DFSExchangeCore) payable {}

}

