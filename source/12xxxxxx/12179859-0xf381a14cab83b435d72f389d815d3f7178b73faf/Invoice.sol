// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint256);
}

/// @title The Invoice contract sends all tokens to the receiver and destructs himself
/// @author davy42
/// @dev The rest of ETH on the wallet will be sent to the receiver even if it's a contract without receive function
contract Invoice {

    /// @notice Constructor
    /// @dev The Invoice contract has only constructor.
    /// @param token The address of the erc20 token contract
    /// @param receiver The address to which tokens will be sent
    /// @param amount amount of tokens
    constructor(IERC20 token, address payable receiver, uint256 amount) {
        token.transfer(receiver, amount);
        selfdestruct(receiver);
    }
}

/// @title The Invoice contract sends all tokens to the receiver and destructs himself
/// @author davy42
/// @dev The rest of ETH on the wallet will be sent to the receiver even if it's a contract without receive function
contract SimpleInvoice {

    /// @notice Constructor
    /// @dev The Invoice contract has only constructor.
    /// @param token The address of the erc20 token contract
    /// @param receiver The address to which tokens will be sent
    constructor(IERC20 token, address payable receiver) {
        token.transfer(receiver, token.balanceOf(address(this)));
        selfdestruct(receiver);
    }
}
