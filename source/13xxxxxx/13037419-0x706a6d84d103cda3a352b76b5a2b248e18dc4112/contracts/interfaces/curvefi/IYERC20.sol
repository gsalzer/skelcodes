// SPDX-License-Identifier: None
pragma solidity 0.6.12;

interface IYERC20 {

    // //ERC20 functions
    // function totalSupply() external view returns (uint256);
    // function balanceOf(address account) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function allowance(address owner, address spender) external view returns (uint256);
    // function approve(address spender, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    // function name() external view returns (string memory);
    // function symbol() external view returns (string memory);
    // function decimals() external view returns (uint8);

    //Y-token functions
    function deposit(uint256 amount) external;
    function withdraw(uint256 shares) external;
    function getPricePerFullShare() external view returns (uint256);

    function token() external returns(address);

}
