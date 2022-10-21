pragma solidity >= 0.5.3 < 0.6.0;

//  ERC20 Interface
//  - interface for ERC20 token functions for compatibility
interface ERC20Interface {
    function balanceOf(address _who) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
