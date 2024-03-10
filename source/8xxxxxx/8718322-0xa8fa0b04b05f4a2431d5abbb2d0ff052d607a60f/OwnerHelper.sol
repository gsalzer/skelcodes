pragma solidity ^0.5.0;

contract OwnerHelper
{

    address public master;
    address public issuer;
    address public manager;

    event ChangeMaster(address indexed _from, address indexed _to);
    event ChangeIssuer(address indexed _from, address indexed _to);
    event ChangeManager(address indexed _from, address indexed _to);

    modifier onlyMaster
    {
        require(msg.sender == master);
        _;
    }
    
    modifier onlyIssuer
    {
        require(msg.sender == issuer);
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
        require(_to != issuer);
        require(_to != manager);
        require(_to != address(0x0));

        address from = master;
        master = _to;

        emit ChangeMaster(from, _to);
    }

    function transferIssuer(address _to) onlyMaster public
    {
        require(_to != master);
        require(_to != issuer);
        require(_to != manager);
        require(_to != address(0x0));

        address from = issuer;
        issuer = _to;

        emit ChangeIssuer(from, _to);
    }

    function transferManager(address _to) onlyMaster public
    {
        require(_to != master);
        require(_to != issuer);
        require(_to != manager);
        require(_to != address(0x0));
        
        address from = manager;
        manager = _to;
        
        emit ChangeManager(from, _to);
    }
}

