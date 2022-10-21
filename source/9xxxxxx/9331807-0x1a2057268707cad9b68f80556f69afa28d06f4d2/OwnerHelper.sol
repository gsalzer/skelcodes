pragma solidity ^0.5.9;

contract OwnerHelper
{

    address public master;
    address public manager;

    event ChangeMaster(address indexed _from, address indexed _to);
    event ChangeManager(address indexed _from, address indexed _to);

    modifier onlyMaster
    {
        require(msg.sender == master);
        _;
    }
    
    modifier onlyManager
    {
        require(msg.sender == manager);
        _;
    }

    constructor() public
    {
        master = msg.sender;
    }
    
    function transferMastership(address _to) onlyMaster public
    {
        require(_to != master);
        require(_to != manager);
        require(_to != address(0x0));

        address from = master;
        master = _to;

        emit ChangeMaster(from, _to);
    }

    function transferManager(address _to) onlyMaster public
    {
        require(_to != master);
        require(_to != manager);
        require(_to != address(0x0));
        
        address from = manager;
        manager = _to;
        
        emit ChangeManager(from, _to);
    }
}

