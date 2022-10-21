// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./interfaces/IFulfillInterpreter.sol";
import "./interfaces/ITransactionManager.sol";
import "./interpreters/FulfillInterpreter.sol";
import "./ProposedOwnable.sol";
import "./lib/LibAsset.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


/**
  *
  * @title TransactionManager
  * @author Connext <support@connext.network>
  * @notice This contract holds the logic to facilitate crosschain transactions.
  *         Transactions go through three phases in the happy case:
  *
  *         1. Route Auction (offchain): User broadcasts to our network 
  *         signalling their desired route. Routers respond with sealed bids 
  *         containing commitments to fulfilling the transaction within a 
  *         certain time and price range.
  *
  *         2. Prepare: Once the auction is completed, the transaction can be 
  *         prepared. The user submits a transaction to `TransactionManager` 
  *         contract on sender-side chain containing router's signed bid. This 
  *         transaction locks up the users funds on the sending chain. Upon 
  *         detecting an event containing their signed bid from the chain, 
  *         router submits the same transaction to `TransactionManager` on the 
  *         receiver-side chain, and locks up a corresponding amount of 
  *         liquidity. The amount locked on the receiving chain is `sending 
  *         amount - auction fee` so the router is incentivized to complete the 
  *         transaction.
  *
  *         3. Fulfill: Upon detecting the `TransactionPrepared` event on the 
  *         receiver-side chain, the user signs a message and sends it to a 
  *         relayer, who will earn a fee for submission. The relayer (which may 
  *         be the router) then submits the message to the `TransactionManager` 
  *         to complete their transaction on receiver-side chain and claim the 
  *         funds locked by the router. A relayer is used here to allow users 
  *         to submit transactions with arbitrary calldata on the receiving 
  *         chain without needing gas to do so. The router then submits the 
  *         same signed message and completes transaction on sender-side, 
  *         unlocking the original `amount`.
  *
  *         If a transaction is not fulfilled within a fixed timeout, it 
  *         reverts and can be reclaimed by the party that called `prepare` on 
  *         each chain (initiator). Additionally, transactions can be cancelled 
  *         unilaterally by the person owed funds on that chain (router for 
  *         sending chain, user for receiving chain) prior to expiry.
  */
