pragma solidity ^0.6.4;

/**
 * @title UniswapFactoryInterface
 * @dev Uniswap factory interface.
 * https://docs.uniswap.io/smart-contract-api/factory
 */
interface UniswapFactoryInterface {
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}
