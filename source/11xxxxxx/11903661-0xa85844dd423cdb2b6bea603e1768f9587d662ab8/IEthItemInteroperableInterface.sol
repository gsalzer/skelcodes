// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IERC20Data.sol";

interface IEthItemInteroperableInterface is IERC20, IERC20Data {

    function init(uint256 id, string calldata name, string calldata symbol, uint256 decimals) external;

    function mainInterface() external view returns (address);

    function objectId() external view returns (uint256);

    function mint(address owner, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function permitNonce(address sender) external view returns(uint256);

    function permit(address owner, address spender, uint value, uint8 v, bytes32 r, bytes32 s) external;

    function interoperableInterfaceVersion() external pure returns(uint256 ethItemInteroperableInterfaceVersion);
}
