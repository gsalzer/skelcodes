pragma solidity ^0.5.11;

contract Burnable {
    bool private _burnallow;
    address private _burner;
    address public pendingBurner;

    modifier whenBurn() {
        require(_burnallow, "burnable: can't burn");
        _;
    }

    modifier onlyBurner() {
        require(msg.sender == _burner, "caller is not a burner");
        _;
    }

    modifier onlyPendingBurner() {
        require(msg.sender == pendingBurner);
        _;
    }

    event BurnerTransferred(address indexed previousBurner, address indexed newBurner);

    constructor () internal {
        _burnallow = true;
        _burner = msg.sender;
    }

    function burnallow() public view returns (bool) {
        return _burnallow;
    }

    function burner() public view returns (address) {
        return _burner;
    }

    function burnTrigger() public onlyBurner {
        _burnallow = !_burnallow;
    }

    function transferWhitelistAdmin(address newBurner) public onlyBurner {
        pendingBurner = newBurner;
    }

    function claimBurner() public onlyPendingBurner {
        emit BurnerTransferred(_burner, pendingBurner);
        _burner = pendingBurner;
        pendingBurner = address(0);
    }
}
