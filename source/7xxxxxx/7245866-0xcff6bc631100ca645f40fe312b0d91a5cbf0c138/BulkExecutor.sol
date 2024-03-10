pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/// @title Enum - Collection of enums
/// @author Richard Meissner - <richard@gnosis.pm>
contract Enum {
    enum Operation {
        Call,
        DelegateCall,
        Create
    }
}

interface MMInterface {
    function split(
        address tokenAddress
    )
    external
    returns (bool);
}

interface SM {

    function isValidSubscription(
        bytes32 subscriptionHash,
        bytes calldata signatures
    ) external view returns (bool);

    function execSubscription (
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata meta,
        bytes calldata signatures) external returns (bool);

    function cancelSubscriptionAsRecipient(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata meta,
        bytes calldata signatures) external returns (bool);
}

contract BulkExecutor is Ownable {


    event SuccessSplit();

    function execute(
        address[] memory customers,
        address payable[] memory to,
        uint256[] memory value,
        bytes[] memory data,
        Enum.Operation[] memory operation,
        uint256[][3] memory gasInfo, //0 txgas 1dataGas 2 gasPrice
        address[] memory gasToken,
        address payable[] memory refundReceiver,
        bytes[][2] memory metaSig
    )
    public
    returns (
        uint256 i
    )
    {
        i = 0;

        while (i < customers.length) {
            if (SM(customers[i]).execSubscription(
                    to[i],
                    value[i],
                    data[i],
                    operation[i],
                    gasInfo[i][0], //txgas
                    gasInfo[i][1], //datagas
                    gasInfo[i][2], //gasPrice
                    gasToken[i],
                    refundReceiver[i],
                    metaSig[i][0], //meta
                    metaSig[i][1]  //sigs
                )
            ) {

                if (value[i] == uint(0)) {

                    address payable splitter;
                    bytes memory dataLocal = data[i];
                    // solium-disable-next-line security/no-inline-assembly
                    assembly {
                        splitter := div(mload(add(add(dataLocal, 0x20), 16)), 0x1000000000000000000000000)
                    }

                    if ((MMInterface(splitter).split(to[i]))) {
                        emit SuccessSplit();
                    }

                } else {
                    if (MMInterface(address(to[i])).split(address(0))) {
                        emit SuccessSplit();
                    }
                }
            }
            i++;
        }
    }
}
