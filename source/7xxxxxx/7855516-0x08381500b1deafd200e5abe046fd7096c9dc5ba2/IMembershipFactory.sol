pragma solidity >=0.5.3 < 0.6.0;

interface IMembershipFactory{
    // TODO: comments
    function deployMembershipManager(address _communityManager) external returns (address);

    function initialize(address _tokenManager, address _target) external;

}
