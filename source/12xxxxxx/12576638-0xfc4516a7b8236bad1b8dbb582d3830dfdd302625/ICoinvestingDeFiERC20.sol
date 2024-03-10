// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface ICoinvestingDeFiERC20 {
    // Events
    event Approval(
        address indexed owner,
        address indexed spender,
        uint value
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint value
    );

    // External functions
    function approve(
        address spender,
        uint value
    )
        external 
        returns (bool);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;
    
    function transfer(
        address to,
        uint value
    )
        external
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    )
        external
        returns (bool);
    
    // External functions that are view        
    function allowance(
        address owner,
        address spender
    )
        external 
        view 
        returns (uint);

    function balanceOf(address owner) external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function totalSupply() external view returns (uint);

    // External functions that are pure
    function decimals() external pure returns (uint8);
    function name() external pure returns (string memory);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function symbol() external pure returns (string memory);
}

