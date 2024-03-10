// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

// TODO: 
// replace https://github.com/jointerinc/jointer-token/blob/0c91e462b2efd61e1541b6f6c5de27d4e6ea53fc/contracts/Auction/Auction.sol#L911-L916
// with approve Escrow contract to transfer and call depositFee(uint256 value) in Escrow contract.

// After deploy and setup tokenContract and gatewayContract addresses need to change the Owner address to the GovernanceProxy (Escrowed) address.
import "./Ownable.sol";
import "./EnumerableSet.sol";

// The GovernanceProxy contract address should be the Owner of other contracts which setting we will change.
interface IGovernanceProxy {
    function governance() external returns(address);    // Voting contract address
}

interface IGovernance {
    function addPremintedWallet(address wallet) external returns(bool);
}

interface  IGateway {
    function getChannelsNumber() external view returns(uint256);
}

interface IERC20Token {
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

interface IAuctionLiquidity {
    function redemptionFromEscrow(address[] calldata _path, uint256 _amount, address payable _sender) external returns (bool);
}

interface ISmartSwapP2P {
    function sendTokenFormEscrow(address token, uint amount, address payable sender) external; 
}

interface IAuctionRegistery {
    function getAddressOf(bytes32 _contractName) external view returns (address payable);
}

interface ICurrencyPrices {
    function getCurrencyPrice(address _which) external view returns (uint256);
}

contract AuctionRegistery is Ownable {
    bytes32 internal constant SMART_SWAP_P2P = "SMART_SWAP_P2P";
    bytes32 internal constant LIQUIDITY = "LIQUIDITY";
    bytes32 internal constant CURRENCY = "CURRENCY";
    IAuctionRegistery public contractsRegistry;
    IAuctionLiquidity public liquidityContract;
    ISmartSwapP2P public smartswapContract;
    ICurrencyPrices public currencyPricesContract;

    function updateRegistery(address _address) external onlyOwner returns (bool)
    {
        require(_address != address(0),"Zero address");
        contractsRegistry = IAuctionRegistery(_address);
        _updateAddresses();
        return true;
    }

    function getAddressOf(bytes32 _contractName)
        internal
        view
        returns (address payable)
    {
        return contractsRegistry.getAddressOf(_contractName);
    }

    /**@dev updates all the address from the registry contract
    this decision was made to save gas that occurs from calling an external view function */

    function _updateAddresses() internal {
        liquidityContract = IAuctionLiquidity(getAddressOf(LIQUIDITY));
        smartswapContract = ISmartSwapP2P(getAddressOf(SMART_SWAP_P2P));
        currencyPricesContract = ICurrencyPrices(getAddressOf(CURRENCY));
    }

     function updateAddresses() external returns (bool) {
        _updateAddresses();
        return true;
    }
}

contract Escrow is AuctionRegistery {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant DECIMAL_NOMINATOR = 10**18;
    uint256 internal constant BUYBACK = 1 << 251;
    uint256 internal constant SMARTSWAP_P2P = 1 << 252;
    IERC20Token public tokenContract;
    address public governanceContract;  // public Governance contract address
    address payable public companyWallet;
    address payable public gatewayContract;

    struct Order {
        address payable seller;
        address payable buyer;
        uint256 sellValue;  // how many token sell
        address wantToken;  // which token want to receive
        uint256 wantValue;  // the value want to receive
        uint256 status;     // 1 - created, 2 - completed; 3 - canceled; 4 -restricted
        address confirmatory;   // the address third person who confirm transaction, if order is restricted.
    }

    Order[] orders;
    
    struct Unpaid {
        uint256 soldValue;
        uint256 value;
    }

    struct Group {
        uint256 rate;
        EnumerableSet.AddressSet wallets;
        uint256 restriction;    // bitmap, where 1 allows to use that channel (1 << channel ID)
        mapping(uint256 => uint256) onSale; // total amount of tokens on sale in group by channel (Channel => Value)
        mapping(uint256 => uint256) soldUnpaid; // total amount of sold tokens but still not spitted pro-rata in group by channel (Channel => Value)
        mapping(uint256 => EnumerableSet.AddressSet) addressesOnChannel;   // list of address on the Liquidity channel
        mapping(uint256 => mapping(address => Unpaid)) unpaid;  // ETH / ERC20 tokens ready to split pro-rata (ETH = address(0))
    }

    // Groups ID: 0 - Company, 1 - Investors with goal, 2 - Main group, 3 - Restricted
    Group[] groups;
    mapping(address => uint256) public inGroup;   // Wallet to Group mapping. 0 - wallet not added, 1+ - group id (1-based)
    // Liquidity Channel ID: 0 - Company 1 - SmartSwap P2C, 2 - Secondary Market (Crypto Exchanges)
    mapping(uint256 => uint256) public totalOnSale;     // total token amount on sale by channel
    mapping(address => mapping(uint256 => uint256)) public onSale;  // How many tokens the wallet want to sell (Wallet => Channel => Value)
    mapping(address => uint256) public goals;   // The amount in USD (decimals = 9), that investor should receive before splitting liquidity with others members

    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => uint256) balancesETH;    // In case ETH sands failed, user can withdraw ETH using withdraw function

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferGateway(address indexed to, uint256 indexed channelId, uint256 value);
    event GroupRate(uint256 indexed groupId, uint256 rate);
    event PutOnSale(address indexed from, uint256 value);
    event RemoveFromSale(address indexed from, uint256 value);
    event PaymentFromGateway(uint256 indexed channelId, address indexed token, uint256 value, uint256 soldValue);
    event SellOrder(address indexed seller, address indexed buyer, uint256 value, address wantToken, uint256 wantValue, uint256 indexed orderId);
    event RestrictedOrder(address indexed seller, address indexed buyer, uint256 value, address wantToken, uint256 wantValue, uint256 indexed orderId, address confirmatory);
    event ReceivedETH(address indexed from, uint256 value);

