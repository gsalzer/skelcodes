pragma solidity ^0.8.0;
import "./ILiquidityProtection.sol";

abstract contract UsingSmartStateProtection {

    bool internal protected = false;
    address internal pair;
    mapping(address => bool) public excludedBuy;
    mapping(address => bool) public excludedSell;
    mapping(address => bool) public excludedTransfer;

    function protectionService() internal view virtual returns(address);
    function isAdmin() internal view virtual returns(bool);
    function ps() internal view returns(ILiquidityProtection) {
        return ILiquidityProtection(protectionService());
    }
    
    function disableProtection() public {
        require(isAdmin());
        protected = false;
    }

    function enableProtection() public {
        require(isAdmin());
        protected = true;

    }

    function isProtected() public view returns(bool) {
        return protected;
    }

    function firstBlockProtectionEnabled() internal pure virtual returns(bool) {
        return false;
    }

    function blockProtectionEnabled() internal pure virtual returns(bool) {
        return false;
    }

    function blocksToProtect() internal pure virtual returns(uint) {
        return 69; //can't buy tokens for 7 blocks
    }

    function amountPercentProtectionEnabled() internal pure virtual returns(bool) {
        return false;
    }

    function amountPercentProtection() internal pure virtual returns(uint) {
        return 5; //can't buy more than 5 percent at once
    }

    function priceChangeProtectionEnabled() internal pure virtual returns(bool) {
        return false;
    }

    function priceProtectionPercent() internal pure virtual returns(uint) {
        return 5; //price can't change for more than 5 percent during 1 transaction
    }

    function rateLimitProtectionEnabled() internal pure virtual returns(bool) {
        return false;
    }

    function rateLimitProtection() internal pure virtual returns(uint) {
        return 60; //user can make only one transaction per minute
    }

    function IDOFactoryEnabled() internal pure virtual returns(bool) {
        return false;
    }

    function IDOFactoryBlocks() internal pure virtual returns(uint) {
        return 30; //blocks for ido factory
    }

    function IDOFactoryParts() internal pure virtual returns(uint) {
        return 3; //blocks should be devidable by parts
    }

    function blockSuspiciousAddresses() internal pure virtual returns(bool) {
        return false;
    }

    function blockAddress(address _address) external {
        require(isAdmin());
        ps().blockAddress(_address);

    }

    function blockAddresses(address[] memory _addresses) external {
        require(isAdmin());
        ps().blockAddresses(_addresses);
    }

    function unblockAddress(address _address) external {
        require(isAdmin());
        ps().unblockAddress(_address);
    }

    function unblockAddresses(address[] memory _addresses) external {
        require(isAdmin());
        ps().unblockAddresses(_addresses);
    }
    
    function excludeBuy(address[] memory _users) external {
        require(isAdmin());
        for (uint i = 0; i < _users.length; i ++) {
            excludedBuy[_users[i]] = true;
        }
    }
    
    function includeBuy(address[] memory _users) external {
        require(isAdmin());
        for (uint i = 0; i < _users.length; i ++) {
            excludedBuy[_users[i]] = false;
        }
    }
    
    function excludeSell(address[] memory _users) external {
        require(isAdmin());
        for (uint i = 0; i < _users.length; i ++) {
            excludedSell[_users[i]] = true;
        }
    }
    
    function includeSell(address[] memory _users) external {
        require(isAdmin());
        for (uint i = 0; i < _users.length; i ++) {
            excludedSell[_users[i]] = false;
        }
    }
    
    function excludeTransfer(address[] memory _users) external {
        require(isAdmin());
        for (uint i = 0; i < _users.length; i ++) {
            excludedTransfer[_users[i]] = true;
        }
    }
    
    function includeTransfer(address[] memory _users) external {
        require(isAdmin());
        for (uint i = 0; i < _users.length; i ++) {
            excludedTransfer[_users[i]] = false;
        }
    }
    
    function setPair(address _pair) internal {
        pair = _pair;
    }
    //main protection logic
    
    function protectionBeforeTokenTransfer(address _from, address _to, uint _amount) internal {
        if (protected && _from == pair && excludedBuy[_to]) {
            return;
        }
        if (protected && _to == pair && excludedSell[_from]) {
            return;
        }
        if (protected && _to != pair && _from != pair && excludedTransfer[_from]) {
            return;
        }
        if (protected) {
            require(!firstBlockProtectionEnabled() || !ps().verifyFirstBlock(), "First Block Protector");
            require(!blockProtectionEnabled() || !ps().verifyBlockNumber(), "Block Protector");
            require(!amountPercentProtectionEnabled() || !ps().verifyAmountPercent(_amount, priceProtectionPercent()), "Amount Protector");
            require(!priceChangeProtectionEnabled() || !ps().verifyPriceAffect(_from, _amount, priceProtectionPercent()), "Percent protector");
            require(!IDOFactoryEnabled() || !ps().updateIDOPartAmount(_from, _amount), "IDO protector");
            require(!rateLimitProtectionEnabled() || !ps().updateRateLimitProtector(_from, _to, rateLimitProtection()), "Rate limit protector");
            require(!blockSuspiciousAddresses() || !ps().verifyBlockedAddress(_from, _to), "Blocked address protector");
        }
    }
}
