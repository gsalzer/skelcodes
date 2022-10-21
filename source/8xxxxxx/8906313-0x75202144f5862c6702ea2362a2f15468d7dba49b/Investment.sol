/**
 *Submitted for verification at Etherscan.io on 2019-09-16
*/

pragma solidity ^0.5.7;

// File: contracts/Ownable/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/KYC/IKYC.sol

/// @title IKYC
/// @notice This contract represents interface for KYC contract
contract IKYC {
    // Fired after the status for a manager is updated
    event ManagerStatusUpdated(address KYCManager, bool managerStatus);

    // Fired after the status for a user is updated
    event UserStatusUpdated(address user, bool status);

    /// @notice Sets status for a manager
    /// @param KYCManager The address of manager for which the status is to be updated
    /// @param managerStatus The status for the manager
    /// @return status of the transaction
    function setKYCManagerStatus(address KYCManager, bool managerStatus)
        public
        returns (bool);

    /// @notice Sets status for a user
    /// @param userAddress The address of user for which the status is to be updated
    /// @param passedKYC The status for the user
    /// @return status of the transaction
    function setUserAddressStatus(address userAddress, bool passedKYC)
        public
        returns (bool);

    /// @notice returns the status of a user
    /// @param userAddress The address of user for which the status is to be returned
    /// @return status of the user
    function getAddressStatus(address userAddress) public view returns (bool);

}

// File: contracts/Properties/IProperties.sol

/**
@title IProperties
@dev This contract represents properties contract interface */
contract IProperties {
    /**
    @notice fired when owner is changed
     */
    event OwnerChanged(address newOwner);

    /**
    @notice fired when a manager's status is set
     */
    event ManagerSet(address manager, bool status);

    /**
    @notice fired when a new property is created
     */
    event PropertyCreated(
        uint256 propertyId,
        uint256 allocationCapacity,
        string title,
        string location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT,
        uint256 dateAdded
    );

    /**
    @notice fired when the status of a property is updated
     */
    event PropertyStatusUpdated(uint256 propertyId, uint256 status);

    /**
    @notice fired when a property is invested in
     */
    event PropertyInvested(uint256 propertyId, uint256 tokens);

    /**
    @dev fired when investment contract's status is set
    */
    event InvestmentContractStatusSet(address investmentContract, bool status);

    /**
    @dev fired when a property is updated
    s */
    event PropertyUpdated(uint256 propertyId);

    /**
    @dev function to change the owner
    @param newOwner the address of new owner
     */
    function changeOwner(address newOwner) external;

    /**
    @dev function to set the status of manager
    @param manager address of manager
    @param status the status to set
     */
    function setManager(address manager, bool status) external;

    /**
    @dev function to create a new property
    @param  allocationCapacity refers to the number of ATs allocated to a property
    @param title title of property
    @param location location of property
    @param marketValue market value of property in USD
    @param maxInvestedATperInvestor absolute amount of shares that could be allocated per person
    @param totalAllowedATinvestments absolute amount of shares to be issued
    @param AT address of AT contract
    */
    function createProperty(
        uint256 allocationCapacity,
        string memory title,
        string memory location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT
    ) public returns (bool);

    /**
    @notice function is called to update a property's status
    @param propertyId ID of the property
    @param status status of the property
     */
    function updatePropertyStatus(uint256 propertyId, uint256 status) external;

    /**
    @notice function is called to invest in the property
    @param investor the address of the investor
    @param propertyId the ID of the property to invest in
    @param shares the amount of shares being invested
     */
    function invest(address investor, uint256 propertyId, uint256 shares)
        public
        returns (bool);

    /**
    @dev this function is called to set the status of an investment contract
    @param investmentContract the address of investment contract
    @param status status of the investment smart contact
     */
    function setInvestmentContractStatus(
        address investmentContract,
        bool status
    ) external;

    /**
    @notice the function returns the paramters of a property
    @param propertyId the ID of the property to get
     */
    function getProperty(uint256 propertyId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint8
        );

    /**
    @notice function returns the list of property investors
    @param from the starting number . minimum = 0
    @param to the ending number
     */
    function getPropertyInvestors(uint256 propertyId, uint256 from, uint256 to)
        public
        view
        returns (address[] memory);

    /**
    @notice Called to get the total amount of investment and investment for a specific holder for a property
    @param propertyId The ID of the property
    @param holder The address of the holder
    @return The total amount of investment
    @return The amount of shares owned by the holder */
    function getTotalAndHolderShares(uint256 propertyId, address holder)
        public
        view
        returns (uint256 totalShares, uint256 holderShares);
}

