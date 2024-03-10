pragma solidity ^0.5.0;

import "./LotInterface.sol";

import "./OrganizationInterface.sol";
import "./PermissionsEnum.sol";

/**
 * @title Lot
 * @dev Lot contract to create new lot and change the states and change the ownership
 */
contract Lot is PermissionsEnum, LotInterface {
    address public factory;

    address public organization;
    address public parentLot;
    address public nextPermitted;

    string public infoFileHash;
    string public name;

    uint32 public totalSupply;
    uint32 public transferredSupply;

    mapping(address => uint32) public supplyDistributionInfo;

    enum LotState {
        NEW,
        INITIAL,
        GROW,
        HARVEST,
        EXTRACTING,
        EXTRACTED,
        TESTING,
        TESTED,
        PRODUCT,
        COMPLETE
    }

    LotState public state;

    event LotTotalSupplyConfigured (
        address organization,
        address lot,
        uint32 totalSupply
    );

    event LotNextPermittedChanged (
        address lot,
        address permitted
    );

    event LotStateChanged (
        address organization,
        address lot,
        uint previousState,
        uint nextState,
        string infoFileHash
    );

    event LotOwnershipTransferred (
        address lot,
        address currentOwner,
        address newOwner
    );

    modifier hasPermission(Permissions perm) {
        require(OrganizationInterface(organization).hasPermissions(msg.sender, uint256(perm)), "Not Allowed");
        _;
    }

    constructor(
        address _organization,
        address _factory,
        string memory _name,
        uint32 _totalSupply,
        address _parentLot,
        address _permitted)
    public {
        organization = _organization;
        factory = _factory;

        name = _name;
        totalSupply = _totalSupply;
        parentLot = _parentLot;
        initLot(0);

        nextPermitted = _permitted;
        if (_permitted != address(0)) {
            emit LotNextPermittedChanged(address(this), _permitted);
        }
    }

    function getOrganization() public view returns (address) {
        return organization;
    }

    function _getSubmittingOrganization(Permissions perm) internal view returns (address) {
        // check nextPermitted oranization
        if (nextPermitted != address(0) && OrganizationInterface(nextPermitted).hasPermissions(msg.sender, uint256(perm))) return nextPermitted;

        if (OrganizationInterface(organization).hasPermissions(msg.sender, uint256(perm))) return organization;

        return address(0);
    }

    /**
     * @dev Change the Lot State.
     * @param _nextState The next state of the Lot.
     * @param _infoFileHash The new infoFileHash of the Lot from IPFS .
     */
    function changeLotState(
        uint _nextState,
        string memory _infoFileHash
    )
    public
    {
        address submittingOrganization = _getSubmittingOrganization(Permissions.UPDATE_LOT);
        require(submittingOrganization != address(0), "Not Allowed");

        uint previousState = uint(state);
        require(_nextState != previousState, "Cannot submit the same state over");
        
        state = LotState(_nextState);
        infoFileHash = _infoFileHash;

        // Always return back to null after lot has changed
        nextPermitted = address(0);

        emit LotStateChanged(submittingOrganization, address(this), previousState, _nextState, _infoFileHash);
    }

    /**
     * @dev Changes the Lot state to Next State
     * @param _nextState The next Lot State.
     * @param _infoFileHash The File Hash representing IPFS record.
     * @param _permitted Next permitted user for the Lot.
     */
    function changeLotStateWithNextPermitted(
        uint _nextState,
        string memory _infoFileHash,
        address _permitted
    )
    public
    {
        address submittingOrganization = _getSubmittingOrganization(Permissions.UPDATE_LOT);
        require(submittingOrganization != address(0), "Not Allowed");

        uint previousState = uint(state);
        require(_nextState != previousState, "Cannot submit the same state over");

        state = LotState(_nextState);
        infoFileHash = _infoFileHash;

        nextPermitted = _permitted;

        emit LotStateChanged(submittingOrganization, address(this), previousState, _nextState, _infoFileHash);
        emit LotNextPermittedChanged(address(this), _permitted);
    }

    /**
     * @dev Sets the lot sate
     * @param _lotState The state of the lot.
     */
    function setLotState(uint _lotState)
    public
    {
        address submittingOrganization = _getSubmittingOrganization(Permissions.UPDATE_LOT);
        require(submittingOrganization != address(0), "Not Allowed");

        uint previousState = uint256(state);

        state = LotState(_lotState);

        emit LotStateChanged(submittingOrganization, address(this), previousState, _lotState, infoFileHash);
    }

    /**
     * @dev Allows to set infoHas to current Lot IPFS.
     * @param _infoFileHash The File Hash representing IPFS record.
     */
    function setInfoFileHash(string memory _infoFileHash)
    public
    {
        address submittingOrganization = _getSubmittingOrganization(Permissions.UPDATE_LOT);
        require(submittingOrganization != address(0), "Not Allowed");

        infoFileHash = _infoFileHash;
    }

    /**
     * @dev Allows to set totalSupply to current Lot.
     * @param _totalSupply The total supply of the current lot.
     */
    function setTotalSupply(uint32 _totalSupply)
    public
    hasPermission(Permissions.UPDATE_LOT)
    {
        require(totalSupply == 0, "Total supply already set");

        totalSupply = _totalSupply;

        emit LotTotalSupplyConfigured(organization, address(this), _totalSupply);
    }

    /**
     * @dev Sets the next permitted address to do a state change on Lot
     * @param _permitted the address to be added
     */
    function setNextPermitted(address _permitted)
    public
    hasPermission(Permissions.UPDATE_LOT)
    {
        nextPermitted = _permitted;
        emit LotNextPermittedChanged(address(this), _permitted);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner)
    public
    hasPermission(Permissions.TRANSFER_LOT_OWNERSHIP)
    returns (bool)
    {
        address currentOwner = organization;
        organization = _newOwner;

        emit LotOwnershipTransferred(address(this), currentOwner, _newOwner);
        return true;
    }

    /**
     * @dev Retieve the File Hash.
     */
    function retrieveFileHash()
    public
    view
    returns (string memory)
    {
        return infoFileHash;
    }

    /**
     * @dev Retieve Lot state.
     */
    function retrieveState()
    public
    view
    returns (uint)
    {
        return uint(state);
    }

    /**
     * @dev Retieve Total Supply.
     */
    function retrieveTotalSupply()
    public
    view
    returns (uint32)
    {
        return totalSupply;
    }

    /**
     * @dev Retieve Total Supply.
     */
    function retrieveTransferredSupply()
    public
    view
    returns (uint32)
    {
        return transferredSupply;
    }

    /**
     * @dev Retieve Sub Lot Supply.
     * @param _lotAddress The address to Sub Lot.
     */
    function retrieveSubLotSupply(address _lotAddress)
    public
    view
    returns (uint32)
    {
        return supplyDistributionInfo[_lotAddress];
    }

    /**
     * @dev Creates a new Lot.
     * @param _lotState The current state of the Lot.
     */
    function initLot(
        uint _lotState
    )
    private
    {
        state = LotState(_lotState);
    }

    /**
     * @dev Allocates supply for a given lot address
     * @param _quantity The total supply transferred
     */
    function allocateSupply(address _lotAddress, uint32 _quantity)
    public
    hasPermission(Permissions.ALLOCATE_SUPPLY)
    {
        require((transferredSupply + _quantity) <= totalSupply, "Cannot allocate supply, exceeds total supply");
        supplyDistributionInfo[_lotAddress] = _quantity;
        transferredSupply += _quantity;
    }
}

