pragma solidity ^0.5.17;

interface GTTokenInterface {
    function isInvestorRegistered(address addr) external view returns(bool);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function owner() external view returns (address);

    function getCompanyTokenBalance(string calldata companyTokenName, address addr) external view returns(uint);

    function burnTokens(uint gtAmount) external returns(bool);
}

