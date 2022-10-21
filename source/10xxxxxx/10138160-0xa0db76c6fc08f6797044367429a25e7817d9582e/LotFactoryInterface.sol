pragma solidity ^0.5.0;

contract LotFactoryInterface {
    function createLot(
        address _organization,
        string memory _name)
    public
    returns(
        address);

    /*
     * @dev Create Sub Lot for existing Lot.
     */
    function createSubLot(
        address _organization,
        address _parentLot,
        string memory _name,
        uint32 _totalSupply,
        address _nextPermitted)
    public
    returns (
        address);
}

