pragma solidity 0.5.6;

import "./Whitelist.sol";

/// @author The Calystral Team
/// @title A subscriber contract
/// @notice A whitelist, which is maintained to grant extras to the community
contract WhitelistAdvanced {
    /// @dev Maps the subscriber index to an address
    mapping (uint256 => address) internal subscriberIndexToAddress;
    /// @dev Maps the subscriber address to the subscriber index or 0 if not subscriped.
    mapping (address => uint256) internal subscriberAddressToSubscribed;
    /// @dev Maps the subscriber address to the blocknumber of subscription or 0 if not subscriped.
    mapping (address => uint256) internal subscriberAddressToBlockNumber;

    /// @dev The legacy whitelist contract.
    Whitelist internal whitelistContract = Whitelist(0x6198149b79AFE8114dc07b46A01d94a6af304ED9);

    /// @dev Used to point towards the subscriber address. Caution: This will be likely unequal to the actual subscriber count. We start at 1 because 0 will be the indicator that an address is not a subscriber.
    uint256 internal subscriberIndex = 1;

    /** @dev Emits on successful subscription.
      * @param _subscriberAddress The address of the subscriber.
      */
    event OnSubscribed(address _subscriberAddress);
    /** @dev Emits on successful unsubscription.
      * @param _subscriberAddress The address of the unsubscriber.
      */
    event OnUnsubscribed(address _subscriberAddress);

    /// @notice This modifier prevents other smart contracts from subscribing.
    modifier isNotAContract(){
        require (msg.sender == tx.origin, "Contracts are not allowed to interact.");
        _;
    }
    
    /** @notice Creates the smart contract and initializes the whitelist.
      * @dev The constructor, which initializes the whitelist by scraping all the subscribers from the legacy contract. Legacy subscribers are initialized by the current block number.
      */
    constructor() public {
        address[] memory subscriberList = whitelistContract.getSubscriberList();
        for (uint256 i = 0; i < subscriberList.length; i++) {
            _subscribe(subscriberList[i]);
        }
    }

    /** @notice Calls the subscribe function if no specific function was called.
      * @dev Fallback function forwards to subscribe function.
      */
    function() external {
        subscribe();
    }

    /** @notice Shows the whole subscriber list.
      * @dev Returns all current subscribers as an address array.
      * @return A list of subscriber addresses.
      */
    function getSubscriberList() external view returns (address[] memory) {
        uint256 subscriberListCounter = 0;
        uint256 subscriberListCount = getSubscriberCount();        
        address[] memory subscriberList = new address[](subscriberListCount);
        
        for (uint256 i = 1; i < subscriberIndex; i++) {
            address subscriberAddress = subscriberIndexToAddress[i];
            if (isSubscriber(subscriberAddress) != 0) {
                subscriberList[subscriberListCounter] = subscriberAddress;
                subscriberListCounter++;
            }
        }

        return subscriberList;
    }

    /** @notice Shows the count of subscribers.
      * @dev Returns the subscriber count as an integer.
      * @return The count of subscribers.
      */
    function getSubscriberCount() public view returns (uint256) {
        uint256 subscriberListCount = 0;

        for (uint256 i = 1; i < subscriberIndex; i++) {
            address subscriberAddress = subscriberIndexToAddress[i];
            if (isSubscriber(subscriberAddress) != 0) {
                subscriberListCount++;
            }
        }

        return subscriberListCount;
    }

    /** @notice Any user can add him or herself to the subscriber list.
      * @dev Subscribes the message sender to the list. Other contracts are not allowed to subscribe.
      */
    function subscribe() public isNotAContract {
        _subscribe(msg.sender);
    }

    /** @dev This function is necessary, so it can be used by the constructor. Nobody should be able to add other people to the list.
      * @param _subscriber The user address, which should be added.
      */
    function _subscribe(address _subscriber) internal {
        require(isSubscriber(_subscriber) == 0, "You already subscribed.");
        
        subscriberAddressToSubscribed[_subscriber] = subscriberIndex;
        subscriberAddressToBlockNumber[_subscriber] = block.number;
        subscriberIndexToAddress[subscriberIndex] = _subscriber;
        subscriberIndex++;

        emit OnSubscribed(_subscriber);
    }

    /** @notice Any user can revoke his or her subscription.
      * @dev Deletes the index entry in the subscriberIndexToAddress mapping for the message sender.
      */
    function unsubscribe() external isNotAContract {
        require(isSubscriber(msg.sender) != 0, "You have not subscribed yet.");

        uint256 index = subscriberAddressToSubscribed[msg.sender];
        delete subscriberIndexToAddress[index];

        emit OnUnsubscribed(msg.sender);
    }
    
    /** @notice Checks wether a user is in the subscriber list.
      * @dev tx.origin is used instead of msg.sender so other contracts may forward a user request (e.g. limited rewards contract).
      * @return The blocknumber at which the user has subscribed or 0 if not subscribed at all.
      */
    function isSubscriber() external view returns (uint256) {
        return isSubscriber(tx.origin);
    }

    /** @notice Checks wheter the given address is in the subscriber list.
      * @dev This function isn't external since it's used by the contract as well.
      * @param _subscriberAddress The address to check for.
      * @return The blocknumber at which the user has subscribed or 0 if not subscribed at all.
      */
    function isSubscriber(address _subscriberAddress) public view returns (uint256) {
        if (subscriberIndexToAddress[subscriberAddressToSubscribed[_subscriberAddress]] != address(0)){
            return subscriberAddressToBlockNumber[_subscriberAddress];
        } else {
            return 0;
        }
    }
}
