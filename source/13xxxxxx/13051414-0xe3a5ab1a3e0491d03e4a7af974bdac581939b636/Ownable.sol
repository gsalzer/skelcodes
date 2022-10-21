// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "Context.sol";
import 'SafeMath.sol';

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
contract Ownable is Context {
    using SafeMath for uint256;
    address private _owner;
    address payable private _charityWalletAddress;
    address payable private _maintenanceWalletAddress;
    address payable private _liquidityWalletAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CharityAddressChanged(address oldAddress, address newAddress);
    event MaintenanceAddressChanged(address oldAddress, address newAddress);
    event LiquidityWalletAddressChanged(address oldAddress, address newAddress);
    event TimeLockChanged(uint256 previousValue, uint256 newValue);

    // set timelock
    enum Functions { excludeFromFee }
    uint256 public timelock = 0;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyUnlocked() {
        require(timelock <= block.timestamp, "Function is timelocked");
        _;
    }

    //lock timelock
    function increaseTimeLockBy(uint256 _time) public onlyOwner onlyUnlocked {
        uint256 _previousValue = timelock;
        timelock = block.timestamp.add(_time);
        emit TimeLockChanged(_previousValue ,timelock);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function lockDue() public view returns (uint256) {
        return timelock;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function updateOwner(address newOwner) internal onlyOwner() onlyUnlocked() {
        _owner = newOwner;
    }
    
    function charity() public view returns (address payable)
    {
        return _charityWalletAddress;
    }

    function maintenance() public view returns (address payable)
    {
        return _maintenanceWalletAddress;
    }

    function liquidityWallet() public view returns (address payable)
    {
        return _liquidityWalletAddress;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyCharity() {
        require(_charityWalletAddress == _msgSender(), "Caller is not the charity address");
        _;
    }

    modifier onlyMaintenance() {
        require(_maintenanceWalletAddress == _msgSender(), "Caller is not the maintenance address");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function excludeFromReward(address account) public virtual onlyOwner() onlyUnlocked() {
    }

    function excludeFromFee(address account) public virtual onlyOwner() onlyUnlocked(){
    }
    
    function setCharityAddress(address payable charityAddress) public virtual onlyOwner onlyUnlocked()
    {
        //require(_charity == address(0), "Charity address cannot be changed once set");
        emit CharityAddressChanged(_charityWalletAddress, charityAddress);
        _charityWalletAddress = charityAddress;
        excludeFromReward(charityAddress);
        excludeFromFee(charityAddress);
    }

    function setMaintenanceAddress(address payable maintenanceAddress) public virtual onlyOwner onlyUnlocked()
    {
        //require(_maintenance == address(0), "Maintenance address cannot be changed once set");
        emit MaintenanceAddressChanged(_maintenanceWalletAddress, maintenanceAddress);
        _maintenanceWalletAddress = maintenanceAddress;
        excludeFromReward(maintenanceAddress);
        excludeFromFee(maintenanceAddress);
    }

    function setLiquidityWalletAddress(address payable liquidityWalletAddress) public virtual onlyOwner onlyUnlocked()
    {
        //require(_maintenance == address(0), "Liquidity address cannot be changed once set");
        emit LiquidityWalletAddressChanged(_liquidityWalletAddress, liquidityWalletAddress);
        _liquidityWalletAddress = liquidityWalletAddress;
        excludeFromReward(liquidityWalletAddress);
        excludeFromFee(liquidityWalletAddress);
    }

}
