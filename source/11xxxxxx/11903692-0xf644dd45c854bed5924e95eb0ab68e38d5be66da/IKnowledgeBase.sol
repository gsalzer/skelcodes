//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

pragma solidity 0.8.0;

import "./IEthItemOrchestratorDependantElement.sol";

/**
 * @title IKnowledgeBase
 * @dev This contract represents the Factory Used to deploy all the EthItems, keeping track of them.
 */
interface IKnowledgeBase is IEthItemOrchestratorDependantElement {

    function setERC20Wrapper(address newWrapper) external;

    function erc20Wrappers() external view returns(address[] memory);

    function erc20Wrapper() external view returns(address);

    function setEthItem(address ethItem) external;

    function isEthItem(address ethItem) external view returns(bool);

    function setWrapped(address wrappedAddress, address ethItem) external;

    function wrapper(address wrappedAddress, uint256 version) external view returns (address ethItem);
}
