// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IBasket {
    function BURN_FEE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function FEE_DIVISOR() external view returns (uint256);

    function FEE_RECIPIENT() external view returns (bytes32);

    function GOVERNANCE() external view returns (bytes32);

    function GOVERNANCE_ADMIN() external view returns (bytes32);

    function INITIALIZED() external view returns (bytes32);

    function MARKET_MAKER() external view returns (bytes32);

    function MARKET_MAKER_ADMIN() external view returns (bytes32);

    function MIGRATOR() external view returns (bytes32);

    function MINT_FEE() external view returns (bytes32);

    function TIMELOCK() external view returns (bytes32);

    function TIMELOCK_ADMIN() external view returns (bytes32);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approveModule(address _module) external;

    function approvedModules(address) external view returns (bool);

    function assets(uint256) external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 _amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function getAssetsAndBalances() external view returns (address[] memory, uint256[] memory);

    function getFees()
        external
        view
        returns (
            uint256,
            uint256,
            address
        );

    function getOne() external view returns (address[] memory, uint256[] memory);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function mint(uint256 _amountOut) external;

    function name() external view returns (string memory);

    function pause() external;

    function paused() external view returns (bool);

    function renounceRole(bytes32 role, address account) external;

    function rescueERC20(address _asset, uint256 _amount) external;

    function revokeModule(address _module) external;

    function revokeRole(bytes32 role, address account) external;

    function setAssets(address[] memory _assets) external;

    function setFee(
        uint256 _mintFee,
        uint256 _burnFee,
        address _recipient
    ) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function unpause() external;

    function viewMint(uint256 _amountOut) external view returns (uint256[] memory _amountsIn);
}

