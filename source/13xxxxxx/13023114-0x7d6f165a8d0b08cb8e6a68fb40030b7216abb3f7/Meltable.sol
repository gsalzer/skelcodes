pragma solidity ^0.5.11;


contract Meltable {
    mapping (address => bool) private _melters;
    address private _melteradmin;
    address public pendingMelterAdmin;

    modifier onlyMelterAdmin() {
        require (msg.sender == _melteradmin, "caller not a melter admin");
        _;
    }

    modifier onlyMelter() {
        require (_melters[msg.sender] == true, "can't perform melt");
        _;
    }

    modifier onlyPendingMelterAdmin() {
        require(msg.sender == pendingMelterAdmin);
        _;
    }

    event MelterTransferred(address indexed previousMelter, address indexed newMelter);

    constructor () internal {
        _melteradmin = msg.sender;
        _melters[msg.sender] = true;
    }

    function melteradmin() public view returns (address) {
        return _melteradmin;
    }

    function addToMelters(address account) public onlyMelterAdmin {
        _melters[account] = true;
    }

    function removeFromMelters(address account) public onlyMelterAdmin {
        _melters[account] = false;
    }

    function transferMelterAdmin(address newMelter) public onlyMelterAdmin {
        pendingMelterAdmin = newMelter;
    }

    function claimMelterAdmin() public onlyPendingMelterAdmin {
        emit MelterTransferred(_melteradmin, pendingMelterAdmin);
        _melteradmin = pendingMelterAdmin;
        pendingMelterAdmin = address(0);
    }
}
