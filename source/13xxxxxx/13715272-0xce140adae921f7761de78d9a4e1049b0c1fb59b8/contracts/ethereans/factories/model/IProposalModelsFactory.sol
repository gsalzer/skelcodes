//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;

import "@ethereansos/swissknife/contracts/factory/impl/Factory.sol";

interface IProposalModelsFactory is IFactory {

    event Singleton(address indexed productAddress);

    function deploySingleton(bytes calldata code, bytes calldata deployData) external returns(address deployedAddress, bytes memory deployLazyInitResponse);

    function addModel(bytes calldata code, string calldata uri) external returns(address modelAddress, uint256 positionIndex);

    function models() external view returns(address[] memory addresses, string[] memory uris);

    function singletons() external view returns(address[] memory addresses);

    function setModelUris(uint256[] memory indices, string[] memory uris) external;

    function model(uint256 i) external view returns(address modelAddress, string memory modelUri);

    function singleton(uint256 i) external view returns(address singletonAddress);
}
