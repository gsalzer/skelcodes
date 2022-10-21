
// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
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
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

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
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;


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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: contracts/Forwarder.sol

pragma solidity 0.5.12;



/**
 * @dev ERC20 interface
 */
interface ERC20 {
  function totalSupply() external view returns (uint supply);
  function balanceOf(address _owner) external view returns (uint balance);
  function transfer(address _to, uint _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function approve(address _spender, uint _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint remaining);
  function decimals() external view returns(uint digits);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @dev Chai interface
 */
interface IChai {
  function join(address dst, uint wad) external;
}

/**
 * @dev Kyber Network Interface
 */
interface IKyberNetworkProxy {
  function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
  function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);
  function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) external returns(uint);
}

contract Forwarder is Initializable, Ownable {

  /**
   * DEVELOPER NOTES
   *   - IMPORTANT: Contracts derived from {GSNRecipient} should never use
   *     `msg.sender`, and should use {_msgSender} instead. See comments here:
   *      https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L6
   */

  // =============================================================================================
  //                                    Storage Variables
  // =============================================================================================

  // Floatify server
  address public floatify;

  // Contract addresses and interfaces
  ERC20 public daiContract;
  IChai public chaiContract;
  IKyberNetworkProxy public knpContract;
  ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  // =============================================================================================
  //                                        Events
  // =============================================================================================

  /**
   * @dev Emitted when Chai is successfully minted from Dai held by the contract
   */
  event ChaiSent(uint256 indexed amountInDai);

  /**
   * @dev Emitted when Ether is swapped for Dai
   */
  event SwapEther(uint256 indexed amountInDai, uint256 indexed amountInEther);

  /**
   * @dev Emitted when a token is swapped for Dai
   */
  event SwapToken(uint256 indexed amountInDai, uint256 indexed amountInToken, address token);

  /**
   * @dev Emitted when saved addresses are updated
   */
  event FloatifyAddressChanged(address indexed previousAddress, address indexed newAddress);
  event DaiAddressChanged(address indexed previousAddress, address indexed newAddress);
  event ChaiAddressChanged(address indexed previousAddress, address indexed newAddress);
  event KyberAddressChanged(address indexed previousAddress, address indexed newAddress);


  // ===============================================================================================
  //                                      Constructor
  // ===============================================================================================

  /**
   * @notice Constructor, calls other constructors. Can only be called once
   * due to initializer modifier
   * @param _owner The user's account address
   * @param _floatify Floatify server address
   * @param _dai Dai contract address
   * @param _chai Chai server address
   * @param _kyber Kyber network proxy address
   */
  function initialize(
    address _owner,
    address _floatify,
    address _dai,
    address _chai,
    address _kyber
  ) public initializer {
    // Call constructors of contracts we inherit from
    Ownable.initialize(_owner);

    // Set Floatify address
    floatify = _floatify;

    // Set contract addresses and interfaces
    daiContract = ERC20(_dai);
    chaiContract = IChai(_chai);
    knpContract = IKyberNetworkProxy(_kyber);

    // Approve the Chai contract to spend our DAI balance
    approveChaiToSpendDai();
  }

  // ===============================================================================================
  //                                       Helpers
  // ===============================================================================================

  /**
   * @dev Throws if called by any account other than floatify
   */
  modifier onlyFloatify() {
    require(_msgSender() == floatify, "Forwarder: caller is not the floatify address");
    _;
  }


  /**
   * @notice Approve the Chai contract to spend our Dai
   */
  function approveChaiToSpendDai() private {
    bool result = daiContract.approve(address(chaiContract), uint256(-1));
    require(result, "Forwarder: failed to approve Chai contract to spend DAI");
  }


  /**
   * @notice Remove allowance of Chai contract to prevent it from spending Dai
   */
  function resetChaiAllowance() private {
    bool result = daiContract.approve(address(chaiContract), 0);
    require(result, "Forwarder: failed to remove allowance of Chai contract to spend DAI");
  }


  // ===============================================================================================
  //                                    Updating Addresses
  // ===============================================================================================

  /**
   * @dev Allows the floatify address to be changed
   * @param _newAddress new address
   */
  function updateFloatifyAddress(address _newAddress) public onlyFloatify {
    // Make sure only floatify can call this function
    require(_newAddress != address(0), "Forwarder: new floatify address is the zero address");
    // Update address
    emit FloatifyAddressChanged(floatify, _newAddress);
    floatify = _newAddress;
  }

  /**
   * @dev Allows the Dai contract address to be changed
   * @param _newAddress new address
   */
  function updateDaiAddress(address _newAddress) public onlyFloatify {
    // Reset allowance for old address to zero
    resetChaiAllowance();
    // Set new allowance
    emit DaiAddressChanged(address(daiContract), _newAddress);
    daiContract = ERC20(_newAddress);
    approveChaiToSpendDai();
  }

  /**
   * @dev Allows the Chai contract address to be changed
   * @param _newAddress new address
   */
  function updateChaiAddress(address _newAddress) public onlyFloatify {
    // Reset allowance for old address to zero
    resetChaiAllowance();
    // Set new allowance
    emit ChaiAddressChanged(address(chaiContract), _newAddress);
    chaiContract = IChai(_newAddress);
    approveChaiToSpendDai();
  }

  /**
   * @dev Allows the Kyber Proxy contract address to be changed
   * @param _newAddress new address
   */
  function updateKyberAddress(address _newAddress) public onlyFloatify {
    emit KyberAddressChanged(address(knpContract), _newAddress);
    knpContract = IKyberNetworkProxy(_newAddress);
  }


  // ===============================================================================================
  //                               Handling Received Ether/Tokens
  // ===============================================================================================

  /**
   * @notice Upon receiving Dai, use this function to convert it to Chai and send
   * it to the owner
   */
  function mintAndSendChai() public {
    // Get Dai balance of this contract
    uint256 _daiBalance = daiContract.balanceOf(address(this));
    // Mint and send Chai
    emit ChaiSent(_daiBalance);
    address _owner = owner();
    chaiContract.join(_owner, _daiBalance);
  }


  /**
   * @notice Upon receiving any other token, use this function to convert it to Dai
   * and send it to the owern
   */
  function convertAndSendToken(address _srcTokenAddress) public {
    // TODO convert token to Dai
    //   Use "Loose Token Conversion" as shown here
    //   https://developer.kyber.network/docs/DappsGuide/#scenario-1-loose-token-conversion

    // Get token parameters
    ERC20 _srcTokenContract = ERC20(_srcTokenAddress);
    uint256 _srcTokenBalance = _srcTokenContract.balanceOf(address(this));

    // Mitigate ERC20 Approve front-running attack, by initially setting allowance to 0
    require(_srcTokenContract.approve(address(knpContract), 0), "First approval failed");

    // Approve tokens so network can take them during the swap
    require(_srcTokenContract.approve(address(knpContract), _srcTokenBalance), "Second approval failed");

    // Use slippage rate as the minimum conversion rate
    uint256 minRate;
    (, minRate) = knpContract.getExpectedRate(_srcTokenContract, daiContract, _srcTokenBalance);

    // Swap the ERC20 token for Dai
    knpContract.swapTokenToToken(_srcTokenContract, _srcTokenBalance, daiContract, minRate);

    // Log the event
    uint256 daiBalance = daiContract.balanceOf(address(this));
    emit SwapToken(daiBalance, _srcTokenBalance, _srcTokenAddress);

    // Mint and send Chai
    mintAndSendChai();
  }


  /**
   * @notice Upon receiving Ether, convert it to Chai and send it to the owner
   */
  function() external payable {
    // TODO
    // handle slippage for larger transactions?
    //   https://developer.kyber.network/docs/Integrations-SlippageRateProtection/

    uint256 etherAmount = address(this).balance;

    // Use slippage rate as the minimum conversion rate
    uint256 minRate;
    (, minRate) = knpContract.getExpectedRate(ETH_TOKEN_ADDRESS, daiContract, msg.value);

    // Swap Ether for Dai, and receive back tokens to this contract's address
    knpContract.swapEtherToToken.value(msg.value)(daiContract, minRate);

    // Log the event
    uint256 daiBalance = daiContract.balanceOf(address(this));
    emit SwapEther(daiBalance, etherAmount);

    // Convert to Chai and send to owner
    mintAndSendChai();
  }
}

