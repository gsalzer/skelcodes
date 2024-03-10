pragma solidity >=0.5.3 < 0.6.0;

interface ITokenManagerFactory{
    function deployMarket(
        string calldata _name,
        string calldata _symbol,
        address _reserveToken,
        address _proteaAccount,
        address _publisher,
        uint256 _contributionRate,
        address _membershipManager
    ) external returns (address);
}
