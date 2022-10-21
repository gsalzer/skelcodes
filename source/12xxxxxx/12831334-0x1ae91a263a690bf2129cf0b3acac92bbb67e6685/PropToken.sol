/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./Context.sol";

interface PropTokenHelpers {
    function freezeProperty(address prop) external;

    function unfreezeProperty(address prop) external;

    function isPropTokenFrozen(address property) external view returns (bool);

    function hasSystemAdminRights(address addr) external view returns (bool);

    function getLicencedIssuerFee() external view returns (uint256);

    function getBlocksquareFee() external view returns (uint256);

    function getCertifiedPartnerFee() external view returns (uint256);

    function getBlocksquareAddress() external view returns (address);

    function getDataProxy() external view returns (address);

    function canTransferPropTokensTo(address wallet, address property) external view returns (bool);

    function isCPAdminOfProperty(address user, address property) external view returns (bool);

    function getCPOfProperty(address prop) external view returns (address);

    function getSpecialWallet() external view returns (address);

    function getBasicInfo(address property) external view returns (string memory streetLocation, string memory geoLocation, uint256 propertyValuation, uint256 tokenValuation, string memory propertyValuationCurrency);

    function getPropertyInfo(address property, uint64 index) external view returns (string memory propertyType, string memory kadastralMunicipality, string memory parcelNumber, string memory ID, uint64 buildingPart);

    function getIPFS(address property) external view returns (string memory);

    function getOceanPointContract() external view returns (address);

    function canEditProperty(address wallet, address property) external view returns (bool);

    function isContractWhitelisted(address cont) external view returns (bool);
}

