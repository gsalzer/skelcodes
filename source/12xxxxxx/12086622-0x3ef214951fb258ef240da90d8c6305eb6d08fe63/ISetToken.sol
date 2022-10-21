// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface ISetToken {
    function addComponent(address _component) external;

    function addExternalPositionModule(address _component, address _positionModule) external;

    function addModule(address _module) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(address _account, uint256 _quantity) external;

    function components(uint256) external view returns (address);

    function controller() external view returns (address);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function editDefaultPositionUnit(address _component, int256 _realUnit) external;

    function editExternalPositionData(
        address _component,
        address _positionModule,
        bytes memory _data
    ) external;

    function editExternalPositionUnit(
        address _component,
        address _positionModule,
        int256 _realUnit
    ) external;

    function editPositionMultiplier(int256 _newMultiplier) external;

    function getComponents() external view returns (address[] memory);

    function getDefaultPositionRealUnit(address _component) external view returns (int256);

    function getExternalPositionData(address _component, address _positionModule) external view returns (bytes memory);

    function getExternalPositionModules(address _component) external view returns (address[] memory);

    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns (int256);

    function getModules() external view returns (address[] memory);

    function getTotalComponentRealUnits(address _component) external view returns (int256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function initializeModule() external;

    function invoke(
        address _target,
        uint256 _value,
        bytes memory _data
    ) external returns (bytes memory _returnValue);

    function isComponent(address _component) external view returns (bool);

    function isExternalPositionModule(address _component, address _module) external view returns (bool);

    function isInitializedModule(address _module) external view returns (bool);

    function isLocked() external view returns (bool);

    function isPendingModule(address _module) external view returns (bool);

    function lock() external;

    function locker() external view returns (address);

    function manager() external view returns (address);

    function mint(address _account, uint256 _quantity) external;

    function moduleStates(address) external view returns (uint8);

    function modules(uint256) external view returns (address);

    function name() external view returns (string memory);

    function positionMultiplier() external view returns (int256);

    function removeComponent(address _component) external;

    function removeExternalPositionModule(address _component, address _positionModule) external;

    function removeModule(address _module) external;

    function removePendingModule(address _module) external;

    function setManager(address _manager) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function unlock() external;
}

