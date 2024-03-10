pragma solidity ^0.5.0;

interface IEGToken {

    function mint(address account, uint256 amount) external returns (bool);

    function deBlacklistAddress(address account) external;

    function burnBlacklistToken(address blacklistAddress, uint256 burnAmount) external;

    function updateSuperAdmin(address newSuperAdmin) external;

    function burn(uint256 amount) external;

    function balanceOf(address account) external returns(uint256);


}

