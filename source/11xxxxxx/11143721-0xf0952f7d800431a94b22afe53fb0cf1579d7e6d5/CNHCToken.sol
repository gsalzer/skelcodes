// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./Context.sol";
import "./Pausable.sol";
import "./BlackList.sol";
import "./Votable.sol";
import "./UpgradedStandardToken.sol";
import "./ERC20WithFee.sol";

contract CNHCToken is ERC20WithFee, BlackList, Votable, Pausable {

    address public upgradedAddress;

    bool public deprecated;

    constructor(uint256 _initialSupply, uint8 _decimals) public ERC20WithFee("CNHC Token","CNHC") {
        _setupDecimals(_decimals);
        _mint(_msgSender(), _initialSupply);
    }

    event DestroyedBlackFunds(address indexed blackListedUser, uint balance);

    event Deprecate(address newAddress);
    
    // functions users can call
    // make compatible if deprecated
    function balanceOf(address account) public override view returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(account);
        } else {
            return super.balanceOf(account);
        }
    }

    function totalSupply() public override view returns (uint) {
        if (deprecated) {
            return IERC20(upgradedAddress).totalSupply();
        } else {
            return super.totalSupply();
        }
    }

    function allowance(address owner, address spender) public override view returns (uint remaining) {
        if (deprecated) {
            return IERC20(upgradedAddress).allowance(owner, spender);
        } else {
            return super.allowance(owner, spender);
        }
    }

    // Allow checks of balance at time of deprecation
    function oldBalanceOf(address account) public view returns (uint256) {
        require(deprecated, "CNHCToken: contract NOT deprecated");
        return super.balanceOf(account);
    }

    // normal functions
    function transfer(address recipient, uint256 amount) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(recipient), "BlackList: recipient address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(_msgSender(), recipient, amount);
        } else {
            return super.transfer(recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(sender), "BlackList: sender address is in blacklist");
        require(!isBlackListUser(recipient), "BlackList: recipient address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(_msgSender(), sender, recipient, amount);
        } else {
            return super.transferFrom(sender, recipient, amount);
        }
    }

    function approve(address spender, uint256 amount) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(spender), "BlackList: spender address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(_msgSender(), spender, amount);
        } else {
            return super.approve(spender, amount);
        }
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(spender), "BlackList: spender address is in blacklist");

        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).increaseApprovalByLegacy(_msgSender(), spender, addedValue);
        } else {
            return super.increaseAllowance(spender, addedValue);
        }
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public override isNotBlackUser(_msgSender()) returns (bool) {
        require(!isBlackListUser(spender), "BlackList: spender address is in blacklist");
        
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).decreaseApprovalByLegacy(_msgSender(), spender, subtractedValue);
        } else {
            return super.decreaseAllowance(spender, subtractedValue);
        }
    }

    function burn(uint256 amount) public {
        require(!deprecated, "CNHCToken: contract was deprecated");
        super._burn(_msgSender(), amount);
    }

    // functions only owner can call
    // open proposals
    function openMintProposal(address _account, uint256 _amount) external onlyOwner{
        _openProposal(abi.encodeWithSignature("mint(address,uint256)", _account, _amount));
    }

    function openDestroyBlackFundsProposal(address _user) external onlyOwner{
        _openProposal(abi.encodeWithSignature("destroyBlackFunds(address)", _user));
    }

    // onlySelf: mint & burn
    function mint(address _account, uint256 _amount) public onlySelf {
        require(!deprecated, "CNHCToken: contract was deprecated");
        super._mint(_account, _amount);
    }

    function destroyBlackFunds(address _user) public onlySelf {
        require(!deprecated, "CNHCToken: contract was deprecated");
        require(isBlackListUser(_user), "BlackList: only fund in blacklist address can be destroy");
        uint dirtyFunds = balanceOf(_user);
        super._burn(_user, dirtyFunds);
        emit DestroyedBlackFunds(_user, dirtyFunds);
    }

    // pause
    function pause() public onlyOwner {
        require(!deprecated, "CNHCToken: contract was deprecated");
        super._pause();
    }

    function unpause() public onlyOwner {
        require(!deprecated, "CNHCToken: contract was deprecated");
        super._unpause();
    }

    // deprecate
    function deprecate(address _upgradedAddress) public onlyOwner {
        require(!deprecated, "CNHCToken: contract was deprecated");
        require(_upgradedAddress != address(0));
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    // hook before _transfer()/_mint()/_burn()
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Pausable: token transfer while paused");
    }
}
