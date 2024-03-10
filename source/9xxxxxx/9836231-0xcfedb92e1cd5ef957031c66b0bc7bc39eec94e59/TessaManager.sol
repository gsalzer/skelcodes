pragma solidity >=0.4.21 <0.7.0;

contract TessaManager {
    string public name = "TESSA MANAGER @2020";

    address internal _owner;
    mapping (address => bool) internal _whitelist;
    mapping (address => bool) internal _managers;

    event SetWhitelist(address indexed _addr, bool state);
    event SetManager(address indexed _addr, bool state);

    constructor() public {
        _owner = msg.sender;
        setWhitelist(msg.sender, true);
        setManager(msg.sender, true);
    }

    function setWhitelist(address _addr, bool state) public returns (bool) {
        require(msg.sender == _owner, "owner:false");
        require(_addr != address(0), "addr:0x0");
        _whitelist[_addr] = state;
        emit SetWhitelist(_addr, state);
        return true;
    }

    function isWhitelist(address _addr) public view returns (bool) {
        require(_addr != address(0), "addr:0x0");
        return _whitelist[_addr];
    }

    function setManager(address _addr, bool state) public returns (bool) {
        require(msg.sender == _owner, "owner:false");
        require(_addr != address(0), "addr:0x0");
        _managers[_addr] = state;
        _whitelist[_addr] = state;
        emit SetManager(_addr, state);
        emit SetWhitelist(_addr, state);
        return true;
    }

    function isManager(address _addr) public view returns (bool) {
        require(_addr != address(0), "addr:0x0");
        return _managers[_addr];
    }
}
