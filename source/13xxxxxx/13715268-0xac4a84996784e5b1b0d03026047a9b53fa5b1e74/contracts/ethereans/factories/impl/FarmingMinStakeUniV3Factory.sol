// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./EthereansFactory.sol";
import "../../../core/model/IOrganization.sol";
import "../../../base/model/IStateManager.sol";
import { Getters, State } from "../../../base/lib/KnowledgeBase.sol";
import { Getters as ExternalGetters } from  "../../../ext/lib/KnowledgeBase.sol";
import { Grimoire as EthereansOSGrimoire, State as EthereansOSState } from  "../../lib/KnowledgeBase.sol";
import { BytesUtilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FarmingMinStakeUniV3Factory is EthereansFactory {
    using ReflectionUtilities for address;
    using TransferUtilities for address;
    using Getters for IOrganization;
    using ExternalGetters for IOrganization;
    using State for IStateManager;
    using BytesUtilities for bytes;

    address public uniswapV3NonfungiblePositionManager;
    address public defaultExtension;

    constructor(bytes memory lazyInitData) EthereansFactory(lazyInitData) {
    }

    function _ethosFactoryLazyInit(bytes memory lazyInitData) internal override returns(bytes memory) {
        (defaultExtension, uniswapV3NonfungiblePositionManager) = abi.decode(lazyInitData, (address, address));
        return "";
    }

    function cloneDefaultExtension() external returns (address clonedAddress) {
        return defaultExtension.clone();
    }

    function deploy(bytes calldata deployData) external payable override returns(address deployedAddress, bytes memory deployedLazyInitResponse) {
        deployer[deployedAddress = modelAddress.clone()] = msg.sender;
        emit Deployed(modelAddress, deployedAddress, msg.sender, deployedLazyInitResponse = ILazyInitCapableElement(deployedAddress).lazyInit(abi.encode(uniswapV3NonfungiblePositionManager, deployData)));
        require(ILazyInitCapableElement(deployedAddress).initializer() == address(this));
    }

    function _realFeeInfo() internal override view returns(uint256 feePercentageForTransacted, address feeReceiver, address tokenToTransferOrBurnAddressInCreation, uint256 transferOrBurnAmountInCreation, address transferOrBurnReceiverInCreation, address tokenToTransferOrBurnAddressInApplication, uint256 transferOrBurnAmountInApplication, address transferOrBurnReceiverInApplication) {
        IOrganization host = IOrganization(ILazyInitCapableElement(initializer).host());
        if(address(host) != address(0)) {
            feeReceiver = address(this);
            transferOrBurnReceiverInApplication = address(0);
            IStateManager stateManager = host.stateManager();
            if(address(stateManager) != address(0)) {

                string[] memory keys = new string[](2);
                keys[0] = EthereansOSState.STATEMANAGER_ENTRY_NAME_FARMING_FEE_PERCENTAGE_FOR_TRANSACTED;
                keys[1] = EthereansOSState.STATEMANAGER_ENTRY_NAME_FARMING_FEE_FOR_BURNING_OS;

                IStateManager.StateEntry[] memory entries = stateManager.list(keys);
                feePercentageForTransacted = entries[0].value.length > 0 ? entries[0].value.asUint256() : 0;
                transferOrBurnAmountInApplication = entries[1].value.length > 0 ? entries[1].value.asUint256() : 0;

                return (
                    feePercentageForTransacted,
                    feeReceiver,
                    tokenToTransferOrBurnAddressInCreation,
                    transferOrBurnAmountInCreation,
                    transferOrBurnReceiverInCreation,
                    _tokenToTransferOrBurnAddressInApplication,
                    transferOrBurnAmountInApplication,
                    transferOrBurnReceiverInApplication
                );
            }
        }
    }

    function _feePaid(address, address tokenAddress, uint256, uint256, uint256 feePaid, uint256, address) internal override {
        if(feePaid > 0) {
            if(tokenAddress == _tokenToTransferOrBurnAddressInApplication) {
                ERC20Burnable(tokenAddress).burn(feePaid);
            } else {
                IOrganization host = IOrganization(ILazyInitCapableElement(initializer).host());
                if(address(host) != address(0)) {
                    address receiver = address(IOrganization(host).treasurySplitterManager());
                    receiver = receiver != address(0) ? receiver : address(IOrganization(host).treasuryManager());
                    if(receiver != address(0)) {
                        tokenAddress.safeTransfer(receiver, feePaid);
                    }
                }
            }
        }
    }
}
