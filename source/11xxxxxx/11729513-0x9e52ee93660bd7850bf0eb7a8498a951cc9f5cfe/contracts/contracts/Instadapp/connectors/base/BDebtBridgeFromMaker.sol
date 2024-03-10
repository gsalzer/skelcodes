// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {GelatoBytes} from "../../../../lib/GelatoBytes.sol";
import {
    DataFlow
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";
import {
    _isVaultOwner,
    _getMakerVaultDebt
} from "../../../../functions/dapps/FMaker.sol";
import {
    AccountInterface,
    ConnectorInterface
} from "../../../../interfaces/InstaDapp/IInstaDapp.sol";

abstract contract BDebtBridgeFromMaker is ConnectorInterface {
    using GelatoBytes for bytes;

    string public constant OK = "OK";
    uint256 internal immutable _id;
    address public immutable oracleAggregator;
    address public immutable instaFeeCollector;
    address public immutable connectGelatoDataFromMakerAddr;
    address internal immutable _connectGelatoDebtBridgeFee;

    constructor(
        uint256 __id,
        address _oracleAggregator,
        address __instaFeeCollector,
        address __connectGelatoDebtBridgeFee
    ) {
        _id = __id;
        oracleAggregator = _oracleAggregator;
        instaFeeCollector = __instaFeeCollector;
        _connectGelatoDebtBridgeFee = __connectGelatoDebtBridgeFee;
        connectGelatoDataFromMakerAddr = address(this);
    }

    /// @dev Connector Details
    function connectorID()
        external
        view
        override
        returns (uint256 _type, uint256 id)
    {
        (_type, id) = (1, _id); // Should put specific value.
    }

    // ====== ACTION TERMS CHECK ==========
    // Overriding IGelatoAction's function (optional)
    function termsOk(
        uint256, // taskReceipId
        address _dsa,
        bytes calldata _actionData,
        DataFlow,
        uint256, // value
        uint256 // cycleId
    ) public view returns (string memory) {
        uint256 vaultId = abi.decode(_actionData[4:36], (uint256));

        if (vaultId == 0)
            return
                string(
                    abi.encodePacked(this.name(), ": Vault Id is not valid")
                );
        if (!_isVaultOwner(vaultId, _dsa))
            return
                string(
                    abi.encodePacked(this.name(), ": Vault not owned by dsa")
                );
        return OK;
    }

    function _cast(address[] memory targets, bytes[] memory datas) internal {
        // Instapool V2 / FlashLoan call
        bytes memory castData =
            abi.encodeWithSelector(
                AccountInterface.cast.selector,
                targets,
                datas,
                msg.sender // msg.sender == GelatoCore
            );

        (bool success, bytes memory returndata) =
            address(this).delegatecall(castData);
        if (!success) {
            returndata.revertWithError(
                string(
                    abi.encodePacked(
                        ConnectorInterface(connectGelatoDataFromMakerAddr)
                            .name(),
                        "._cast:"
                    )
                )
            );
        }
    }
}

