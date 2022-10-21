// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IFactoryOfFactories {

    function size() external view returns (uint256);
    function all() external view returns (address[] memory hosts, address[][] memory factoryLists);
    function partialList(uint256 start, uint256 offset) external view returns (address[] memory hosts, address[][] memory factoryLists);

    function get(uint256 index) external view returns(address host, address[] memory factoryList);

    function create(address[] calldata hosts, bytes[][] calldata factoryBytecodes) external returns (address[][] memory factoryLists, uint256[] memory listPositions);
    function setFactoryListsMetadata(uint256[] calldata listPositions, address[] calldata newHosts) external returns (address[] memory replacedHosts);
    event FactoryList(uint256 indexed listPosition, address indexed fromHost, address indexed toHost);

    function add(uint256[] calldata listPositions, bytes[][] calldata factoryBytecodes) external returns(address[][] memory factoryLists, uint256[][] memory factoryPositions);
    event FactoryAdded(uint256 indexed listPosition, address indexed host, address indexed factoryAddress, uint256 factoryPosition);

    function payFee(address sender, address tokenAddress, uint256 value, bytes calldata permitSignature, uint256 feePercentage, address feeReceiver) external payable returns (uint256 feeSentOrBurnt, uint256 feePaid);
    function burnOrTransferTokenAmount(address sender, address tokenAddress, uint256 value, bytes calldata permitSignature, address receiver) external payable returns(uint256 feeSentOrBurnt, uint256 amountTransferedOrBurnt);
}
