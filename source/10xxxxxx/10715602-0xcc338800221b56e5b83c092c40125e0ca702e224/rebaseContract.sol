pragma solidity >=0.4.0 <0.7.0;

import "./Truample.sol";

interface IOracle {

    function getData() external returns (uint256, bool);
    
}


contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init(address owner_) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(owner_);
    }

    function __Ownable_init_unchained(address owner_) internal initializer {
        //address msgSender = _msgSender();
        _owner = owner_;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {
    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        require(a <= MAX_INT256);
        return int256(a);
    }
}


contract rebaseContract is OwnableUpgradeSafe {

    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    uint256 DECIMALS = 18;

    // More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    IOracle public marketOracle;
    Truample public tokenContractAddress;
    
    //oracle contracts will be disabled till token is listed on exchanges 
    bool public oracleContractActivation; 

    uint256 private manualOracleData;
    uint256 public lastOracleCallTime;
    uint256 public oracelWindowValidUpto;
    bool public lastCallRebaseManual;
    
    struct RebaseLog {
        uint256 epoch;
        uint256 newOracleData;
        int256 oraclePriceDelta;
        int256 targetPriceDelta;
        uint256 newTargetPrice;
        int256 supplyDelta;
        uint256 newSupply;
        uint256 multiple;
    }

    uint256 public epoch;
    uint256 public rebaseLag;
    mapping(uint256 => RebaseLog) public rebaseLog;

    /**
     * @notice Initializes the Contract.
     *
     * @param _owner is address of owner of contract.
     * @param _initialTargetPrice is initial target price of Token. It is of type uint256.
     * @param _initialSupply is initial supply of ERC20 toke.
     *
     * @dev All timing parameters are initialized here.
     *      minRebaseTimeIntervalSec = 1 day i.e minimum time between two rebases is atleast 1 day.
     *      lastRebaseTimestampSec = 0, Since Contract is initilized here, it is equal to zero. It stores timestamp of last rebase.
     *
     * @dev This function also initializes rebaseLog[epoch] at epoch = 0.
     *
     *
     */
    function initilize(
        address _owner,
        uint256 _initialTargetPrice,
        uint256 _initialSupply,
        Truample _tokenAddress
        
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init(_owner);
        epoch = 0;
        rebaseLag = 10;
        
        minRebaseTimeIntervalSec = 1 days;
        lastRebaseTimestampSec = 0;
        oracelWindowValidUpto = 15 minutes;
        tokenContractAddress = _tokenAddress;
        oracleContractActivation = false;
        lastOracleCallTime = 0;
        
        rebaseLog[epoch].newTargetPrice = _initialTargetPrice.mul(10**18);
        rebaseLog[epoch].newOracleData = _initialTargetPrice.mul(10**18);
        rebaseLog[epoch].newSupply = _initialSupply;
        rebaseLog[epoch].multiple = _initialTargetPrice;
    }

    /**
     * @notice This is rebase function. Here all time constraints are checked and supplyDelta is computed.     *
     */

    function rebase() public onlyOwner{

        require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now, 'to hurry to call rebase');

        uint256 _newOracledata;
        bool value;

        if (oracleContractActivation) {
             
            (_newOracledata, value) = marketOracle.getData();
            require(value);
            lastCallRebaseManual = true;

        }else {

            require(now < lastOracleCallTime.add(oracelWindowValidUpto), 'oracle window is valid upto 15 minutes after price feed');                    
            require(manualOracleData != 0,'oracle data is zero');
           _newOracledata = manualOracleData;
            lastCallRebaseManual = false;            
            
        }

        int256 supplyDeltaToSend = computeSupplyDelta(epoch, _newOracledata);
        require(tokenContractAddress.rebase(epoch,supplyDeltaToSend));
        lastRebaseTimestampSec = now;
        epoch += 1;

    }

    /**
     * @notice This is the main function where supply delta is calculated.
     * 
     * @dev This function should have internal visibility and should be called only from
     *      rebase(). 
     *      The method for calculation of supply delta is as folllows :-
     * 
     */
    function computeSupplyDelta(uint256 _epoch, uint256 _newOracleData)
        internal
        returns (int256)
    {
        int256 oraclePriceDelta = _newOracleData.toInt256Safe().sub(
            rebaseLog[_epoch].newOracleData.toInt256Safe()
        );
    
        int256 targetPriceDelta = (oraclePriceDelta).div(2);
        int256 newTargetPrice;
        int256 targetToBeAdded;
        
        int256 multipleDifference = (_newOracleData.toInt256Safe().div(10**18)).sub(rebaseLog[_epoch].multiple.toInt256Safe());
        
        targetToBeAdded = multipleDifference.mul(500000000000000000);
        newTargetPrice = rebaseLog[_epoch].newTargetPrice.toInt256Safe().add(targetToBeAdded);
        

        int256 supplyDelta = (
            rebaseLog[_epoch].newSupply.toInt256Safe().mul(
                (_newOracleData.toInt256Safe().sub(newTargetPrice)).mul(100)
            )
        )
            .div(100);

        supplyDelta = supplyDelta.div(
            (rebaseLag.mul(10**DECIMALS)).toInt256Safe()
        );
        
        int256 newSupply = rebaseLog[_epoch].newSupply.toInt256Safe().add(
            supplyDelta
        );

        RebaseLog memory newLog;
        newLog.epoch = _epoch + 1;
        newLog.newOracleData = _newOracleData;
        newLog.oraclePriceDelta = oraclePriceDelta;
        newLog.targetPriceDelta = targetPriceDelta;
        newLog.newTargetPrice = uint256(newTargetPrice);
        newLog.supplyDelta = supplyDelta;
        newLog.newSupply = uint256(newSupply);
        newLog.multiple = _newOracleData.div(10**18);

        rebaseLog[epoch + 1] = newLog;
        return (supplyDelta);
    }

    /**
     * @notice This function is used to reset the timing parameters of contract
     */

    function setRebaseTimingParameters(
        uint256 minRebaseTimeIntervalSec_,
        uint256 _oracelWindowValidUpto

    ) external onlyOwner {

        require(minRebaseTimeIntervalSec_ > 0);
        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
        oracelWindowValidUpto = _oracelWindowValidUpto;

    }

    function setOracleContractAddress (IOracle _address) external onlyOwner returns (bool) {

        marketOracle = _address;
        return true;
        
    }

    function setOracleContractActivation (bool _value) external onlyOwner returns (bool) {

        oracleContractActivation = _value;
        return oracleContractActivation;
        
    }

    function setRebasemanually (uint256 _oracleData) external onlyOwner returns (uint256) {
        
        manualOracleData = _oracleData;
        lastOracleCallTime = now;
    }

}
