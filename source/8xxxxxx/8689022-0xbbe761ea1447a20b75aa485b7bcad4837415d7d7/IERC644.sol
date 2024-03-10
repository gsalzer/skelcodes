pragma solidity 0.5.8;


interface IERC644 {
    function getBalance(address _acct) external view returns(uint);
    function incBalance(address _acct, uint _val) external returns(bool);
    function decBalance(address _acct, uint _val) external returns(bool);
    function getAllowance(address _owner, address _spender) external view returns(uint);
    function setApprove(address _sender, address _spender, uint256 _value) external returns(bool);
    function decApprove(address _from, address _spender, uint _value) external returns(bool);
    function getModule(address _acct) external view returns (bool);
    function setModule(address _acct, bool _set) external returns(bool);
    function getTotalSupply() external view returns(uint);
    function incTotalSupply(uint _val) external returns(bool);
    function decTotalSupply(uint _val) external returns(bool);
    function transferRoot(address _new) external returns(bool);

    event BalanceAdj(address indexed Module, address indexed Account, uint Amount, string Polarity);
    event ModuleSet(address indexed Module, bool indexed Set);
}


