// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IBasicIssuanceModule {
    function controller() external view returns (address);

    function getRequiredComponentUnitsForIssue(address _setToken, uint256 _quantity)
        external
        view
        returns (address[] memory, uint256[] memory);

    function initialize(address _setToken, address _preIssueHook) external;

    function issue(
        address _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function managerIssuanceHook(address) external view returns (address);

    function redeem(
        address _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function removeModule() external;
}

