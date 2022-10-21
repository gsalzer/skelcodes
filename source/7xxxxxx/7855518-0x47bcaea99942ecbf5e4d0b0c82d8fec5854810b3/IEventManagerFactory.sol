pragma solidity >=0.5.3 < 0.6.0;

interface IEventManagerFactory{
    function deployEventManager(address _tokenManager, address _membershipManager, address _communityCreator) external returns (address);
}
