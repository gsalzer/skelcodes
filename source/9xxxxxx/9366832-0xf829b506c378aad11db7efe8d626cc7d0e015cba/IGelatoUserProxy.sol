pragma solidity ^0.6.0;

import "./IGelatoAction.sol";
import "./GelatoCoreEnums.sol";

/// @title IGelatoUserProxy - solidity interface of GelatoConditionsStandard
/// @notice GelatoUserProxy.execute() API called by gelatoCore during .execute()
/// @dev all the APIs are implemented inside GelatoUserProxy
interface IGelatoUserProxy {
    function callAccount(address, bytes calldata) external payable returns(bool, bytes memory);
    function delegatecallAccount(address, bytes calldata) external payable returns(bool, bytes memory);

    function delegatecallGelatoAction(
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256 _actionGas
    )
        external
        payable;

    function user() external view returns(address);
    function gelatoCore() external view returns(address);
}
