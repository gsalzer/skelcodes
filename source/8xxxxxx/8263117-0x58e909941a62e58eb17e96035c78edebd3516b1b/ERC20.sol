pragma solidity 0.4.26;


contract ERC20Interface {

    /// @return total amount of tokens
    function totalSupply() public view returns (uint);

    /// @tokenOwner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address tokenOwner) public view returns (uint balance);

    /// @param tokenOwner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    /// @notice send `tokens` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param tokens The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address to, uint tokens) public returns (bool success);

    /// @notice send `tokens` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param tokens The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    /// @notice `msg.sender` approves `spender` to spend `tokens` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param tokens The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address spender, uint tokens) public returns (bool success);

    function mint(uint256 value) public returns (bool);
    function mintToWallet(address to, uint256 tokens) public returns (bool);
    function burn(uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

