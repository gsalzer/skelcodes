pragma solidity ^0.5.0;

contract Owned {

    // Holds the address of the owner of the contract
    // who is able to perform contract management operations
    address internal _owner;

    // Holds the address of the invited party to become
    // the new contract owner. This is switched back to
    // address(0) once the new owner accepts.
    address internal _newOwner;

    // An event emitted when the ownership is successfully
    // transferred to the new owner
    event OwnershipTransferred(address indexed _from, address indexed _to);

    // Function modifier for functions accessable
    // only by the owner of the contract
    modifier onlyOwner {

        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    /**
     * Constructor of the contract. Initializes the owner
     * address as the address of the contract creator
     */
    constructor()
    public {

        _owner = msg.sender;
        _newOwner = address(0);
    }

    /**
     * Invites another party to become the new owner of
     * the contract. Current owner is still in charge until
     * the new owner accepts the incitation. Current owner
     * can revoke the invitation by calling this function
     * again with address(0), assuming it has not been accepted
     *
     * @param newOwner - The address of the new owner
     */
    function transferOwnership(address newOwner)
    public
    onlyOwner {

        _newOwner = newOwner;
    }

    /**
     * Invoked by the invited party to accept the ownership
     * invitation. Must be called from the address stored
     * in newOwner. Once this call succeeds, the owner is changed
     * and an OwnershipTransferred event is emitted
     */
    function acceptOwnership()
    public {

        require(msg.sender == _newOwner, "This function can be called only by the new owner address");

        emit OwnershipTransferred(_owner, _newOwner);

        _owner = _newOwner;
        _newOwner = address(0);
    }

    /**
     * A constant function used to check if the if the
     * caller is the owner of the contract
     *
     * @return bool - True if 'msg.sender' is the owner
     */
    function isOwner()
    public view
    returns (bool) {

        return msg.sender == _owner;
    }

    /**
     * A constant function used to get the address of
     * the contract owner
     *
     * @return address - The address of the owner.
     */
    function owner()
    public view
    returns (address) {
        return _owner;
    }
}

