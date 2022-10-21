// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.9;

import "./Ownable.sol";

interface IERC20Token {
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

interface IEscrow {
    function transferToGateway(uint256 value, uint256 channelId) external returns(uint256 send);
    function transferFromGateway(uint256 value, uint256 channelId) external;
    function paymentFromGateway(uint256 channelId, address token, uint256 value, uint256 soldValue) external payable;
}

contract SafeMath {
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
}

contract ChannelContract is Ownable, SafeMath {
    struct Wallet {
        string name;
        address wallet;
        bool isBlocked;  // Block wallet transfer tokens to.
    }

    Wallet[] wallets;   // list of wallets where allowed to transfer (exchanges wallets, Bancor, etc).
    uint256 public spent;   // Amount of token spend from channel (sent to Market, SmartSwap, etc.)
    uint256 public received; // Amount of token received from Escrow

    string public channelName;
    IERC20Token public tokenContract;
    address payable public escrowContract;

    constructor(IERC20Token _tokenContract,  address payable _escrowContract, string memory _name) public {
        tokenContract = _tokenContract;
        escrowContract = _escrowContract;
        channelName = _name;
    }

    event SetWallet(address indexed channel, uint256 walletId, address wallet, string name);
    event BlockWallet(address indexed channel, uint256 walletId, bool isBlock);
    event TransferTokens(address indexed channel, address indexed to, uint256 value, string walletName);
    event ReceivedETH(address indexed from, uint256 value);

    function totalSupply() public view returns(uint256) {
        return safeSub(received, spent);
    }

    function addWallet(string memory name, address wallet) external onlyOwner {
        require(wallet != address(0),"Zero address");
        uint256 walletId = wallets.length;
        wallets.push(Wallet(name, wallet, false));
        emit SetWallet(address(this), walletId, wallet, name);
    }

    // if wallet is address(0) - wallet removed.
    function updateWallet(uint256 walletId, address wallet) external onlyOwner {
        wallets[walletId].wallet = wallet;
        emit SetWallet(address(this), walletId, wallet, wallets[walletId].name);
    }

    // Block selected wallet transfer to.
    function blockWallet(uint256 walletId, bool isBlock) external onlyOwner {
        wallets[walletId].isBlocked = isBlock;
        emit BlockWallet(address(this), walletId, isBlock);
    }

    function getWalletsNumber() external view returns(uint256) {
        return wallets.length;
    }

    function getWalletInfo(uint256 walletId) external view returns(string memory name, address wallet, bool isBlocked) {
        name = wallets[walletId].name;
        wallet = wallets[walletId].wallet;
        isBlocked = wallets[walletId].isBlocked;
    }

    // Receive tokens from Escrow (gateway)
    function receiveTokens(uint256 value) external onlyOwner {
        received = safeAdd(received, value);
    }

    // transfer tokens to selected wallet (ex. Exchange wallet)
    function transferTokens(uint256 walletId, uint256 value) external onlyOwner {
        require(totalSupply() >= value, "Not enough tokens");
        address to = wallets[walletId].wallet;
        require(to != address(0), "Wallet removed");
        spent = safeAdd(spent, value); 
        tokenContract.transfer(to, value);
        emit TransferTokens(address(this), to, value, wallets[walletId].name);
    }


    // transfer tokens to selected wallet (ex. Exchange wallet)
    function approveTokens(uint256 walletId, uint256 value) external onlyOwner {
        require(totalSupply() >= value, "Not enough tokens");
        address to = wallets[walletId].wallet;
        require(to != address(0), "Wallet removed");
        spent = safeAdd(spent, value); 
        tokenContract.approve(to, value);
        emit TransferTokens(address(this), to, value, wallets[walletId].name);
    }

    /**
     * @dev Trigger arbitrary function on selected wallet address.
     * @param walletId The wallet to call
     * @param params encoded params
     */
    function trigger(uint256 walletId, bytes calldata params) external onlyOwner {
        address to = wallets[walletId].wallet;
        to.call(params);
    }

    // Gateway transfer token to Escrow
    function returnToEscrow(uint256 value) external onlyOwner {
        require(totalSupply() >= value, "Not enough tokens");
        received = safeSub(received, value);
        tokenContract.transfer(escrowContract, value);
    }

    /**
     * @dev Send giveaways (received ETH/ERC20) to Escrow for splitting among participants.
     * When token sold on exchange, withdraw ETH/ERC20 to this contract address.
     * @param soldTokenAmount amount of sold tokens
     * @param receivedToken The ERC20 token address (or 0 for ETH) for which tokens were sold.
     * @param receivedAmount Amount of ETH/ERC20 received for sold tokens.
     */
    function transferGiveaways(uint256 soldTokenAmount, address receivedToken, uint256 receivedAmount) external onlyOwner {
        require(spent >= soldTokenAmount, "Wrong Sold Token Amount");
        if (receivedToken == address(0)) {
            escrowContract.transfer(receivedAmount);
        }
        else {
            IERC20Token(receivedToken).transfer(escrowContract, receivedAmount);
        }
        spent = safeSub(spent, soldTokenAmount);
        received = safeSub(received, soldTokenAmount);
    }

    // accept ETH
    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }
}

