pragma solidity ^0.5.0;


interface IBalancerPool {
    function isFinalized()
        external view returns (bool);

    function getCurrentTokens()
        external view returns (address[] memory tokens);

    function getSwapFee()
        external view returns (uint256);

    function getDenormalizedWeight(address token)
        external view returns (uint256);

    function getBalance(address token)
        external view returns (uint256);
}

