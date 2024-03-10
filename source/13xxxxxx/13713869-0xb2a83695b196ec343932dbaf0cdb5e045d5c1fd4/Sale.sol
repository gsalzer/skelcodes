// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Sales contract for Etched NFTs
 * @author Linum Labs
 */

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ISale.sol";
import "./IRegistry.sol";

interface IEtchedNFT {
  function royaltyInfo(uint256 tokenId, uint256 _salePrice) external view returns(address, uint256);
  function balanceOf(address account, uint256 id) external view returns(uint256);
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
  function supportsInterface(bytes4 interfaceID) external returns(bool);
}

contract EtchedNFTSale is ISale, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Counters for Counters.Counter;

  // already declared in ISale

  // struct Sale {
  //   uint256 id; // id of sale
  //   address owner; // address of NFT owner
  //   address nftContract;
  //   uint256 tokenId;
  //   uint256 amount; // amount of NFTs being sold
  //   uint256 purchased; // amount of NFTs purchased
  //   uint256 startTime;
  //   uint256 endTime;
  //   uint256 price;
  //   uint256 maxBuyAmount;
  //   address currency; // use 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa for ETH
  // }

  // address alias for using ETH as a currency
  address constant ETH = address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa);

  Counters.Counter private _saleId;
  IRegistry private Registry;

  mapping(uint256 => Sale) private sales;
  mapping(uint256 => bool) private cancelled;
  mapping(uint256 => mapping(address => uint256)) private purchased;
  // user address => tokenAddress => amount
  mapping(address => mapping(address => uint256)) private claimableFunds;

  // already declared in ISale
  // event NewSale(uint256 indexed id, Sale indexed newSale);
  // event Purchase(
  //   uint256 saleId, 
  //   address purchaser, 
  //   address recipient, 
  //   uint256 quantity
  // );
  // event NFTsReclaimed(uint256 indexed id, address indexed owner, uint256 indexed amount);
  // event BalanceUpdated(
  //   address indexed accountOf, 
  //   address indexed tokenAddress, 
  //   uint256 indexed newBalance
  // );

  constructor(address registry) {
    Registry = IRegistry(registry);
  }

  /// @notice returns the details of a particular Sale
  /// @param saleId the index of the Sale to return the details of
  /// @return a Sale struct with the Sale details
  function getSaleDetails(uint256 saleId) external view returns(Sale memory) {
    require(saleId <= _saleId.current() && saleId > 0, "sale does not exist");
    return sales[saleId];
  }

  /// @notice returns the status of a particular Sale
  /// @dev possible statuses: PENDING, ACTIVE, ENDED, CANCELLED
  /// @param saleId the index of the Sale to return the status of
  /// @return an all-caps string of the status
  function getSaleStatus(uint256 saleId) public view override returns(string memory) {
    require(saleId <= _saleId.current() && saleId > 0, "sale does not exist");
    if(cancelled[saleId] || !Registry.isPlatformContract(address(this))) return "CANCELLED";
    if(block.timestamp < sales[saleId].startTime) return "PENDING";
    if(
      block.timestamp >= sales[saleId].startTime &&
      block.timestamp < sales[saleId].endTime &&
      sales[saleId].purchased < sales[saleId].amount
    ) return "ACTIVE";
    if(
      block.timestamp >= sales[saleId].endTime || 
      sales[saleId].purchased == sales[saleId].amount
    ) return "ENDED";
    revert("error");
  }

  /// @notice returns the user's balance of a particular token in the contract
  /// @dev use 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa for ETH
  /// @param account the address to query the balance of
  /// @param token the address of the token to query the account's balance of
  /// @return the uint256 balance of the account in the token queried
  function getClaimableBalance(address account, address token) external view returns(uint256){
    return claimableFunds[account][token];
  }

  /// @notice Creates a sale of NFTs from an approved contract
  /// @dev this custodies the NFTs in the contract until they are sold or reclaimed by the seller
  /// @dev use 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa for currency if ETH is being used
  /// @param nftContract the address of the contract the NFTs are from
  /// @param tokenId the index of the NFTs being sold in the NFT contract
  /// @param amount the amount of NFTs to sell
  /// @param startTime the uint256 Solidity timestamp the sale should start at
  /// @param endTime the uint256 Solidity timestamp the sale should end at
  /// @param maxBuyAmount the maximum amount a signle address can buy from the sale
  /// @param currency the address of the token NFTs can be bought in
  /// @return the uint256 ID of the sale
  function createSale(
    address nftContract,
    uint256 tokenId,
    uint256 amount,
    uint256 startTime,
    uint256 endTime,
    uint256 price,
    uint256 maxBuyAmount,
    address currency
  ) external nonReentrant returns(uint256) {
    IEtchedNFT NftContract = IEtchedNFT(nftContract);
    require(Registry.isPlatformContract(nftContract) == true, "NFT not in approved contract");
    require(Registry.isPlatformContract(address(this)) == true, "This contract is deprecated");
    require(Registry.isApprovedCurrency(currency) == true, "currency not supported");
    require(NftContract.supportsInterface(0x2a55205a), "contract must support ERC2981");
    require(NftContract.balanceOf(msg.sender, tokenId) >= amount, "insufficient NFT balance");
    require(endTime > startTime, "error in start/end params");
    require(maxBuyAmount > 0, "maxBuyAmount must be non-zero");
    _saleId.increment();
    uint256 saleId = _saleId.current();

    sales[saleId] = Sale({
      id: saleId,
      owner: msg.sender,
      nftContract: nftContract,
      tokenId: tokenId,
      amount: amount,
      purchased: 0,
      startTime: startTime,
      endTime: endTime,
      price: price,
      maxBuyAmount: maxBuyAmount,
      currency: currency
    });

    NftContract.safeTransferFrom(
      msg.sender, 
      address(this), 
      tokenId,
      amount,
      ""
    );

    emit NewSale(
      saleId,
      sales[saleId]
    );

    return saleId;
  }

  /// @notice purchases NFTs from a sale
  /// @dev system fees and royalties are automatically split off
  /// @param saleId the index of the sale to purchase from
  /// @param recipient the address the purchased NFTs should be sent to
  /// @param amountToBuy the amount of NFTs to purchase
  /// @param amountFromBalance the amount of claimable balance on this contract to use
  ///    towards the purchase
  /// @return a bool indicating success
  function buy(
    uint256 saleId, 
    address recipient, 
    uint256 amountToBuy,
    uint256 amountFromBalance
  ) external payable nonReentrant returns(bool) {
    require(Registry.isPlatformContract(address(this)) == true, "This contract is deprecated");
    require(keccak256(bytes(getSaleStatus(saleId))) == keccak256(bytes("ACTIVE")), "sale is not active");
    Sale memory currentSale = sales[saleId];
    require(purchased[saleId][msg.sender] + amountToBuy <= currentSale.maxBuyAmount, "buy quantity too high");
    require(amountToBuy <= currentSale.amount - currentSale.purchased,
      "not enough stock for purchase");
    address currency = currentSale.currency;
    require(amountFromBalance <= claimableFunds[msg.sender][currency],
      "not enough balance"
    );

    uint256 tokenId = currentSale.tokenId;

    IEtchedNFT Nft = IEtchedNFT(currentSale.nftContract);
    (address artistAddress, uint256 royalties) = Nft.royaltyInfo(tokenId, amountToBuy * currentSale.price);

    if(currency != ETH) {
      IERC20 Token = IERC20(currency);

      Token.safeTransferFrom(msg.sender, address(this), (amountToBuy * currentSale.price) - amountFromBalance);
    } else {
      require(msg.value == (amountToBuy * currentSale.price) - amountFromBalance, "msg.value + balance != price");
    }
    if(amountFromBalance > 0){
      claimableFunds[msg.sender][currency] -= amountFromBalance;
      emit BalanceUpdated(msg.sender, currency, claimableFunds[msg.sender][currency]);
    }

    // system fee
    (address systemWallet, uint256 fee) = Registry.feeInfo(amountToBuy * currentSale.price);
    claimableFunds[systemWallet][currency] += fee;
    emit BalanceUpdated(systemWallet, currency, claimableFunds[systemWallet][currency]);

    // artist royalty if artist isn't the seller
    if(currentSale.owner != artistAddress){
      claimableFunds[artistAddress][currency] += royalties;
      emit BalanceUpdated(artistAddress, currency, claimableFunds[artistAddress][currency]);
    } else {
      // since the artist is the seller
      royalties = 0;
    }

    // seller gains
    claimableFunds[currentSale.owner][currency] += (amountToBuy * currentSale.price) - fee - royalties;
    emit BalanceUpdated(currentSale.owner, currency, claimableFunds[currentSale.owner][currency]);

    sales[saleId].purchased += amountToBuy;
    purchased[saleId][msg.sender] += amountToBuy;

    Nft.safeTransferFrom(
      address(this), 
      recipient, 
      tokenId,
      amountToBuy, 
      ""
    );

    emit Purchase(saleId, msg.sender, recipient, amountToBuy);

    return true;
  }

  /// @notice claims unsold NFTs
  /// @dev this is for the original seller to reclaim unsold NFTs
  ///    from an ended or cancelled sale
  /// @param saleId the index of the sale to reclaim the NFTs from
  function claimNfts(uint256 saleId) external {
    bytes32 status = keccak256(bytes(getSaleStatus(saleId)));
    require(
      status == keccak256(bytes("CANCELLED")) || 
      status == keccak256(bytes("ENDED")),
      "cannot claim before sale closes"  
    );
    require(msg.sender == sales[saleId].owner,
      "only nft owner can claim"
    );
    require(sales[saleId].purchased < sales[saleId].amount, "stock already sold or claimed");

    uint256 stock = sales[saleId].amount - sales[saleId].purchased;
    sales[saleId].purchased = sales[saleId].amount;
    IEtchedNFT Nft = IEtchedNFT(sales[saleId].nftContract);
    Nft.safeTransferFrom(
      address(this),
      sales[saleId].owner, 
      sales[saleId].tokenId,
      stock,
      ""
    );

    emit NFTsReclaimed(saleId, msg.sender, stock);
  }

  /// @notice Explain to an end user what this does
  /// @dev use 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa for ETH
  /// @param tokenContract the address of the token being claimed
  function claimFunds(address tokenContract) external {
    require(claimableFunds[msg.sender][tokenContract] > 0, "nothing to claim");
    uint256 payout = claimableFunds[msg.sender][tokenContract];
    if(tokenContract != ETH) {
      IERC20 Token = IERC20(tokenContract);
      claimableFunds[msg.sender][tokenContract] = 0;
      Token.safeTransfer(msg.sender, payout);
    } else {
      claimableFunds[msg.sender][tokenContract] = 0;
      (bool success,) = msg.sender.call{ value: payout }("");
      require(success, "ETH payout failed");
    }
    emit BalanceUpdated(msg.sender, tokenContract, claimableFunds[msg.sender][tokenContract]);
  }

  /// @notice cancels a sale
  /// @dev can only be called by NFT owner or platform owner
  /// @param saleId the index of the sale to cancel
  function cancelSale(uint256 saleId) external {
    require(msg.sender == sales[saleId].owner || 
      msg.sender == owner(),
      "only owner or sale creator"  
    );
    cancelled[saleId] = true;

    emit SaleCancelled(saleId);
  }

  /// @notice callback functioning for signalling ERC1155 support
  /// @dev in order to receive a safeTransfer, contracts must return
  ///    `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
  ///    (0xf23a6e61) when queried
  /// @param operator The address which initiated the transfer (i.e. msg.sender)
  /// @param from The address which previously owned the token
  /// @param id The ID of the token being transferred
  /// @param value The amount of tokens being transferred
  /// @param data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
  function onERC1155Received(
    address operator, 
    address from,
    uint256 id, 
    uint256 value, 
    bytes memory data
    ) external pure returns(bytes4){
    // 0xf23a6e61 = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
    return 0xf23a6e61;
  }
}