contract TransactionManager is ReentrancyGuard, ProposedOwnable, ITransactionManager {
  /**
   * @dev Mapping of router to balance specific to asset
   */
  mapping(address => mapping(address => uint256)) public routerBalances;

  /**
    * @dev Mapping of allowed router addresses. Must be added to both
    *      sending and receiving chains when forwarding a transfer.
    */
  mapping(address => bool) public approvedRouters;

  /**
    * @dev Mapping of allowed assetIds on same chain as contract
    */
  mapping(address => bool) public approvedAssets;

  /**
    * @dev Mapping of hash of `InvariantTransactionData` to the hash
    *      of the `VariantTransactionData`
    */
  mapping(bytes32 => bytes32) public variantTransactionData;

  /**
  * @dev The stored chain id of the contract, may be passed in to avoid any 
  *      evm issues
  */
  uint256 private immutable chainId;

  /**
    * @dev Minimum timeout (will be the lowest on the receiving chain)
    */
  uint256 public constant MIN_TIMEOUT = 1 days; // 24 hours

  /**
    * @dev Maximum timeout (will be the highest on the sending chain)
    */
  uint256 public constant MAX_TIMEOUT = 30 days; // 720 hours

  /**
    * @dev The external contract that will execute crosschain
    *      calldata
    */
  IFulfillInterpreter public immutable interpreter;

  constructor(uint256 _chainId) {
    chainId = _chainId;
    interpreter = new FulfillInterpreter(address(this));
  }

  /** 
   * @notice Gets the chainId for this contract. If not specified during init
   *         will use the block.chainId
   */
  function getChainId() public view override returns (uint256 _chainId) {
    // Hold in memory to reduce sload calls
    uint256 chain = chainId;
    if (chain == 0) {
      // If not provided, pull from block
      chain = block.chainid;
    }
    return chain;
  }

  /**
   * @notice Allows us to get the chainId that this contract has stored
   */
  function getStoredChainId() external view override returns (uint256) {
    return chainId;
  }

  /**
    * @notice Used to add routers that can transact crosschain
    * @param router Router address to add
    */
  function addRouter(address router) external override onlyOwner {
    // Sanity check: not empty
    require(router != address(0), "#AR:001");

    // Sanity check: needs approval
    require(approvedRouters[router] == false, "#AR:032");

    // Update mapping
    approvedRouters[router] = true;

    // Emit event
    emit RouterAdded(router, msg.sender);
  }

  /**
    * @notice Used to remove routers that can transact crosschain
    * @param router Router address to remove
    */
  function removeRouter(address router) external override onlyOwner {
    // Sanity check: not empty
    require(router != address(0), "#RR:001");

    // Sanity check: needs removal
    require(approvedRouters[router] == true, "#RR:033");

    // Update mapping
    approvedRouters[router] = false;

    // Emit event
    emit RouterRemoved(router, msg.sender);
  }

  /**
    * @notice Used to add assets on same chain as contract that can
    *         be transferred.
    * @param assetId AssetId to add
    */
  function addAssetId(address assetId) external override onlyOwner {
    // Sanity check: needs approval
    require(approvedAssets[assetId] == false, "#AA:032");

    // Update mapping
    approvedAssets[assetId] = true;

    // Emit event
    emit AssetAdded(assetId, msg.sender);
  }

  /**
    * @notice Used to remove assets on same chain as contract that can
    *         be transferred.
    * @param assetId AssetId to remove
    */
  function removeAssetId(address assetId) external override onlyOwner {
    // Sanity check: already approval
    require(approvedAssets[assetId] == true, "#RA:033");

    // Update mapping
    approvedAssets[assetId] = false;

    // Emit event
    emit AssetRemoved(assetId, msg.sender);
  }

  /**
    * @notice This is used by anyone to increase a router's available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    * @param router The router you are adding liquidity on behalf of
    */
  function addLiquidityFor(uint256 amount, address assetId, address router) external payable override nonReentrant {
    _addLiquidityForRouter(amount, assetId, router);
  }

  /**
    * @notice This is used by any router to increase their available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    */
  function addLiquidity(uint256 amount, address assetId) external payable override nonReentrant {
    _addLiquidityForRouter(amount, assetId, msg.sender);
  }

  /**
    * @notice This is used by any router to decrease their available
    *         liquidity for a given asset.
    * @param amount The amount of liquidity to remove for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're removing liquidity for
    * @param recipient The address that will receive the liquidity being removed
    */
  function removeLiquidity(
    uint256 amount,
    address assetId,
    address payable recipient
  ) external override nonReentrant {
    // Sanity check: recipient is sensible
    require(recipient != address(0), "#RL:007");

    // Sanity check: nonzero amounts
    require(amount > 0, "#RL:002");

    uint256 routerBalance = routerBalances[msg.sender][assetId];
    // Sanity check: amount can be deducted for the router
    require(routerBalance >= amount, "#RL:008");

    // Update router balances
    unchecked {
      routerBalances[msg.sender][assetId] = routerBalance - amount;
    }

    // Transfer from contract to specified recipient
    LibAsset.transferAsset(assetId, recipient, amount);

    // Emit event
    emit LiquidityRemoved(msg.sender, assetId, amount, recipient);
  }

  /**
    * @notice This function creates a crosschain transaction. When called on
    *         the sending chain, the user is expected to lock up funds. When
    *         called on the receiving chain, the router deducts the transfer
    *         amount from the available liquidity. The majority of the
    *         information about a given transfer does not change between chains,
    *         with three notable exceptions: `amount`, `expiry`, and 
    *         `preparedBlock`. The `amount` and `expiry` are decremented
    *         between sending and receiving chains to provide an incentive for 
    *         the router to complete the transaction and time for the router to
    *         fulfill the transaction on the sending chain after the unlocking
    *         signature is revealed, respectively.
    * @param args TODO
    */
  function prepare(
    PrepareArgs calldata args
  ) external payable override nonReentrant returns (TransactionData memory) {
    // Sanity check: user is sensible
    require(args.invariantData.user != address(0), "#P:009");

    // Sanity check: router is sensible
    require(args.invariantData.router != address(0), "#P:001");

    // Router is approved *on both chains*
    require(isRouterOwnershipRenounced() || approvedRouters[args.invariantData.router], "#P:003");

    // Sanity check: sendingChainFallback is sensible
    require(args.invariantData.sendingChainFallback != address(0), "#P:010");

    // Sanity check: valid fallback
    require(args.invariantData.receivingAddress != address(0), "#P:026");

    // Make sure the chains are different
    require(args.invariantData.sendingChainId != args.invariantData.receivingChainId, "#P:011");

    // Make sure the chains are relevant
    uint256 _chainId = getChainId();
    require(args.invariantData.sendingChainId == _chainId || args.invariantData.receivingChainId == _chainId, "#P:012");

    { // Expiry scope
      // Make sure the expiry is greater than min
      uint256 buffer = args.expiry - block.timestamp;
      require(buffer >= MIN_TIMEOUT, "#P:013");

      // Make sure the expiry is lower than max
      require(buffer <= MAX_TIMEOUT, "#P:014");
    }

    // Make sure the hash is not a duplicate
    bytes32 digest = keccak256(abi.encode(args.invariantData));
    require(variantTransactionData[digest] == bytes32(0), "#P:015");

    // NOTE: the `encodedBid` and `bidSignature` are simply passed through
    //       to the contract emitted event to ensure the availability of
    //       this information. Their validity is asserted offchain, and
    //       is out of scope of this contract. They are used as inputs so
    //       in the event of a router or user crash, they may recover the
    //       correct bid information without requiring an offchain store.

    // Amount actually used (if fee-on-transfer will be different than
    // supplied)
    uint256 amount = args.amount;

    // First determine if this is sender side or receiver side
    if (args.invariantData.sendingChainId == _chainId) {
      // Check the sender is correct
      require(msg.sender == args.invariantData.initiator, "#P:039");

      // Sanity check: amount is sensible
      // Only check on sending chain to enforce router fees. Transactions could
      // be 0-valued on receiving chain if it is just a value-less call to some
      // `IFulfillHelper`
      require(args.amount > 0, "#P:002");

      // Assets are approved
      // NOTE: Cannot check this on receiving chain because of differing
      // chain contexts
      require(isAssetOwnershipRenounced() || approvedAssets[args.invariantData.sendingAssetId], "#P:004");

      // This is sender side prepare. The user is beginning the process of 
      // submitting an onchain tx after accepting some bid. They should
      // lock their funds in the contract for the router to claim after
      // they have revealed their signature on the receiving chain via
      // submitting a corresponding `fulfill` tx

      // Validate correct amounts on msg and transfer from user to
      // contract
      amount = transferAssetToContract(
        args.invariantData.sendingAssetId,
        args.amount
      );

      // Store the transaction variants. This happens after transferring to
      // account for fee on transfer tokens
      variantTransactionData[digest] = hashVariantTransactionData(
        amount,
        args.expiry,
        block.number
      );
    } else {
      // This is receiver side prepare. The router has proposed a bid on the
      // transfer which the user has accepted. They can now lock up their
      // own liquidity on th receiving chain, which the user can unlock by
      // calling `fulfill`. When creating the `amount` and `expiry` on the
      // receiving chain, the router should have decremented both. The
      // expiry should be decremented to ensure the router has time to
      // complete the sender-side transaction after the user completes the
      // receiver-side transactoin. The amount should be decremented to act as
      // a fee to incentivize the router to complete the transaction properly.

      // Check that the callTo is a contract
      // NOTE: This cannot happen on the sending chain (different chain 
      // contexts), so a user could mistakenly create a transfer that must be
      // cancelled if this is incorrect
      require(args.invariantData.callTo == address(0) || Address.isContract(args.invariantData.callTo), "#P:031");

      // Check that the asset is approved
      // NOTE: This cannot happen on both chains because of differing chain 
      // contexts. May be possible for user to create transaction that is not
      // prepare-able on the receiver chain.
      require(isAssetOwnershipRenounced() || approvedAssets[args.invariantData.receivingAssetId], "#P:004");

      // Check that the caller is the router
      require(msg.sender == args.invariantData.router, "#P:016");

      // Check that the router isnt accidentally locking funds in the contract
      require(msg.value == 0, "#P:017");

      // Check that router has liquidity
      uint256 balance = routerBalances[args.invariantData.router][args.invariantData.receivingAssetId];
      require(balance >= amount, "#P:018");

      // Store the transaction variants
      variantTransactionData[digest] = hashVariantTransactionData(
        amount,
        args.expiry,
        block.number
      );

      // Decrement the router liquidity
      // using unchecked because underflow protected against with require
      unchecked {
        routerBalances[args.invariantData.router][args.invariantData.receivingAssetId] = balance - amount;
      }
    }

    // Emit event
    TransactionData memory txData = TransactionData({
      receivingChainTxManagerAddress: args.invariantData.receivingChainTxManagerAddress,
      user: args.invariantData.user,
      router: args.invariantData.router,
      initiator: args.invariantData.initiator,
      sendingAssetId: args.invariantData.sendingAssetId,
      receivingAssetId: args.invariantData.receivingAssetId,
      sendingChainFallback: args.invariantData.sendingChainFallback,
      callTo: args.invariantData.callTo,
      receivingAddress: args.invariantData.receivingAddress,
      callDataHash: args.invariantData.callDataHash,
      transactionId: args.invariantData.transactionId,
      sendingChainId: args.invariantData.sendingChainId,
      receivingChainId: args.invariantData.receivingChainId,
      amount: amount,
      expiry: args.expiry,
      preparedBlockNumber: block.number
    });

    emit TransactionPrepared(
      txData.user,
      txData.router,
      txData.transactionId,
      txData,
      msg.sender,
      args
    );

    return txData;
  }



    /**
    * @notice This function completes a crosschain transaction. When called on
    *         the receiving chain, the user reveals their signature on the
    *         transactionId and is sent the amount corresponding to the number
    *         of shares the router locked when calling `prepare`. The router 
    *         then uses this signature to unlock the corresponding funds on the 
    *         receiving chain, which are then added back to their available 
    *         liquidity. The user includes a relayer fee since it is not 
    *         assumed they will have gas on the receiving chain. This function 
    *         *must* be called before the transaction expiry has elapsed.
    * @param args TODO
    */
  function fulfill(
    FulfillArgs calldata args
  ) external override nonReentrant returns (TransactionData memory) {
    // Get the hash of the invariant tx data. This hash is the same
    // between sending and receiving chains. The variant data is stored
    // in the contract when `prepare` is called within the mapping.

    { // scope: validation and effects
      bytes32 digest = hashInvariantTransactionData(args.txData);

      // Make sure that the variant data matches what was stored
      require(variantTransactionData[digest] == hashVariantTransactionData(
        args.txData.amount,
        args.txData.expiry,
        args.txData.preparedBlockNumber
      ), "#F:019");

      // Make sure the expiry has not elapsed
      require(args.txData.expiry >= block.timestamp, "#F:020");

      // Make sure the transaction wasn't already completed
      require(args.txData.preparedBlockNumber > 0, "#F:021");

      // Check provided callData matches stored hash
      require(keccak256(args.callData) == args.txData.callDataHash, "#F:024");

      // To prevent `fulfill` / `cancel` from being called multiple times, the
      // preparedBlockNumber is set to 0 before being hashed. The value of the
      // mapping is explicitly *not* zeroed out so users who come online without
      // a store can tell the difference between a transaction that has not been
      // prepared, and a transaction that was already completed on the receiver
      // chain.
      variantTransactionData[digest] = hashVariantTransactionData(
        args.txData.amount,
        args.txData.expiry,
        0
      );
    }

    // Declare these variables for the event emission. Are only assigned
    // IFF there is an external call on the receiving chain
    bool success;
    bool isContract;
    bytes memory returnData;

    uint256 _chainId = getChainId();

    if (args.txData.sendingChainId == _chainId) {
      // The router is completing the transaction, they should get the
      // amount that the user deposited credited to their liquidity
      // reserves.

      // Make sure that the user is not accidentally fulfilling the transaction
      // on the sending chain
      require(msg.sender == args.txData.router, "#F:016");

      // Validate the user has signed
      require(
        recoverFulfillSignature(
          args.txData.transactionId,
          args.relayerFee,
          args.txData.receivingChainId,
          args.txData.receivingChainTxManagerAddress,
          args.signature
        ) == args.txData.user, "#F:022"
      );

      // Complete tx to router for original sending amount
      routerBalances[args.txData.router][args.txData.sendingAssetId] += args.txData.amount;

    } else {
      // Validate the user has signed, using domain of contract
      require(
        recoverFulfillSignature(
          args.txData.transactionId,
          args.relayerFee,
          _chainId,
          address(this),
          args.signature
        ) == args.txData.user, "#F:022"
      );

      // Sanity check: fee <= amount. Allow `=` in case of only 
      // wanting to execute 0-value crosschain tx, so only providing 
      // the fee amount
      require(args.relayerFee <= args.txData.amount, "#F:023");

      (success, isContract, returnData) = _receivingChainFulfill(
        args.txData,
        args.relayerFee,
        args.callData
      );
    }

    // Emit event
    emit TransactionFulfilled(
      args.txData.user,
      args.txData.router,
      args.txData.transactionId,
      args,
      success,
      isContract,
      returnData,
      msg.sender
    );

    return args.txData;
  }

  /**
    * @notice Any crosschain transaction can be cancelled after it has been
    *         created to prevent indefinite lock up of funds. After the
    *         transaction has expired, anyone can cancel it. Before the
    *         expiry, only the recipient of the funds on the given chain is
    *         able to cancel. On the sending chain, this means only the router
    *         is able to cancel before the expiry, while only the user can
    *         prematurely cancel on the receiving chain.
    * @param args TODO
    */
  function cancel(CancelArgs calldata args)
    external
    override
    nonReentrant
    returns (TransactionData memory)
  {
    // Make sure params match against stored data
    // Also checks that there is an active transfer here
    // Also checks that sender or receiver chainID is this chainId (bc we checked it previously)

    // Get the hash of the invariant tx data. This hash is the same
    // between sending and receiving chains. The variant data is stored
    // in the contract when `prepare` is called within the mapping.
    bytes32 digest = hashInvariantTransactionData(args.txData);

    // Verify the variant data is correct
    require(variantTransactionData[digest] == hashVariantTransactionData(args.txData.amount, args.txData.expiry, args.txData.preparedBlockNumber), "#C:019");

    // Make sure the transaction wasn't already completed
    require(args.txData.preparedBlockNumber > 0, "#C:021");

    // To prevent `fulfill` / `cancel` from being called multiple times, the
    // preparedBlockNumber is set to 0 before being hashed. The value of the
    // mapping is explicitly *not* zeroed out so users who come online without
    // a store can tell the difference between a transaction that has not been
    // prepared, and a transaction that was already completed on the receiver
    // chain.
    variantTransactionData[digest] = hashVariantTransactionData(args.txData.amount, args.txData.expiry, 0);

    // Get chainId for gas
    uint256 _chainId = getChainId();

    // Return the appropriate locked funds
    if (args.txData.sendingChainId == _chainId) {
      // Sender side, funds must be returned to the user
      if (args.txData.expiry >= block.timestamp) {
        // Timeout has not expired and tx may only be cancelled by router
        // NOTE: no need to validate the signature here, since you are requiring
        // the router must be the sender when the cancellation is during the
        // fulfill-able window
        require(msg.sender == args.txData.router, "#C:025");
      }

      // Return users locked funds
      // NOTE: no need to check if amount > 0 because cant be prepared on
      // sending chain with 0 value
      LibAsset.transferAsset(
        args.txData.sendingAssetId,
        payable(args.txData.sendingChainFallback),
        args.txData.amount
      );

    } else {
      // Receiver side, router liquidity is returned
      if (args.txData.expiry >= block.timestamp) {
        // Timeout has not expired and tx may only be cancelled by user
        // Validate signature
        require(msg.sender == args.txData.user || recoverCancelSignature(args.txData.transactionId, _chainId, address(this), args.signature) == args.txData.user, "#C:022");

        // NOTE: there is no incentive here for relayers to submit this on
        // behalf of the user (i.e. fee not respected) because the user has not
        // locked funds on this contract. However, if the user reveals their
        // cancel signature to the router, they are incentivized to submit it
        // to unlock their own funds
      }

      // Return liquidity to router
      routerBalances[args.txData.router][args.txData.receivingAssetId] += args.txData.amount;
    }

    // Emit event
    emit TransactionCancelled(
      args.txData.user,
      args.txData.router,
      args.txData.transactionId,
      args,
      msg.sender
    );

    // Return
    return args.txData;
  }

  //////////////////////////
  /// Private functions ///
  //////////////////////////

  /**
    * @notice Contains the logic to verify + increment a given routers liquidity
    * @param amount The amount of liquidity to add for the router
    * @param assetId The address (or `address(0)` if native asset) of the
    *                asset you're adding liquidity for
    * @param router The router you are adding liquidity on behalf of
    */
  function _addLiquidityForRouter(
    uint256 amount,
    address assetId,
    address router
  ) internal {
    // Sanity check: router is sensible
    require(router != address(0), "#AL:001");

    // Sanity check: nonzero amounts
    require(amount > 0, "#AL:002");

    // Router is approved
    require(isRouterOwnershipRenounced() || approvedRouters[router], "#AL:003");

    // Asset is approved
    require(isAssetOwnershipRenounced() || approvedAssets[assetId], "#AL:004");

    // Transfer funds to contract
    amount = transferAssetToContract(assetId, amount);

    // Update the router balances. Happens after pulling funds to account for
    // the fee on transfer tokens
    routerBalances[router][assetId] += amount;

    // Emit event
    emit LiquidityAdded(router, assetId, amount, msg.sender);
  }

  /**
   * @notice Handles transferring funds from msg.sender to the
   *         transaction manager contract. Used in prepare, addLiquidity
   * @param assetId The address to transfer
   * @param specifiedAmount The specified amount to transfer. May not be the 
   *                        actual amount transferred (i.e. fee on transfer 
   *                        tokens)
   */
  function transferAssetToContract(address assetId, uint256 specifiedAmount) internal returns (uint256) {
    uint256 trueAmount = specifiedAmount;

    // Validate correct amounts are transferred
    if (LibAsset.isNativeAsset(assetId)) {
      require(msg.value == specifiedAmount, "#TA:005");
    } else {
      uint256 starting = LibAsset.getOwnBalance(assetId);
      require(msg.value == 0, "#TA:006");
      LibAsset.transferFromERC20(assetId, msg.sender, address(this), specifiedAmount);
      // Calculate the *actual* amount that was sent here
      trueAmount = LibAsset.getOwnBalance(assetId) - starting;
    }

    return trueAmount;
  }

  /// @notice Recovers the signer from the signature provided by the user
  /// @param transactionId Transaction identifier of tx being recovered
  /// @param signature The signature you are recovering the signer from
  function recoverCancelSignature(
    bytes32 transactionId,
    uint256 receivingChainId,
    address receivingChainTxManagerAddress,
    bytes calldata signature
  ) internal pure returns (address) {
    // Create the signed payload
    SignedCancelData memory payload = SignedCancelData({
      transactionId: transactionId,
      functionIdentifier: "cancel",
      receivingChainId: receivingChainId,
      receivingChainTxManagerAddress: receivingChainTxManagerAddress
    });

    // Recover
    return recoverSignature(abi.encode(payload), signature);
  }

  /**
    * @notice Recovers the signer from the signature provided by the user
    * @param transactionId Transaction identifier of tx being recovered
    * @param relayerFee The fee paid to the relayer for submitting the
    *                   tx on behalf of the user.
    * @param signature The signature you are recovering the signer from
    */
  function recoverFulfillSignature(
    bytes32 transactionId,
    uint256 relayerFee,
    uint256 receivingChainId,
    address receivingChainTxManagerAddress,
    bytes calldata signature
  ) internal pure returns (address) {
    // Create the signed payload
    SignedFulfillData memory payload = SignedFulfillData({
      transactionId: transactionId,
      relayerFee: relayerFee,
      functionIdentifier: "fulfill",
      receivingChainId: receivingChainId,
      receivingChainTxManagerAddress: receivingChainTxManagerAddress
    });

    // Recover
    return recoverSignature(abi.encode(payload), signature);
  }

  /**
    * @notice Holds the logic to recover the signer from an encoded payload.
    *         Will hash and convert to an eth signed message.
    * @param encodedPayload The payload that was signed
    * @param signature The signature you are recovering the signer from
    */
  function recoverSignature(bytes memory encodedPayload, bytes calldata  signature) internal pure returns (address) {
    // Recover
    return ECDSA.recover(
      ECDSA.toEthSignedMessageHash(keccak256(encodedPayload)),
      signature
    );
  }

  /**
    * @notice Returns the hash of only the invariant portions of a given
    *         crosschain transaction
    * @param txData TransactionData to hash
    */
  function hashInvariantTransactionData(TransactionData calldata txData) internal pure returns (bytes32) {
    InvariantTransactionData memory invariant = InvariantTransactionData({
      receivingChainTxManagerAddress: txData.receivingChainTxManagerAddress,
      user: txData.user,
      router: txData.router,
      initiator: txData.initiator,
      sendingAssetId: txData.sendingAssetId,
      receivingAssetId: txData.receivingAssetId,
      sendingChainFallback: txData.sendingChainFallback,
      callTo: txData.callTo,
      receivingAddress: txData.receivingAddress,
      sendingChainId: txData.sendingChainId,
      receivingChainId: txData.receivingChainId,
      callDataHash: txData.callDataHash,
      transactionId: txData.transactionId
    });
    return keccak256(abi.encode(invariant));
  }

  /**
    * @notice Returns the hash of only the variant portions of a given
    *         crosschain transaction
    * @param amount amount to hash
    * @param expiry expiry to hash
    * @param preparedBlockNumber preparedBlockNumber to hash
    * @return Hash of the variant data
    *
    */
  function hashVariantTransactionData(uint256 amount, uint256 expiry, uint256 preparedBlockNumber) internal pure returns (bytes32) {
    VariantTransactionData memory variant = VariantTransactionData({
      amount: amount,
      expiry: expiry,
      preparedBlockNumber: preparedBlockNumber
    });
    return keccak256(abi.encode(variant));
  }

  /**
   * @notice Handles the receiving-chain fulfillment. This function should
   *         pay the relayer and either send funds to the specified address
   *         or execute the calldata. Will return a tuple of boolean,bytes
   *         indicating the success and return data of the external call.
   * @dev Separated from fulfill function to avoid stack too deep errors
   *
   * @param txData The TransactionData that needs to be fulfilled
   * @param relayerFee The fee to be paid to the relayer for submission
   * @param callData The data to be executed on the receiving chain
   *
   * @return Tuple representing (success, returnData) of the external call
   */
  function _receivingChainFulfill(
    TransactionData calldata txData,
    uint256 relayerFee,
    bytes calldata callData
  ) internal returns (bool, bool, bytes memory) {
    // The user is completing the transaction, they should get the
    // amount that the router deposited less fees for relayer.

    // Get the amount to send
    uint256 toSend;
    unchecked {
      toSend = txData.amount - relayerFee;
    }

    // Send the relayer the fee
    if (relayerFee > 0) {
      LibAsset.transferAsset(txData.receivingAssetId, payable(msg.sender), relayerFee);
    }

    // Handle receiver chain external calls if needed
    if (txData.callTo == address(0)) {
      // No external calls, send directly to receiving address
      if (toSend > 0) {
        LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend);
      }
      return (false, false, new bytes(0));
    } else {
      // Handle external calls with a fallback to the receiving
      // address in case the call fails so the funds dont remain
      // locked.

      bool isNativeAsset = LibAsset.isNativeAsset(txData.receivingAssetId);

      // First, transfer the funds to the helper if needed
      if (!isNativeAsset && toSend > 0) {
        LibAsset.transferERC20(txData.receivingAssetId, address(interpreter), toSend);
      }

      // Next, call `execute` on the helper. Helpers should internally
      // track funds to make sure no one user is able to take all funds
      // for tx, and handle the case of reversions
      return interpreter.execute{ value: isNativeAsset ? toSend : 0}(
        txData.transactionId,
        payable(txData.callTo),
        txData.receivingAssetId,
        payable(txData.receivingAddress),
        toSend,
        callData
      );
    }
  }
}