    /**
     * @dev Throws if called by any account other than the companyWallet.
     */
    modifier onlyCompany() {
        require(companyWallet == msg.sender,"Not Company");
        _;
    }

    /**
     * @dev Throws if called by any account other than the gatewayContract.
     */
    modifier onlyGateway() {
        require(gatewayContract == msg.sender,"Not Gateway");
        _;
    }

    constructor(address payable _companyWallet) public {
        _nonZeroAddress(_companyWallet);
        companyWallet = _companyWallet;
        // Groups rete: Company = 100%, Investors = 0%, Main = 0%, Restricted = 0%
        uint256[4] memory groupRate = [uint256(100),0,0,0];
        for (uint i = 0; i < 4; i++) {
            groups.push();
            groups[i].rate = groupRate[i];
        }
        groups[0].restriction = 1; // allow company to use Gateway supply channel (0)
        orders.push();  // order ID starts from 1. Zero order ID means - no order
    }

    // Safe Math subtract function
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    // Safe Math add function
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Set token contract address.
     * @param newAddress The address of token contract.
     */
    function setTokenContract(IERC20Token newAddress) external onlyOwner {
        require(newAddress != IERC20Token(0) && tokenContract == IERC20Token(0),"Change address not allowed");
        tokenContract = newAddress;
    }

    /**
     * @dev Set gateway contract address
     * @param newAddress The address of gateway contract.
     */
    function setGatewayContract(address payable newAddress) external onlyOwner {
        _nonZeroAddress(newAddress);
        gatewayContract = newAddress;
    }

    /**
     * @dev Set governance (the main governance for public communities) contract address.
     * Uses to add addresses of escrowed (pre-minted) wallets to the isInEscrow list in Governance contract.
     * @param newAddress The address of governance contract.
     */
    function setGovernanceContract(address payable newAddress) external onlyOwner {
        _nonZeroAddress(newAddress);
        governanceContract = newAddress;
    }