// File: contracts/AllocationToken/IAllocationToken.sol

/**
@title IAllocationToken
@notice This contract provides an interface for AllocationToken
 */
contract IAllocationToken {
    /**
    @dev fired on exchange contract's updation
    @param exchangeContract the address of exchange contract
     */
    event ExchangeContractUpdated(address exchangeContract);

    /**
    @dev fired on investment contract's updation
    @param investmentContract the address of investment contract
     */
    event InvestmentContractUpdated(address investmentContract);

    /**
    @dev updates exchange contract's address
    @param _exchangeContract the address of updated exchange contract
     */
    function updateExchangeContract(address _exchangeContract) external;

    /**
    @dev updates the investment contract's address
    @param _investmentContract the address of updated innvestment contract
     */
    function updateInvestmentContract(address _investmentContract) external;

    /**
    @notice Allows to mint new AT tokens
    @dev Only owner or exchange contract can call this function
    @param _holder The address to mint the tokens to
    @param _tokens The amount of tokens to mint
     */
    function mint(address _holder, uint256 _tokens) public;

    /**
    @notice Allows to burn AT tokens
    @dev Only Investment contract contract can call this function
    @param _address The address to burn the tokens from
    @param _value The amount of tokens to burn
    */
    function burn(address _address, uint256 _value) public;
}

// File: contracts/Investment/IInvestment.sol

/**
@title IInvestment
@dev This contract is an interface for Investment contract
 */
contract IInvestment {
    /**
    @dev fired on investment state change
    */
    event StateChanged(uint256 state);

    /**
    @dev fired when user invests
     */
    event Invested(
        uint256 propertyId,
        address investor,
        address tokenAddress,
        uint256 tokens
    );

    /**
    @dev fired when property is set by owner
     */
    event PropertySet(address property);

    /**
    @dev fired when the premium status of a use is changed
     */
    event PremiumStatusOfUserChanged(address user, bool status);

    /**
    @dev fired when allocation token state is changed
     */
    event AllocationTokenStateChanged(address allocationToken, bool state);

    /**
    @notice it invests allocation tokens to buy property
    @param propertyId ID of the property to make investment into
    @param tokenAddress address of the token using which the investment is made
    @param tokens the amount of tokens to invest
     */
    function invest(uint256 propertyId, address tokenAddress, uint256 tokens)
        external;

    /**
    @notice this function sets/changes state of this smart contract and owner can call it
    @param state it can be either 0 (Inactive) or 1 (Active)
     */
    function setState(uint256 state) external;

    /**
    @notice is called by owner to set property address
    @param _property it is the address of the property
     */
    function setProperty(IProperties _property) external;

    /**
    @notice is called by owner to change the allocation token state
    @param _token it is the address of the allocation token
    @param _state it is the state of the allocation token
     */

    /**
    @notice is called by owner to change the allocation token state
    @param _token it is the address of the allocation token
    @param _state it is the state of the allocation token
    @param _isPremium sets true if the set is premium
     */
    function setAllocationTokenState(
        address _token,
        bool _state,
        bool _isPremium
    ) external;

    /**
    @notice It changes premium status of a user
    @param user The address of the user
    @param status The premium status of the user */
    function changePremiumStatusOfUser(address user, bool status) public;

}

// File: contracts/Investment/Investment.sol

/**
@notice Investment smart contract for Chelle app
 */
