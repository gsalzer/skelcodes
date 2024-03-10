// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


/**
 * @title Interface of VokenTB.
 */
interface IVokenTB {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function cap() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    
    function mint(address account, uint256 amount) external returns (bool);
    function mintWithVesting(address account, uint256 amount, address vestingContract) external returns (bool);

    function referrer(address account) external view returns (address payable);
    function address2voken(address account) external view returns (uint160);
    function voken2address(uint160 voken) external view returns (address payable);
}