    function updateCompanyAddress(address payable newAddress) external onlyCompany {
        require(inGroup[newAddress] == 0, "Wallet already added");
        _nonZeroAddress(newAddress);
        balances[newAddress] = balances[companyWallet];
        groups[0].wallets.remove(companyWallet);    // remove from company group
        inGroup[companyWallet] = 0;
        balances[companyWallet] = 0;
        // request number of channels from Gateway
        uint channels = _getChannelsNumber();
        for (uint i = 0; i < channels; i++) {   // exclude channel 0. It allow company to wire tokens for Gateway supply
            if (onSale[companyWallet][i] > 0) {
                onSale[newAddress][i] = onSale[companyWallet][i];
                onSale[companyWallet][i] = 0;
                groups[0].addressesOnChannel[i].add(newAddress);
                groups[0].addressesOnChannel[i].remove(companyWallet);
            }
        }
        _addPremintedWallet(newAddress, 0); // add company wallet to the company group.
        companyWallet = newAddress;
    }


    /**
     * @dev Add all pre-minted tokens to the company wallet.
     */
    function init() external onlyOwner {
        require(inGroup[companyWallet] == 0, "Already init");
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "No pre-minted tokens");
        balances[companyWallet] = balance; //Transfer all pre-minted tokens to company wallet.
        _addPremintedWallet(companyWallet, 0); // add company wallet to the company group.
        totalSupply = safeAdd(totalSupply, balance);
        emit Transfer(address(0), companyWallet, balance);
    }

    function setGroupRestriction(uint256 groupId, uint256 restriction) external onlyOwner {
        groups[groupId].restriction = restriction;
    }

    /**
     * @dev Get details of selected group
     * @param groupId The group ID.
     * @return rate The rate of group.
     * @return membersNumber The number of members in group.
     * @return restriction The bitmap, where 1 allows to use that channel (1 << channel ID)
     */
    function getGroupDetails(uint256 groupId) external view returns(uint256 rate, uint256 membersNumber, uint256 restriction) {
        return (groups[groupId].rate, groups[groupId].wallets.length(), groups[groupId].restriction);
    }

    function getGroupsNumber() external view returns(uint256 number) {
        return groups.length;
    }

    /**
     * @dev Get members of selected group
     * @param groupId The group ID.
     * @return wallets The list of addresses.
     */
    function getGroupMembers(uint256 groupId) external view returns(address[] memory wallets) {
        return groups[groupId].wallets._values;
    }
    
    // Move user from one group to another
    function moveToGroup(address wallet, uint256 toGroup) external onlyOwner {
        require(goals[wallet] == 0, "Wallet with goal can't be moved");
        _moveToGroup(wallet, toGroup, false);
    }

    function addGroup(uint256 rate) external onlyOwner {
        uint256 groupId = groups.length;
        groups.push();
        groups[groupId].rate = rate;
        emit GroupRate(groupId, rate);
    }

    function changeGroupRate(uint256 groupId, uint256 rate) external onlyOwner {
        groups[groupId].rate = rate;
        emit GroupRate(groupId, rate);
    }

    /**
     * @dev Get list of addresses in the group on the selected Liquidity Channel
     * @param groupId The group ID.
     * @param channelId Liquidity Channel ID.
     * @return wallets The list of addresses.
     */
    function getAddressesOnChannel(uint256 groupId, uint256 channelId) external view returns(address[] memory wallets) {
        return groups[groupId].addressesOnChannel[channelId]._values;
    }

    /**
     * @dev Create new wallet in Escrow contract
     * @param newWallet The wallet address
     * @param groupId The group ID. Wallet with goal can be added only in group 1
     * @param value The amount of token transfer from company wallet to created wallet
     * @param goal The amount in USD, that investor should receive before splitting liquidity with others members
     * @return true when if wallet created.
     */
    function createWallet(address newWallet, uint256 groupId, uint256 value, uint256 goal) external onlyCompany returns(bool){
        require(inGroup[newWallet] == 0, "Wallet already added");
        if (goal != 0) {
            require(groupId == 1, "Wallet with goal disallowed");
            goals[newWallet] = goal;
        }
        _addPremintedWallet(newWallet, groupId);
        return _transfer(newWallet, value);
    }

    /**
     * @dev Deposit fee from Auction contract and add it to the Company wallet.
     * @param value The fee value.
     */
    function depositFee(uint256 value) external {
        require(tokenContract.transferFrom(msg.sender, address(this), value),"Transfer failed");
        balances[companyWallet] = safeAdd(balances[companyWallet], value);
        totalSupply = safeAdd(totalSupply, value);
        emit Transfer(msg.sender, address(this), value);
    }
    
    /**
     * @dev transfer token for a specified address into Escrow contract
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(inGroup[to] != 0, "Wallet not added");
        uint256 groupId = _getGroupId(msg.sender);
        require(groups[groupId].restriction != 0,"Group is restricted");
        return _transfer(to, value);
    }

    /**
     * @dev transfer token for a specified address into Escrow contract from restricted group
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @param confirmatory The address of third party who have to confirm this transfer
     */
    function transferRestricted(address to, uint256 value, address confirmatory) external {
        _nonZeroAddress(confirmatory);
        require(inGroup[to] != 0, "Wallet not added");
        require(msg.sender != confirmatory && to != confirmatory, "Wrong confirmatory address");
        _restrictedOrder(value, address(0), 0, payable(to), confirmatory);   // Create restricted order where wantValue = 0.
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _who The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    // Redeem via BuyBack if allowed
    function redemption(address[] calldata path, uint256 value) external {
        require(balances[msg.sender] >= value, "Not enough balance");
        uint256 groupId = _getGroupId(msg.sender);
        require(groups[groupId].restriction & BUYBACK > 0, "BuyBack disallowed");
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        tokenContract.approve(address(liquidityContract), value);
        totalSupply = safeSub(totalSupply, value);
        require(liquidityContract.redemptionFromEscrow(path, value, msg.sender), "Redemption failed");
    }

    // Send token to SmartSwap P2P
    function samartswapP2P(uint256 value) external {
        require(balances[msg.sender] >= value, "Not enough balance");
        uint256 groupId = _getGroupId(msg.sender);
        require(groups[groupId].restriction & SMARTSWAP_P2P > 0, "SmartSwap P2P disallowed");
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        tokenContract.approve(address(smartswapContract), value);
        smartswapContract.sendTokenFormEscrow(address(tokenContract), value, msg.sender);
    }

    // Receive token from SmartSwap P2P in case order canceled. Called from SmartSwap P2P contract
    function canceledP2P(address user, uint256 value) external returns(bool) {
        require(tokenContract.transferFrom(msg.sender, address(this), value),"Cancel P2P failed");
        balances[user] = safeAdd(balances[user], value);
        totalSupply = safeAdd(totalSupply, value);
        return true;
    }

    // Sell tokens to other user (inside Escrow contract).
    function sellToken(uint256 sellValue, address wantToken, uint256 wantValue, address payable buyer) external {
        require(sellValue > 0, "Zero sell value");
        require(balances[msg.sender] >= sellValue, "Not enough balance");
        require(inGroup[buyer] != 0, "Wallet not added");        
        uint256 groupId = _getGroupId(msg.sender);
        require(groups[groupId].restriction != 0,"Group is restricted");
        balances[msg.sender] = safeSub(balances[msg.sender], sellValue);
        uint256 orderId = orders.length;
        orders.push(Order(msg.sender, buyer, sellValue, wantToken, wantValue, 1, address(0)));
        emit SellOrder(msg.sender, buyer, sellValue, wantToken, wantValue, orderId);
    }

    // Sell tokens to other user (inside Escrow contract) from restricted group.
    function sellTokenRestricted(uint256 sellValue, address wantToken, uint256 wantValue, address payable buyer, address confirmatory) external {
        _nonZeroAddress(confirmatory);
        require(inGroup[buyer] != 0, "Wallet not added");
        require(balances[msg.sender] >= sellValue, "Not enough balance");
        require(msg.sender != confirmatory && buyer != confirmatory, "Wrong confirmatory address");
        _restrictedOrder(sellValue, wantToken, wantValue, buyer, confirmatory);
    }


    // confirm restricted order by third-party confirmatory address
    function confirmOrder(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(o.confirmatory == msg.sender, "Not a confirmatory");
        if (o.wantValue == 0) { // if it's simple transfer, complete it immediately.
            balances[o.buyer] = safeAdd(balances[o.buyer], o.sellValue);
            o.status = 2;   // complete
        }
        else {
            o.status = 1;   // remove restriction
        }
    }

    // cancel sell order
    function cancelOrder(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(msg.sender == o.seller || msg.sender == o.buyer, "You can't cancel");
        require(o.status == 1 || o.status == 4, "Wrong order"); // user can cancel restricted order too.
        balances[o.seller] = safeAdd(balances[o.seller], o.sellValue);
        o.status = 3;   // cancel
    }

    // get order info. Status 1 - created, 2 - completed, 3 - canceled.
    function getOrder(uint256 orderId) external view returns(
        address seller,
        address buyer,
        uint256 sellValue,
        address wantToken,
        uint256 wantValue,
        uint256 status,
        address confirmatory)
    {
        Order storage o = orders[orderId];
        return (o.seller, o.buyer, o.sellValue, o.wantToken, o.wantValue, o.status, o.confirmatory);
    }

    // get total number of orders
    function getOrdersNumber() external view returns(uint256 number) {
        return orders.length;
    }

    // get the last order ID where msg.sender is buyer or seller.
    function getLastAvailableOrder() external view returns(uint256 orderId)
    {
        uint len = orders.length;
        while(len > 0) {
            len--;
            Order storage o = orders[len];
            if (o.status == 1 && (o.seller == msg.sender || o.buyer == msg.sender)) {
                return len;
            }
        }
        return 0; // No orders available
    }

    // get the last order ID where msg.sender is confirmatory address.
    function getLastOrderToConfirm() external view returns(uint256 orderId) {
        uint len = orders.length;
        while(len > 0) {
            len--;
            Order storage o = orders[len];
            if (o.status == 4 && o.confirmatory == msg.sender) {
                return len;
            }
        }
        return 0;
    }

    // buy selected order (ID). If buy using ERC20 token, the amount should be approved for Escrow contract.
    function buyOrder(uint256 orderId) external payable {
        require(inGroup[msg.sender] != 0, "Wallet not added");
        Order storage o = orders[orderId];
        require(msg.sender == o.buyer, "Wrong buyer");
        require(o.status == 1, "Wrong order status");
        if (o.wantValue > 0) {
            if (o.wantToken == address(0)) {
                require(msg.value == o.wantValue, "Wrong value");
                o.seller.transfer(msg.value);
            }
            else {
                require(IERC20Token(o.wantToken).transferFrom(msg.sender, o.seller, o.wantValue), "Not enough value");
            }
        }
        balances[msg.sender] = safeAdd(balances[msg.sender], o.sellValue);
        o.status = 2;   // complete
    }

    // Put token on sale on selected channel
    function putOnSale(uint256 value, uint256 channelId) external {
        require(balances[msg.sender] >= value, "Not enough balance");
        uint256 groupId = _getGroupId(msg.sender);
        require(groups[groupId].restriction & (1 << channelId) > 0, "Liquidity channel disallowed");
        require(groups[groupId].soldUnpaid[channelId] == 0, "There is unpaid giveaways");
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        groups[groupId].addressesOnChannel[channelId].add(msg.sender);  // the case that wallet already in list, checks in add function
        onSale[msg.sender][channelId] = safeAdd(onSale[msg.sender][channelId], value);
        totalOnSale[channelId] = safeAdd(totalOnSale[channelId], value);
        groups[groupId].onSale[channelId] = safeAdd(groups[groupId].onSale[channelId], value);
        emit PutOnSale(msg.sender, value);
    }

    // Remove token form sale on selected channel if it was not transferred to the Gateway.
    function removeFromSale(uint256 value, uint256 channelId) external {
        //if amount on sale less then requested, then remove entire amount.
        if (onSale[msg.sender][channelId] < value) {
            value = onSale[msg.sender][channelId];
        }
        require(totalOnSale[channelId] >= value, "Not enough on sale");
        uint groupId = _getGroupId(msg.sender);
        require(groups[groupId].soldUnpaid[channelId] == 0, "There is unpaid giveaways");
        onSale[msg.sender][channelId] = safeSub(onSale[msg.sender][channelId], value);
        totalOnSale[channelId] = safeSub(totalOnSale[channelId], value);
        balances[msg.sender] = safeAdd(balances[msg.sender], value);
        totalSupply = safeAdd(totalSupply, value);
        groups[groupId].onSale[channelId] = safeSub(groups[groupId].onSale[channelId], value);

        if (onSale[msg.sender][channelId] == 0) {
            groups[groupId].addressesOnChannel[channelId].remove(msg.sender);
        }
        emit RemoveFromSale(msg.sender, value);
    }

    // Transfer token to gateway from selected channel
    function transferToGateway(uint256 value, uint256 channelId) external onlyGateway returns(uint256 send){
        send = value;
        if(totalOnSale[channelId] < value)
            send = totalOnSale[channelId];
        totalOnSale[channelId] = safeSub(totalOnSale[channelId], send);
        tokenContract.approve(gatewayContract, send);
        emit TransferGateway(gatewayContract, channelId, send);
    }

    // Gateway transfer token to Escrow and call this function
    function transferFromGateway(uint256 value, uint256 channelId) external onlyGateway {
        totalOnSale[channelId] = safeAdd(totalOnSale[channelId], value);
        emit TransferGateway(address(this), channelId, value);
    }

    /**
     * @dev Receive ETH from Gateway
     * @param channelId Liquidity channel ID which sold tokens.
     * @param token The ERC20 token address which was sens by Gateway (in case ETH the token = address(0)).
     * @param value Amount of sent tokens
     * @param soldValue Amount of token that was sold
     */
    function paymentFromGateway(uint256 channelId, address token, uint256 value, uint256 soldValue) external payable onlyGateway {
        uint256 len = groups.length;
        uint256[] memory groupPart = new uint256[](len);
        uint256[] memory groupOnSale = new uint256[](len);
        bool[] memory groupHasOnSale = new bool[](len);
        uint256[] memory groupRate = new uint256[](len);
        uint256 totalRateNew;
        uint256 restNew = soldValue;

        for (uint i = 0; i < len; i++) {
            groupOnSale[i] = safeSub(groups[i].onSale[channelId], groups[i].soldUnpaid[channelId]);
            if (groupOnSale[i] > 0) {
                groupHasOnSale[i] = true;
                groupRate[i] = groups[i].rate;
                totalRateNew += groupRate[i];
            }
        }
        
        uint256 part;
        // Split by groups
        while (restNew > 0) {
        //for (uint k = 0; k<n; k++) {
            uint256 restValue = restNew;
            uint256 totalRate = totalRateNew;
            for (uint i = 0; i < len; i++) {
                if (groupHasOnSale[i]) {
                    if (restNew < len) part = restNew; // if rest value less then calculation error use it all
                    else part = (restValue*groupRate[i]/totalRate);
                    groupPart[i] += part;
                    if (groupPart[i] > groupOnSale[i]) {
                        part = part - (groupPart[i]-groupOnSale[i]);    // part that rest
                        groupPart[i] = groupOnSale[i];
                        groupHasOnSale[i] = false; // group on-sale fulfilled
                        totalRateNew = totalRate - groupRate[i];
                    }
                    restNew -= part;
                }
            }
        }

        for (uint i = 0; i < len; i++) {
            if (groupOnSale[i] > 0) {
                groups[i].soldUnpaid[channelId] += groupPart[i];    // total sold tokens and unpaid (unsplit) by channel
                groups[i].unpaid[channelId][token].soldValue += groupPart[i]; // sold tokens by payment tokens and channel
                groups[i].unpaid[channelId][token].value += (groupPart[i] * value / soldValue); //unpaid tokens by channel 
            }
        }
        emit PaymentFromGateway(channelId, token, value, soldValue);
    }

    // return list of groups with unpaid token amount
    function getUnpaidGroups(uint256 channelId) external view returns (uint256[] memory unpaidSold){
        uint256 len = groups.length;
        unpaidSold = new uint256[](len);
        for (uint i = 0; i<len; i++) {
            unpaidSold[i] = groups[i].soldUnpaid[channelId];
        }
    }

    // Use this function to avoid OUT_OF_GAS. Gas per user about 60.000
    function splitProrata(uint256 channelId, address token, uint256 groupId) external {
        if (groupId == 1) _splitForGoals(channelId, token, groupId);    // split among Investors with goal 
        else _splitProrata(channelId, token, groupId);
    }

    // Split giveaways in each groups among participants pro-rata their orders amount.
    // May throw with OUT_OF_GAS is there are too many participants.
    function splitProrataAll(uint256 channelId, address token) external {
        uint256 len = groups.length;
        for (uint i = 0; i < len; i++) {
            if (i == 1) _splitForGoals(channelId, token, i);    // split among Investors with goal 
            else _splitProrata(channelId, token, i);
        }
    }

    // require to avoid 'stack too deep' compiler error
    struct SplitValues {
        uint256 soldValue;
        uint256 value;
        uint256 total;
        uint256 soldRest;
        uint256 valueRest;
        uint256 userPart;
        uint256 userValue;
    }

    // Gas per user about 60.000
    function _splitProrata(uint256 channelId, address token, uint256 groupId) internal {
        Group storage g = groups[groupId];
        SplitValues memory v;
        v.soldValue = g.unpaid[channelId][token].soldValue;
        if (v.soldValue == 0) return; // no unpaid tokens
        v.value = g.unpaid[channelId][token].value;
        v.total = g.onSale[channelId];
        if (v.total == 0) return; // no tokens onSale

        g.onSale[channelId] = safeSub(v.total, v.soldValue);
        g.soldUnpaid[channelId] = safeSub(g.soldUnpaid[channelId], v.soldValue);
        delete g.unpaid[channelId][token].value;
        delete g.unpaid[channelId][token].soldValue;

        EnumerableSet.AddressSet storage sellers = g.addressesOnChannel[channelId];

        v.soldRest = v.soldValue;
        v.valueRest = v.value;
        while (v.soldRest != 0 ) {
            uint256 addrNum = sellers.length();
            uint256 divider = v.total * addrNum * 2;
            uint256 j = addrNum;
            while (j != 0 && v.soldRest != 0) {
                j--;
                address payable user = payable(sellers.at(j));
                uint256 amount = onSale[user][channelId];
                if (v.soldRest < 10000) v.userPart = v.soldRest;    // very small value
                else v.userPart = v.soldValue * (amount * addrNum + v.total) / divider;
                if (v.userPart >= amount) {
                    v.userPart = amount;
                    sellers.remove(user);
                }
                v.soldRest = safeSub(v.soldRest, v.userPart);
                onSale[user][channelId] = safeSub(amount, v.userPart);
                // get return amount in target ETH / ERC20
                if (v.soldRest != 0) v.userValue = v.userPart * v.value / v.soldValue;
                else v.userValue = v.valueRest; // If all tokens split send the rest value
                v.valueRest = safeSub(v.valueRest, v.userValue);
                if (token == address(0)) {
                    if (!user.send(v.userValue))
                        balancesETH[user] = v.userValue;
                }
                else {
                    IERC20Token(token).transfer(user, v.userValue);
                }
            }
            v.total = v.total + v.soldRest - v.soldValue;
            v.soldValue = v.soldRest;
            v.value = v.valueRest;
        }
    }

    function _splitForGoals(uint256 channelId, address token, uint256 groupId) internal {
        Group storage g = groups[groupId];
        SplitValues memory v;
        v.soldValue = g.unpaid[channelId][token].soldValue;
        if (v.soldValue == 0) return; // no unpaid tokens
        v.value = g.unpaid[channelId][token].value;
        v.total = g.onSale[channelId];
        if (v.total == 0) return; // no tokens onSale

        EnumerableSet.AddressSet storage sellers = g.addressesOnChannel[channelId];
        uint256 addrNum = sellers.length();
        // split among members with the goals
        uint256 price = currencyPricesContract.getCurrencyPrice(token);

        v.soldRest = v.soldValue;
        uint256 j = addrNum;
        while (j != 0) {
            j--;
            address payable user = payable(sellers.at(j));
            uint256 amount = onSale[user][channelId];

            if (j == 0) v.userPart = v.soldRest;    // the last member get the rest
            else v.userPart = v.soldValue * amount / v.total;
            if (v.userPart >= amount) {
                v.userPart = amount;
            }
            v.soldRest = safeSub(v.soldRest, v.userPart);
            onSale[user][channelId] = safeSub(amount, v.userPart);

            v.userValue = v.userPart * v.value / v.soldValue;
            uint256 userValueUSD = v.userValue * price / DECIMAL_NOMINATOR;
            if (userValueUSD >= goals[user]) {
                goals[user] = 0;
                _moveToGroup(user, 2, true);  // move user with fulfilled goal to the Main group (2).
            }
            else {
                goals[user] = goals[user] - userValueUSD;
            }
            // transfer userValue to user
            if (token == address(0)) {
                if (!user.send(v.userValue))
                    balancesETH[user] = v.userValue;
            }
            else {
                IERC20Token(token).transfer(user, v.userValue);
            }
        }
        g.onSale[channelId] = safeSub(v.total + v.soldRest, v.soldValue);
        g.soldUnpaid[channelId] = safeSub(g.soldUnpaid[channelId], v.soldValue);
        delete g.unpaid[channelId][token].value;
        delete g.unpaid[channelId][token].soldValue;
    }

    // Withdraw ETH in case sending failed
    function withdraw() external {
        require(balancesETH[msg.sender] > 0, "No ETH");
        msg.sender.transfer(balancesETH[msg.sender]);
    }

    // Move user from one group to another
    function _moveToGroup(address wallet, uint256 toGroup, bool allowUnpaid) internal {
        uint256 from = _getGroupId(wallet);
        require(from != toGroup, "Already in this group");
        inGroup[wallet] = toGroup + 1;  // change wallet's group id (1-based)
        // add to group wallets list
        groups[toGroup].wallets.add(wallet);
        // delete from previous group
        groups[from].wallets.remove(wallet);
        // recalculate groups OnSale
        // request number of channels from Gateway
        uint channels = _getChannelsNumber();
        for (uint i = 1; i < channels; i++) {   // exclude channel 0. It allow company to wire tokens for Gateway supply
            if (onSale[wallet][i] > 0) {
                require(groups[from].soldUnpaid[i] == 0 || allowUnpaid, "There is unpaid giveaways");
                groups[from].onSale[i] = safeSub(groups[from].onSale[i], onSale[wallet][i]);
                groups[toGroup].onSale[i] = safeAdd(groups[toGroup].onSale[i], onSale[wallet][i]);
                groups[from].addressesOnChannel[i].remove(wallet);
                groups[toGroup].addressesOnChannel[i].add(wallet);
            }
        }
    }

    /**
     * @dev transfer token for a specified address into Escrow contract
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address to, uint256 value) internal returns (bool) {
        _nonZeroAddress(to);
        require(balances[msg.sender] >= value, "Not enough balance");
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // Create restricted order which require confirmation from third-party confirmatory address. For simple transfer the wantValue = 0.
    function _restrictedOrder(uint256 sellValue, address wantToken, uint256 wantValue, address payable buyer, address confirmatory) internal {
        require(sellValue > 0, "Zero sell value");
        balances[msg.sender] = safeSub(balances[msg.sender], sellValue);
        uint256 orderId = orders.length;
        orders.push(Order(msg.sender, buyer, sellValue, wantToken, wantValue, 4, confirmatory));  //add restricted order
        emit RestrictedOrder(msg.sender, buyer, sellValue, wantToken, wantValue, orderId, confirmatory);
    }
    function _getGroupId(address wallet) internal view returns(uint256 groupId) {
        groupId = inGroup[wallet];
        require(groupId > 0, "Wallet not added");
        groupId--;  // from 1-based to 0-based index
    }

    /**
     * @dev Add wallet that received pre-minted tokens to the list in the Governance contract.
     * The contract owner should be GovernanceProxy contract.
     * This Escrow contract address should be added to Governance contract (setEscrowContract).
     * @param wallet The address of wallet.
     */
    function _addPremintedWallet(address wallet, uint256 groupId) internal {
        require(groupId < groups.length, "Wrong group");
        IGovernance(governanceContract).addPremintedWallet(wallet);
        inGroup[wallet] = groupId + 1;    // groupId + 1 (0 - mean that wallet not added)
        groups[groupId].wallets.add(wallet);  // add to the group
    }

    function _getChannelsNumber() internal view returns (uint256 channelsNumber) {
        return IGateway(gatewayContract).getChannelsNumber();
    }

    function _nonZeroAddress(address addr) internal pure {
        require(addr != address(0), "Zero address");
    }

    // accept ETH
    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }
}
