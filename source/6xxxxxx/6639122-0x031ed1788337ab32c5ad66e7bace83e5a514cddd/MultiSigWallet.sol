pragma solidity ^0.4.18;

contract MultiSigWallet {

    event Deposit(address indexed sender, uint value);
    event SubmitTransaction(address indexed sender,address indexed destination);
    event ExecuteTransaction(address indexed from, uint value);

    mapping (address => bool) public isOwner;
    mapping (address => address) public ownerCommitedAddresses;
    address[] public owners;

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            throw;
        _;
    }

    modifier balanceGt0(address _address) {
        if (this.balance == 0)
            throw;
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    function MultiSigWallet()
        public
    { 
        owners = [0xC4a1D8CcAEdD700d2d450903b50401c0bC360A4E,0xCC7A9B1f9d84b94e1452db96eDacd9b0406ae051];
        for (uint i=0; i<owners.length; i++) {
            isOwner[owners[i]] = true;
        }
    }

    /// Allows owner to submit a destination address.
    /// @param destination Transaction target address.
    function submitTransaction(address destination)
        public
        ownerExists(msg.sender)
        notNull(destination)
        balanceGt0(this)
    {
        ownerCommitedAddresses[msg.sender] = destination;
        executeTransaction(destination);
        SubmitTransaction(msg.sender,destination);
    }

    /// Allows owner to delete commited destination address
    function deleteTransaction()
        public
        ownerExists(msg.sender)
    {
        delete ownerCommitedAddresses[msg.sender];
    }

    /*
     * Internal functions
     */
    /// @param destination Transaction target address.
    function executeTransaction(address destination)
        internal
    {
        if(canExecute(destination)){
            uint amount = this.balance;
            destination.send(amount);
            setOwnerAddressNull();
            ExecuteTransaction(this,amount);
        }
    }

    /// @param destination Transaction target address.
    function canExecute(address destination)
        internal
        returns (bool)
    {
        bool canPass = true;
        for (uint i=0; i<owners.length; i++) {
            if(( ownerCommitedAddresses[owners[i]]== 0) || destination != ownerCommitedAddresses[owners[i]]){
                 canPass = false;
            }
        }
        return canPass;
    }

    function setOwnerAddressNull()
         internal
    {
        for (uint i=0; i<owners.length; i++) {
            delete ownerCommitedAddresses[owners[i]];
        }
    }

    /*
    * Web3 call functions
    */

    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    function getOwnerSubmitAddress(address owner)
        public
        constant
        returns (address)
    {
        return ownerCommitedAddresses[owner];
    }
}