contract Gateway is Ownable, SafeMath {
    IERC20Token public tokenContract;
    IEscrow public escrowContract;
    address public admin;
    address public jointerVoting;   //Jointer voting contract can block specific Channel or Wallet

    struct Channel {
        string name;    // name of channel
        bool isBlocked;  // Block entire channel to transfer tokens to any wallets.
        ChannelContract channel;    // address of ChannelContract
    }

    Channel[] channels;     // list of liquidity channels

    event AddChannel(uint256 indexed channelId, address indexed channelAddress, string name);
    event BlockChannel(uint256 indexed channelId, bool isBlock);

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin == msg.sender,"Not admin");
        _;
    }

    /**
     * @dev Set token contract address.
     * @param token The address of token contract.
     */
    function setTokenContract(IERC20Token token) external onlyOwner {
        require(token != IERC20Token(0) && tokenContract == IERC20Token(0),"Change address not allowed");
        tokenContract = token;
    }

    /**
     * @dev Set escrow contract address
     * @param escrow The address of escrow contract.
     */
    function setEscrowContract(address payable escrow) external onlyOwner {
        require(escrow != address(0),"Zero address");
        escrowContract = IEscrow(escrow);
    }

    /**
     * @dev Set Jointer Voting (Escrowed) contract address
     * @param newAddress The address of escrow contract.
     */
    function setJointerVotingContract(address payable newAddress) external onlyOwner {
        require(newAddress != address(0),"Zero address");
        jointerVoting = newAddress;
    }

    /**
     * @dev Set gateway admin address
     * @param _admin The address of gateway admin wallet.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0),"Zero address");
        admin = _admin;
    }

    // Add new Liquidity channel
    function addChannel(string memory name) external onlyOwner {
        uint256 channelId = channels.length;
        require(channelId < 251, "Channels limit reached");
        channels.push();
        channels[channelId].name = name;
        channels[channelId].channel = new ChannelContract(tokenContract, payable(address(escrowContract)), name);
        emit AddChannel(channelId, address(channels[channelId].channel), name);
    }

    function getChannelsNumber() external view returns(uint256) {
        return channels.length;
    }

    // Get details of channel
    function getChannelInfo(uint256 channelId) external view 
        returns(
            string memory name,
            address channelAddress,
            bool isBlocked,
            uint256 amount,
            uint256 spent,
            uint256 walletsNumber
        ) 
    {
        name = channels[channelId].name;
        channelAddress = address(channels[channelId].channel);
        isBlocked = channels[channelId].isBlocked;
        amount = channels[channelId].channel.received();
        spent = channels[channelId].channel.spent();
        walletsNumber = channels[channelId].channel.getWalletsNumber();
    }

    // Add new wallet to selected liquidity channel
    function addWallet(uint256 channelId, string memory name, address payable wallet) external onlyOwner {
        require(wallet != address(0),"Zero address");
        channels[channelId].channel.addWallet(name, wallet);
    }

    // Update wallet address on selected liquidity channel. If wallet is address(0) - wallet removed.
    function updateWallet(uint256 channelId, uint256 walletId, address payable wallet) external onlyOwner {
        channels[channelId].channel.updateWallet(walletId, wallet);
    }

    // In case updating gateway contract, we can change Channel Ownership to the new Gateway contract
    function transferChannelOwnership(uint256 channelId, address newOwner) external onlyOwner {
        channels[channelId].channel.transferOwnership(newOwner);
    }

    // Transfer token to gateway from selected channel
    function transferToGateway(uint256 value, uint256 channelId) external onlyAdmin {
        uint256 approved = escrowContract.transferToGateway(value, channelId);  // amount of approved tokens
        ChannelContract channel = channels[channelId].channel;
        require(tokenContract.transferFrom(address(escrowContract), address(channel), approved),"Transfer to Gateway channel Failed");
        channel.receiveTokens(approved);
    }

    // Gateway transfer token to Escrow from Channel
    function transferFromGateway(uint256 value, uint256 channelId) external onlyAdmin {
        channels[channelId].channel.returnToEscrow(value);
        escrowContract.transferFromGateway(value, channelId);
    }

    // Block selected wallet transfer to.
    function blockWallet(uint256 channelId, uint256 walletId, bool isBlock) external {
        require(msg.sender == jointerVoting, "Only JNTR voting allowed");
        channels[channelId].channel.blockWallet(walletId, isBlock);
    }

    // Block selected channel transfer to any wallet.
    function blockChannel(uint256 channelId, bool isBlock) external {
        require(msg.sender == jointerVoting, "Only JNTR voting allowed");
        channels[channelId].isBlocked = isBlock;
        emit BlockChannel(channelId, isBlock);
    }

    // transfer tokens from Channel to selected wallet (ex. Exchange wallet)
    function transferTokens(uint256 channelId, uint256 walletId, uint256 value) external onlyAdmin {
        channels[channelId].channel.transferTokens(walletId, value);
    }

    // approve tokens from Channel to selected wallet (ex. Exchange wallet)
    function approveTokens(uint256 channelId, uint256 walletId, uint256 value) external onlyAdmin {
        channels[channelId].channel.approveTokens(walletId, value);
    }

    /**
     * @dev Trigger arbitrary function on selected wallet address.
     * @param channelId The channel which have to call
     * @param walletId The wallet to call
     * @param params encoded params
     */
    function trigger(uint256 channelId, uint256 walletId, bytes calldata params) external onlyAdmin {
        channels[channelId].channel.trigger(walletId, params);
    }

    /**
     * @dev Send giveaways (received ETH/ERC20) to Escrow for splitting among participants.
     * When token sold on exchange, withdraw ETH/ERC20 to this contract address.
     * @param channelId Liquidity channel ID which sold tokens.
     * @param soldTokenAmount amount of sold tokens
     * @param receivedToken The ERC20 token address (or 0 for ETH) for which tokens were sold.
     * @param receivedAmount Amount of ETH/ERC20 received for sold tokens.
     */
    function transferGiveaways(uint256 channelId, uint256 soldTokenAmount, address receivedToken, uint256 receivedAmount) external onlyAdmin {
        channels[channelId].channel.transferGiveaways(soldTokenAmount, receivedToken, receivedAmount);
        escrowContract.paymentFromGateway(channelId, receivedToken, receivedAmount, soldTokenAmount);
    }
}

