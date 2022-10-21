pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getOwnerStatic(address ownableContract) internal view returns (address) {
        bytes memory callcodeOwner = abi.encodeWithSignature("getOwner()");
        (bool success, bytes memory returnData) = address(ownableContract).staticcall(callcodeOwner);
        require(success, "input address has to be a valid ownable contract");
        return parseAddr(returnData);
    }

    function getTokenVestingStatic(address tokenFactoryContract) internal view returns (address) {
        bytes memory callcodeTokenVesting = abi.encodeWithSignature("getTokenVesting()");
        (bool success, bytes memory returnData) = address(tokenFactoryContract).staticcall(callcodeTokenVesting);
        require(success, "input address has to be a valid TokenFactory contract");
        return parseAddr(returnData);
    }


    function parseAddr(bytes memory data) public pure returns (address parsed){
        assembly {parsed := mload(add(data, 32))}
    }




}


/**
 * @title Registry contract for storing token proposals
 * @dev For storing token proposals. This can be understood as a state contract with minimal CRUD logic.
 * @author Jake Goh Si Yuan @ jakegsy, jake@jakegsy.com
 */
contract Registry is Ownable {

    struct Creator {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address proposer;
        address vestingBeneficiary;
        uint8 initialPercentage;
        uint256 vestingPeriodInWeeks;
        bool approved;
    }

    mapping(bytes32 => Creator) public rolodex;
    mapping(string => bytes32)  nameToIndex;
    mapping(string => bytes32)  symbolToIndex;

    event LogProposalSubmit(string name, string symbol, address proposer, bytes32 indexed hashIndex);
    event LogProposalApprove(string name, address indexed tokenAddress);

    /**
     * @dev Submit token proposal to be stored, only called by Owner, which is set to be the Manager contract
     * @param _name string Name of token
     * @param _symbol string Symbol of token
     * @param _decimals uint8 Decimals of token
     * @param _totalSupply uint256 Total Supply of token
     * @param _initialPercentage uint8 Initial Percentage of total supply to Vesting Beneficiary
     * @param _vestingPeriodInWeeks uint256 Number of weeks that the remaining of total supply will be linearly vested for
     * @param _vestingBeneficiary address Address of Vesting Beneficiary
     * @param _proposer address Address of Proposer of Token, also the msg.sender of function call in Manager contract
     * @return bytes32 It will return a hash index which is calculated as keccak256(_name, _symbol, _proposer)
     */
    function submitProposal(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint8 _initialPercentage,
        uint256 _vestingPeriodInWeeks,
        address _vestingBeneficiary,
        address _proposer
    )
    public
    onlyOwner
    returns (bytes32 hashIndex)
    {
        nameDoesNotExist(_name);
        symbolDoesNotExist(_symbol);
        hashIndex = keccak256(abi.encodePacked(_name, _symbol, _proposer));
        rolodex[hashIndex] = Creator({
            token : address(0),
            name : _name,
            symbol : _symbol,
            decimals : _decimals,
            totalSupply : _totalSupply,
            proposer : _proposer,
            vestingBeneficiary : _vestingBeneficiary,
            initialPercentage : _initialPercentage,
            vestingPeriodInWeeks : _vestingPeriodInWeeks,
            approved : false
        });
        emit LogProposalSubmit(_name, _symbol, msg.sender, hashIndex);
    }

    /**
     * @dev Approve token proposal, only called by Owner, which is set to be the Manager contract
     * @param _hashIndex bytes32 Hash Index of Token proposal
     * @param _token address Address of Token which has already been launched
     * @return bool Whether it has completed the function
     * @dev Notice that the only things that have changed from an approved proposal to one that is not
     * is simply the .token and .approved object variables.
     */
    function approveProposal(
        bytes32 _hashIndex,
        address _token
    )
    external
    onlyOwner
    returns (bool)
    {
        Creator memory c = rolodex[_hashIndex];
        nameDoesNotExist(c.name);
        symbolDoesNotExist(c.symbol);
        rolodex[_hashIndex].token = _token;
        rolodex[_hashIndex].approved = true;
        nameToIndex[c.name] = _hashIndex;
        symbolToIndex[c.symbol] = _hashIndex;
        emit LogProposalApprove(c.name, _token);
        return true;
    }

    //Getters

    function getIndexByName(
        string memory _name
        )
    public
    view
    returns (bytes32)
    {
        return nameToIndex[_name];
    }

    function getIndexSymbol(
        string memory _symbol
        )
    public
    view
    returns (bytes32)
    {
        return symbolToIndex[_symbol];
    }

    function getCreatorByIndex(
        bytes32 _hashIndex
    )
    external
    view
    returns (Creator memory)
    {
        return rolodex[_hashIndex];
    }



    //Assertive functions

    function nameDoesNotExist(string memory _name) internal view {
        require(nameToIndex[_name] == 0x0, "Name already exists");
    }

    function symbolDoesNotExist(string memory _name) internal view {
        require(symbolToIndex[_name] == 0x0, "Symbol already exists");
    }
}
