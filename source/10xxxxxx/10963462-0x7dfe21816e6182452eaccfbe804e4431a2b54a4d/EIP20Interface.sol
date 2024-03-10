pragma solidity ^0.5.16;

/**
 * @title EIP20Interface
 */
contract EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return uint
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param _owner The address from which the balance will be retrieved
     * @return uint
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param _dst The address of the destination account
     * @param _amount The number of tokens to transfer
     * @return bool
     */
    function transfer(address _dst, uint256 _amount) external returns (bool success);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param _src The address of the source account
     * @param _dst The address of the destination account
     * @param _amount The number of tokens to transfer
     * @return bool
     */
    function transferFrom(address _src, address _dst, uint256 _amount) external returns (bool success);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @param _spender The address of the account which may transfer tokens
     * @param _amount The number of tokens that are approved (-1 means infinite)
     * @return uint
     */
    function approve(address _spender, uint256 _amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param _owner The address of the account which owns the tokens to be spent
     * @param _spender The address of the account which may transfer tokens
     * @return uint
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}
