pragma solidity 0.8.3;

interface ProjectOwnerServiceInterface {

    function getProjectOwner(address _address) external view returns(address);
    
    function getProjectFeeInWei(address _address) external view returns(uint256);

    function isProjectRegistered(address _address) external view returns(bool);

    function isProjectOwnerService() external view returns(bool);

}