contract Owned is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/// @title Property Token
contract PropToken is ERC20, Owned {
    using SafeMath for uint256;

    uint256 internal _cap;

    address private _mintContract;
    address private _burnContract;
    address internal _propertyRegistry;

    bool private _canMint;

    modifier onlySystemAdmin {
        require(PropTokenHelpers(getDataAddress()).hasSystemAdminRights(msg.sender), "PropToken: You need to have system admin rights!");
        _;
    }

    modifier onlyPropManager {
        require(PropTokenHelpers(getDataAddress()).isCPAdminOfProperty(msg.sender, address(this)) || msg.sender == PropTokenHelpers(getDataAddress()).getCPOfProperty(address(this)),
            "PropToken: you don't have permission!");
        _;
    }

    constructor(string memory name, string memory symbol) internal ERC20(name, symbol) {
    }

    function changeLI(address newOwner) public onlySystemAdmin {
        _owner = newOwner;
    }

    /**
    * @dev Sends `amount` of token from caller address to `recipient`
    * @param recipient Address where we are sending to
    * @param amount Amount of tokens to send
    * @return bool Returns true if transfer was successful
    */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferWithFee(msg.sender, recipient, amount);
        return true;
    }

    /**
    * @dev Sends `amount` of token from `sender` to `recipient`
    * @param sender Address from which we send
    * @param recipient Address where we are sending to
    * @param amount Amount of tokens to send
    * @return bool Returns true if transfer was successful
    */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, allowance(sender, msg.sender).sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transferWithFee(sender, recipient, amount);
        return true;
    }

    /// @notice mint tokens for given wallets
    /// @param accounts Array of wallets
    /// @param amounts Amount of tokens to mint to each wallet
    function mint(address[] memory accounts, uint256[] memory amounts) public returns (bool) {
        require(_canMint, "PropToken: Minting is not enabled!");
        require(PropTokenHelpers(getDataAddress()).isCPAdminOfProperty(msg.sender, address(this)) || _mintContract == msg.sender, "PropToken: you don't have permission to mint");
        require(accounts.length == amounts.length, "PropToken: Arrays must be of same length!");
        for (uint256 i = 0; i < accounts.length; i++) {
            require(totalSupply().add(amounts[i]) <= _cap, "PropToken: cap exceeded");
            require(PropTokenHelpers(getDataAddress()).canTransferPropTokensTo(accounts[i], address(this)), "PropToken: Wallet is not whitelisted");
            _mint(accounts[i], amounts[i]);
        }
        return true;
    }

    /// @notice burn and mint at he same time
    /// @param from Address from which we burn
    /// @param to Address to which we mint
    /// @param amount Amount of tokens to burn and mint
    function burnAndMint(address from, address to, uint256 amount) public onlySystemAdmin returns (bool) {
        _burn(from, amount);
        _mint(to, amount);
        return true;
    }

    function contractBurn(address user, uint256 amount) public returns (bool) {
        require(msg.sender == _burnContract, "PropToken: Only burn contract can burn tokens from users!");
        _burn(user, amount);
        return true;
    }

    /// @notice You need permission to call this function
    function freezeToken() public onlyPropManager {
        PropTokenHelpers(getDataAddress()).freezeProperty(address(this));
    }


    /// @notice You need permission to call this function
    function unfreezeToken() public onlyPropManager {
        PropTokenHelpers(getDataAddress()).unfreezeProperty(address(this));
    }

    /// @notice set contract that is allowed to mint
    /// @param mintContract Address of contract that is allowed to mint
    function setMintContract(address mintContract) public onlyPropManager {
        require(PropTokenHelpers(getDataAddress()).isContractWhitelisted(mintContract), "PropToken: Contract is not whitelisted");
        _mintContract = mintContract;
    }

    /// @notice set contract that is allowed to burn
    /// @param burnContract Address of contract that is allowed to burn
    function setBurnContract(address burnContract) public onlyPropManager {
        require(PropTokenHelpers(getDataAddress()).isContractWhitelisted(burnContract), "PropToken: Contract is not whitelisted");
        _burnContract = burnContract;
    }

    /// @notice set this contract into minting mode
    function allowMint() public {
        require(PropTokenHelpers(getDataAddress()).isCPAdminOfProperty(msg.sender, address(this)), "PropToken: Only CP admin!");
        _canMint = true;
    }

    function _transferWithFee(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "PropToken: transfer from the zero address");
        require(recipient != address(0), "PropToken: transfer to the zero address");
        require(!PropTokenHelpers(getDataAddress()).isPropTokenFrozen(address(this)), "PropToken: Transactions are frozen");
        address blocksquare = PropTokenHelpers(getDataAddress()).getBlocksquareAddress();
        address cp = PropTokenHelpers(getDataAddress()).getCPOfProperty(address(this));

        if (PropTokenHelpers(getDataAddress()).hasSystemAdminRights(sender) || recipient == getOceanPointContract() || recipient == _burnContract) {
            _transfer(sender, recipient, amount);
        }
        else if (recipient == blocksquare || recipient == cp || recipient == owner()) {
            _transfer(sender, recipient, amount);
        }
        else {
            require(PropTokenHelpers(getDataAddress()).canTransferPropTokensTo(recipient, address(this)), "PropToken: Can't send tokens to!");
            if (sender == blocksquare || sender == cp || sender == owner()) {
                _transfer(sender, recipient, amount);
            }
            else {
                _fee(sender, recipient, amount, blocksquare, cp);
            }
        }
    }

    function _fee(address sender, address recipient, uint256 amount, address blocksquare, address cp) private {
        uint256 blocksquareFee = (amount.mul(PropTokenHelpers(getDataAddress()).getBlocksquareFee())).div(1000);
        uint256 liFee = (amount.mul(PropTokenHelpers(getDataAddress()).getLicencedIssuerFee())).div(1000);
        uint256 cpFee = (amount.mul(PropTokenHelpers(getDataAddress()).getCertifiedPartnerFee())).div(1000);

        uint256 together = blocksquareFee.add(liFee).add(cpFee);

        _transfer(sender, blocksquare, blocksquareFee);
        _transfer(sender, cp, cpFee);
        _transfer(sender, owner(), liFee);

        _transfer(sender, recipient, amount.sub(together));
    }

    function getDataAddress() internal view returns (address) {
        return PropTokenHelpers(_propertyRegistry).getDataProxy();
    }

    /// @notice gets maximum number of tokens that can be created
    function cap() public view returns (uint256) {
        return _cap;
    }

    /// @notice check if this property can be minted
    function canBeMinted() public view returns (bool) {
        return _canMint;
    }

    /// @notice retrieves address of contract that is allowed to mint
    function getMintContract() public view returns (address) {
        return _mintContract;
    }

    /// @notice retrieves address of contract that is allowed to burn
    function getBurnContract() public view returns (address) {
        return _burnContract;
    }

    /// @notice retrieves ocean point contract address
    function getOceanPointContract() public view returns (address) {
        return PropTokenHelpers(getDataAddress()).getOceanPointContract();
    }
}

