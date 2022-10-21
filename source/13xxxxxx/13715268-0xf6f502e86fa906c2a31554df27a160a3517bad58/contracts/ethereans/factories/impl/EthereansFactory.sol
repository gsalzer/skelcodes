// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/IEthereansFactory.sol";
import "@ethereansos/swissknife/contracts/factory/impl/Factory.sol";
import "../../factoryOfFactories/model/IFactoryOfFactories.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { TransferUtilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

abstract contract EthereansFactory is Factory, IEthereansFactory {
    using TransferUtilities for address;

    uint256 internal _feePercentageForTransacted;
    address internal _feeReceiver;
    address internal _tokenToTransferOrBurnAddressInCreation;
    uint256 internal _transferOrBurnAmountInCreation;
    address internal _transferOrBurnReceiverInCreation;
    address internal _tokenToTransferOrBurnAddressInApplication;
    uint256 internal _transferOrBurnAmountInApplication;
    address internal _transferOrBurnReceiverInApplication;

    constructor(bytes memory lazyInitData) Factory(lazyInitData) {
    }

    receive() external payable {
    }

    function _factoryLazyInit(bytes memory initData) internal override virtual returns (bytes memory factoryLazyInitResponse) {
        EthereansFactoryInitializer memory ethereansFactoryInitializer;
        (ethereansFactoryInitializer) = abi.decode(initData, (EthereansFactoryInitializer));
        _feePercentageForTransacted = ethereansFactoryInitializer.feePercentageForTransacted;
        _feeReceiver = ethereansFactoryInitializer.feeReceiver;
        _tokenToTransferOrBurnAddressInCreation = ethereansFactoryInitializer.tokenToTransferOrBurnAddressInCreation;
        _transferOrBurnAmountInCreation = ethereansFactoryInitializer.transferOrBurnAmountInCreation;
        _transferOrBurnReceiverInCreation = ethereansFactoryInitializer.transferOrBurnReceiverInCreation;
        _tokenToTransferOrBurnAddressInApplication = ethereansFactoryInitializer.tokenToTransferOrBurnAddressInApplication;
        _transferOrBurnAmountInApplication = ethereansFactoryInitializer.transferOrBurnAmountInApplication;
        _transferOrBurnReceiverInApplication = ethereansFactoryInitializer.transferOrBurnReceiverInApplication;
        factoryLazyInitResponse = _ethosFactoryLazyInit(ethereansFactoryInitializer.factoryLazyInitData);
    }

    function feeInfo() public override view returns(address operator, uint256 feePercentageForTransacted, address feeReceiver, address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation, address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) {
        operator = initializer;
        (feePercentageForTransacted, feeReceiver, tokenToTransferOrBurnAddressInCreation, transferOrBurnAmountInCreation, transferOrBurnReceiverInCreation, tokenToTransferOrBurnAddressInApplication, transferOrBurnAmountInApplication, transferOrBurnReceiverInApplication) = _realFeeInfo();
    }

    function payFee(address sender, address tokenAddress, uint256 value, bytes calldata permitSignature) external override payable returns (uint256 feePaid) {
        (uint256 feePercentageForTransacted, address feeReceiver, , , , , uint256 transferOrBurnAmountInApplication, ) = _realFeeInfo();
        if(feePercentageForTransacted != 0) {
            (uint256 feeSentOrBurnt, uint256 fofFeePaid) = IFactoryOfFactories(initializer).payFee{value : tokenAddress == address(0) ? value : 0}(sender, tokenAddress, value, permitSignature, feePercentageForTransacted, feeReceiver);
            feePaid = feeSentOrBurnt + fofFeePaid;
            _feePaid(sender, tokenAddress, value, feeSentOrBurnt, fofFeePaid, feePercentageForTransacted, feeReceiver);
        } else {
            require(transferOrBurnAmountInApplication == 0, "zero fees");
        }
    }

    function _feePaid(address sender, address tokenAddress, uint256 value, uint256 feeSentOrBurnt, uint256 feePaid, uint256 feePercentageForTransacted, address feeReceiver) internal virtual {
    }

    function burnOrTransferToken(address sender, bytes calldata permitSignature) external payable override returns(uint256 amountTransferedOrBurnt) {
        (uint256 feePercentageForTransacted, , , , , address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) = _realFeeInfo();
        if(transferOrBurnAmountInApplication != 0) {
            (uint256 feeSentOrBurnt, uint256 fofAmountTransferedOrBurnt) = IFactoryOfFactories(initializer).burnOrTransferTokenAmount{value : tokenToTransferOrBurnAddressInApplication == address(0) ? transferOrBurnAmountInApplication : 0}(sender, tokenToTransferOrBurnAddressInApplication, transferOrBurnAmountInApplication, permitSignature, transferOrBurnReceiverInApplication);
            amountTransferedOrBurnt = feeSentOrBurnt + fofAmountTransferedOrBurnt;
            _amountTransferedOrBurnt(sender, feeSentOrBurnt, fofAmountTransferedOrBurnt, tokenToTransferOrBurnAddressInApplication, transferOrBurnAmountInApplication, transferOrBurnReceiverInApplication);
        } else {
            require(feePercentageForTransacted == 0, "zero amount");
        }
    }

    function _amountTransferedOrBurnt(address sender, uint256 feeSentOrBurnt, uint256 amountTransferedOrBurnt, address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) internal virtual {
    }

    function _burnOrTransferTokenAtCreation(address sender, bytes memory permitSignature) internal returns(uint256 amountTransferedOrBurnt) {
        (, , address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation, , , ) = _realFeeInfo();
        if(transferOrBurnAmountInCreation != 0) {
            (uint256 feeSentOrBurnt, uint256 fofAmountTransferedOrBurnt) = IFactoryOfFactories(initializer).burnOrTransferTokenAmount{value : tokenToTransferOrBurnAddressInCreation == address(0) ? transferOrBurnAmountInCreation : 0}(sender, tokenToTransferOrBurnAddressInCreation, transferOrBurnAmountInCreation, permitSignature, transferOrBurnReceiverInCreation);
            amountTransferedOrBurnt = feeSentOrBurnt + fofAmountTransferedOrBurnt;
            _amountTransferedOrBurntAtCreation(sender, feeSentOrBurnt, fofAmountTransferedOrBurnt, tokenToTransferOrBurnAddressInCreation, transferOrBurnAmountInCreation, transferOrBurnReceiverInCreation);
        }
    }

    function _amountTransferedOrBurntAtCreation(address sender, uint256 feeSentOrBurnt, uint256 amountTransferedOrBurnt, address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation) internal virtual {
    }

    function _subjectIsAuthorizedFor(address, address, bytes4 selector, bytes calldata, uint256) internal override pure returns (bool, bool) {
        if(selector == this.setModelAddress.selector || selector == this.setDynamicUriResolver.selector) {
            return (true, false);
        }
        return (false, false);
    }

    function _realFeeInfo() internal virtual view returns(uint256 feePercentageForTransacted, address feeReceiver, address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation, address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) {
        return (_feePercentageForTransacted, _feeReceiver, _tokenToTransferOrBurnAddressInCreation, _transferOrBurnAmountInCreation, _transferOrBurnReceiverInCreation, _tokenToTransferOrBurnAddressInApplication, _transferOrBurnAmountInApplication, _transferOrBurnReceiverInApplication);
    }

    function _ethosFactoryLazyInit(bytes memory lazyInitData) internal virtual returns(bytes memory lazyInitResponse);
}