contract Investment is IInvestment, Ownable {
    enum State {INACTIVE, ACTIVE}

    struct AllocationToken {
        bool state;
        bool isPremium;
    }

    mapping(address => AllocationToken) public allocationTokens; //addresses of ERC-20, that could be invested through this contract.
    mapping(address => bool) public premiumUsers;
    IProperties public property; // address of Real Estate Properties ERC721 Contract.
    IKYC public kyc;

    State investmentState; //current state of contract to indicate is it allowed to invest AT tokens through this contract.

    /**
    @notice constructor of investment contract
     */
    constructor(IKYC _kyc) public {
        investmentState = State.ACTIVE;
        kyc = _kyc;
        emit StateChanged(uint256(investmentState));
    }

    /**
    @notice call is only allowed to pass when investment contract is in ACTIVE state
     */
    modifier isStateActive() {
        require(
            investmentState == State.ACTIVE,
            "Investment contract's state is INACTIVE."
        );
        _;
    }

    /**
    @notice validates the contract state
     */
    modifier validateContract(address tokenAddress) {
        require(address(property) != address(0), "property is not set.");
        require(
            allocationTokens[tokenAddress].state,
            "token is not a part of allocation tokens."
        );
        _;
    }

    /**
    @notice It changes premium status of a user
    @param user The address of the user
    @param status The premium status of the user */
    function changePremiumStatusOfUser(address user, bool status)
        public
        onlyOwner
    {
        require(user != address(0), "Provide a valid user address.");
        require(
            premiumUsers[user] != status,
            "The provided status is already set."
        );

        premiumUsers[user] = status;
        emit PremiumStatusOfUserChanged(user, status);
    }
    /**
    @notice it invests allocation tokens to buy property
    @param propertyId ID of the property to make investment into
    @param tokenAddress address of the token using which the investment is made
    @param tokens the amount of tokens to invest
     */
    function invest(uint256 propertyId, address tokenAddress, uint256 tokens)
        external
        isStateActive
        validateContract(tokenAddress)
    {
        require(propertyId > 0, "propertyId should be greater than zero");
        require(tokens > 0, "investment tokens should be greater than zero");

        require(
            kyc.getAddressStatus(msg.sender),
            "msg.sender is not whiteliisted in KYC"
        );

        if (allocationTokens[tokenAddress].isPremium) {
            require(
                premiumUsers[msg.sender],
                "Only premium users can invest in the property"
            );
        } else {
            require(
                !premiumUsers[msg.sender],
                "Only basic users can invest in the property"
            );
        }

        IAllocationToken allocationToken = IAllocationToken(tokenAddress);

        allocationToken.burn(msg.sender, tokens);

        (, , , , , , , address ATToken, , uint8 propertyStatus) = property
            .getProperty(propertyId);

        require(ATToken == tokenAddress, "ATTokens do not match");
        require(propertyStatus == 0, "property is not investable");

        // call invest function on the property contract
        property.invest(msg.sender, propertyId, tokens);
        emit Invested(propertyId, msg.sender, tokenAddress, tokens);
    }

    /**
    @notice this function sets/changes state of this smart contract and owner can call it
    @param state it can be either 0 (Inactive) or 1 (Active)
     */
    function setState(uint256 state) external onlyOwner {
        require(state == 0 || state == 1, "Provided state is invalid.");
        require(
            state != uint256(investmentState),
            "Provided state is already set."
        );

        investmentState = State(state);
        emit StateChanged(uint256(investmentState));
    }

    /**
    @notice is called by owner to set property address
    @param _property it is the address of the property
     */
    function setProperty(IProperties _property) external onlyOwner {
        require(
            address(_property) != address(0),
            "property address must be a valid address."
        );
        property = _property;

        emit PropertySet(address(property));
    }

    /**
    @dev fired when allocation token state is changed
     */
    event AllocationTokenStateChanged(address allocationToken, bool state);

    /**
    @notice is called by owner to change the allocation token state
    @param _token it is the address of the allocation token
    @param _state it is the state of the allocation token
    @param _isPremium sets true if the set is premium
     */
    function setAllocationTokenState(
        address _token,
        bool _state,
        bool _isPremium
    ) external onlyOwner {
        require(
            _token != address(0),
            "allocation token address must be a valid address."
        );
        require(
            allocationTokens[_token].state != _state,
            "this state is already set for the provided allocation token."
        );

        allocationTokens[_token].state = _state;
        allocationTokens[_token].isPremium = _isPremium;

        emit AllocationTokenStateChanged(_token, _state);
    }
}
