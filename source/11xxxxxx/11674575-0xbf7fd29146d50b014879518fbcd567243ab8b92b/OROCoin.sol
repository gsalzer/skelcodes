pragma solidity 0.7.0;

interface tokenRecipient {
    function receiveApproval (address from, uint256 value, address token, bytes calldata extraData) external;
}

interface ERC20CompatibleToken {
    function transfer (address to, uint256 value) external returns (bool);
}

/**
 * Math operations with safety checks that throw on overflows.
 */
library SafeMath {
    
    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
    
    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
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
				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
contract OROCoin is Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => mapping(uint => bool)) public usedSigIds; 

    address public rescueAccount; 
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier rescueAccountOnly {require(msg.sender == rescueAccount); _;}

    enum sigStandard { typed, personal, stringHex }
    enum sigDestination { transfer, approve, approveAndCall, transferFrom }

    bytes constant public ethSignedMessagePrefix = "\x19Ethereum Signed Message:\n";
    bytes32 constant public sigDestinationTransfer = keccak256(abi.encodePacked(
        "address Token Contract Address",
        "address Sender's Address",
        "address Recipient's Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "address Account which Receives Fee",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    )); // `transferViaSignature`: keccak256(address(this), from, to, value, fee, deadline, sigId)
    bytes32 constant public sigDestinationTransferFrom = keccak256(abi.encodePacked(
        "address Token Contract Address",
        "address Address Approved for Withdraw",
        "address Account to Withdraw From",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "address Account which Receives Fee",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    )); // `transferFromViaSignature`: keccak256(address(this), signer, from, to, value, fee, deadline, sigId)
    bytes32 constant public sigDestinationApprove = keccak256(abi.encodePacked(
        "address Token Contract Address",
        "address Withdrawal Approval Address",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "address Account which Receives Fee",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    )); // `approveViaSignature`: keccak256(address(this), from, spender, value, fee, deadline, sigId)
    bytes32 constant public sigDestinationApproveAndCall = keccak256(abi.encodePacked(
        "address Token Contract Address",
        "address Withdrawal Approval Address",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "bytes Data to Transfer",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "address Account which Receives Fee",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    )); // `approveAndCallViaSignature`: keccak256(address(this), from, spender, value, extraData, fee, deadline, sigId)

    constructor () public {
        name = "ORO (GBP)";
        symbol = "ORP";
        rescueAccount = msg.sender;
    } 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		

    /**
     * Utility internal function used to safely transfer `value` tokens `from` -> `to`. Throws if transfer is impossible.
     * @param from - account to make the transfer from
     * @param to - account to transfer `value` tokens to
     * @param value - tokens to transfer to account `to`
     */
    function internalTransfer (address from, address to, uint value) internal {
        require(to != address(0x0)); // Prevent people from accidentally burning their tokens
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * Utility internal function used to safely transfer `value1` tokens `from` -> `to1`, and `value2` tokens
     * `from` -> `to2`, minimizing gas usage (calling `internalTransfer` twice is more expensive). Throws if
     * transfers are impossible.
     * @param from - account to make the transfer from
     * @param to1 - account to transfer `value1` tokens to
     * @param value1 - tokens to transfer to account `to1`
     * @param to2 - account to transfer `value2` tokens to
     * @param value2 - tokens to transfer to account `to2`
     */
    function internalDoubleTransfer (address from, address to1, uint value1, address to2, uint value2) internal {
        require(to1 != address(0x0) && to2 != address(0x0)); // Prevent people from accidentally burning their tokens
        balanceOf[from] = balanceOf[from].sub(value1.add(value2));
        balanceOf[to1] = balanceOf[to1].add(value1);
        emit Transfer(from, to1, value1);
        if (value2 > 0) {
            balanceOf[to2] = balanceOf[to2].add(value2);
            emit Transfer(from, to2, value2);
        }
    }

    /**
     * Internal method that makes sure that the given signature corresponds to a given data and is made by `signer`.
     * It utilizes three (four) standards of message signing in Ethereum, as at the moment of this smart contract
     * development there is no single signing standard defined. For example, Metamask and Geth both support
     * personal_sign standard, SignTypedData is only supported by Matamask, Trezor does not support "widely adopted"
     * Ethereum personal_sign but rather personal_sign with fixed prefix and so on.
     * Note that it is always possible to forge any of these signatures using the private key, the problem is that
     * third-party wallets must adopt a single standard for signing messages.
     * @param data - original data which had to be signed by `signer`
     * @param signer - account which made a signature
     * @param deadline - until when the signature is valid
     * @param sigId - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param sig - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param sigStd - chosen standard for signature validation. The signer must explicitly tell which standard they use
     * @param sigDest - for which type of action this signature was made
     */
    function requireSignature (
        bytes32 data,
        address signer,
        uint256 deadline,
        uint256 sigId,
        bytes memory sig,
        sigStandard sigStd,
        sigDestination sigDest
    ) internal {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly { // solium-disable-line security/no-inline-assembly
            r := mload(add(sig, 32))
            s := mload(add(sig, 64)) 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27)
            v += 27;
        require(block.timestamp <= deadline && !usedSigIds[signer][sigId]); // solium-disable-line security/no-block-members
        if (sigStd == sigStandard.typed) { // Typed signature. This is the most likely scenario to be used and accepted
            require(
                signer == ecrecover(
                    keccak256(abi.encodePacked(
                        sigDest == sigDestination.transfer
                            ? sigDestinationTransfer
                            : sigDest == sigDestination.approve
                                ? sigDestinationApprove
                                : sigDest == sigDestination.approveAndCall
                                    ? sigDestinationApproveAndCall
                                    : sigDestinationTransferFrom,
                        data
                    )),
                    v, r, s
                )
            );
        } else if (sigStd == sigStandard.personal) { // Ethereum signed message signature (Geth and Trezor)
            require(
                signer == ecrecover(keccak256(abi.encodePacked(ethSignedMessagePrefix, "32", data)), v, r, s) // Geth-adopted
                ||
                signer == ecrecover(keccak256(abi.encodePacked(ethSignedMessagePrefix, "\x20", data)), v, r, s) // Trezor-adopted
            );
        } else { // == 2; Signed string hash signature (the most expensive but universal)
            require(
                signer == ecrecover(keccak256(abi.encodePacked(ethSignedMessagePrefix, "64", hexToString(data))), v, r, s) // Geth
                ||
                signer == ecrecover(keccak256(abi.encodePacked(ethSignedMessagePrefix, "\x40", hexToString(data))), v, r, s) // Trezor
            );
        }
        usedSigIds[signer][sigId] = true;
    }

    /**
     * Utility costly function to encode bytes HEX representation as string.
     * @param sig - signature as bytes32 to represent as string
     */
    function hexToString (bytes32 sig) internal pure returns (bytes memory) {
        bytes memory str = new bytes(64);
        for (uint8 i = 0; i < 32; ++i) {
            str[2 * i] = byte((uint8(sig[i]) / 16 < 10 ? 48 : 87) + uint8(sig[i]) / 16);
            str[2 * i + 1] = byte((uint8(sig[i]) % 16 < 10 ? 48 : 87) + (uint8(sig[i]) % 16));
        }
        return str;
    }

    /**
     * Transfer `value` tokens to `to` address from the account of sender.
     * @param to - the address of the recipient
     * @param value - the amount to send
     */
    function transfer (address to, uint256 value) public returns (bool) {
        internalTransfer(msg.sender, to, value);
        return true;
    }

    /**
     * This function distincts transaction signer from transaction executor. It allows anyone to transfer tokens
     * from the `from` account by providing a valid signature, which can only be obtained from the `from` account
     * owner.
     * Note that passed parameter sigId is unique and cannot be passed twice (prevents replay attacks). When there's
     * a need to make signature once again (because the first one is lost or whatever), user should sign the message
     * with the same sigId, thus ensuring that the previous signature can't be used if the new one passes.
     * Use case: the user wants to send some tokens to another user or smart contract, but don't have Ether to do so.
     * @param from - the account giving its signature to transfer `value` tokens to `to` address
     * @param to - the account receiving `value` tokens
     * @param value - the value in tokens to transfer
     * @param fee - a fee to pay to `feeRecipient`
     * @param feeRecipient - account which will receive fee
     * @param deadline - until when the signature is valid
     * @param sigId - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param sig - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param sigStd - chosen standard for signature validation. The signer must explicitly tell which standard they use
     */
    function transferViaSignature ( 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
        address        from,
        address        to,
        uint256        value,
        uint256        fee,
        address        feeRecipient,
        uint256        deadline,
        uint256        sigId,
        bytes calldata sig,
        sigStandard    sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(abi.encodePacked(address(this), from, to, value, fee, feeRecipient, deadline, sigId)),
            from, deadline, sigId, sig, sigStd, sigDestination.transfer
        );
        internalDoubleTransfer(from, to, value, feeRecipient, fee);
        return true;
    }

    /**
     * Allow `spender` to take `value` tokens from the transaction sender's account.
     * Beware that changing an allowance with this method brings the risk that `spender` may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender - the address authorized to spend
     * @param value - the maximum amount they can spend
     */
    function approve (address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * Same as `transferViaSignature`, but for `approve`.
     * Use case: the user wants to set an allowance for the smart contract or another user without having Ether on
     * their balance.
     * @param from - the account to approve withdrawal from, which signed all below parameters
     * @param spender - the account allowed to withdraw tokens from `from` address
     * @param value - the value in tokens to approve to withdraw
     * @param fee - a fee to pay to `feeRecipient`
     * @param feeRecipient - account which will receive fee
     * @param deadline - until when the signature is valid
     * @param sigId - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param sig - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param sigStd - chosen standard for signature validation. The signer must explicitly tell which standard they use
     */
    function approveViaSignature (
        address        from,
        address        spender,
        uint256        value,
        uint256        fee,
        address        feeRecipient,
        uint256        deadline,
        uint256        sigId,
        bytes calldata sig,
        sigStandard    sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(abi.encodePacked(address(this), from, spender, value, fee, feeRecipient, deadline, sigId)),
            from, deadline, sigId, sig, sigStd, sigDestination.approve
        );
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
        internalTransfer(from, feeRecipient, fee);
        return true;
    }

    /**
     * Transfer `value` tokens to `to` address from the `from` account, using the previously set allowance.
     * @param from - the address to transfer tokens from
     * @param to - the address of the recipient
     * @param value - the amount to send
     */
    function transferFrom (address from, address to, uint256 value) public returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        internalTransfer(from, to, value);
        return true;
    }

    /**
     * Same as `transferViaSignature`, but for `transferFrom`.
     * Use case: the user wants to withdraw tokens from a smart contract or another user who allowed the user to
     * do so. Important note: the fee is subtracted from the `value`, and `to` address receives `value - fee`.
     * @param signer - the address allowed to call transferFrom, which signed all below parameters
     * @param from - the account to make withdrawal from
     * @param to - the address of the recipient
     * @param value - the value in tokens to withdraw
     * @param fee - a fee to pay to `feeRecipient`
     * @param feeRecipient - account which will receive fee
     * @param deadline - until when the signature is valid
     * @param sigId - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param sig - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param sigStd - chosen standard for signature validation. The signer must explicitly tell which standard they use
     */
    function transferFromViaSignature (
        address        signer,
        address        from,
        address        to,
        uint256        value,
        uint256        fee,
        address        feeRecipient,
        uint256        deadline,
        uint256        sigId,
        bytes calldata sig,
        sigStandard    sigStd
    ) external returns (bool) { 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
        requireSignature(
            keccak256(abi.encodePacked(address(this), from, to, value, fee, feeRecipient, deadline, sigId)),
            signer, deadline, sigId, sig, sigStd, sigDestination.transferFrom
        );
        allowance[from][signer] = allowance[from][signer].sub(value);
        internalDoubleTransfer(from, to, value.sub(fee), feeRecipient, fee);
        return true;
    }

    /**
     * Utility function, which acts the same as approve(...), but also calls `receiveApproval` function on a
     * `spender` address, which is usually the address of the smart contract. In the same call, smart contract can
     * withdraw tokens from the sender's account and receive additional `extraData` for processing.
     * @param spender - the address to be authorized to spend tokens
     * @param value - the max amount the `spender` can withdraw
     * @param extraData - some extra information to send to the approved contract
     */
    function approveAndCall (address spender, uint256 value, bytes memory extraData) public returns (bool) {
        approve(spender, value);
        tokenRecipient(spender).receiveApproval(msg.sender, value, address(this), extraData);
        return true;
    }

    /**
     * Same as `approveViaSignature`, but for `approveAndCall`.
     * Use case: the user wants to send tokens to the smart contract and pass additional data within one transaction.
     * @param fromAddress - the account to approve withdrawal from, which signed all below parameters
     * @param spender - the account allowed to withdraw tokens from `from` address (in this case, smart contract only)
     * @param value - the value in tokens to approve to withdraw
     * @param extraData - additional data to pass to the `spender` smart contract
     * @param fee - a fee to pay to `feeRecipient`
     * @param feeRecipient - account which will receive fee
     * @param deadline - until when the signature is valid
     * @param sigId - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param sig - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param sigStd - chosen standard for signature validation. The signer must explicitly tell which standard they use
     */
    function approveAndCallViaSignature (
        address        fromAddress,
        address        spender,
        uint256        value,
        bytes calldata extraData,
        uint256        fee,
        address        feeRecipient,
        uint256        deadline,
        uint256        sigId,
        bytes calldata sig,
        sigStandard    sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(abi.encodePacked(address(this), fromAddress, spender, value, extraData, fee, feeRecipient, deadline, sigId)), fromAddress, deadline, sigId, sig, sigStd, sigDestination.approveAndCall);
        allowance[fromAddress][spender] = value;
        emit Approval(fromAddress, spender, value);
        tokenRecipient(spender).receiveApproval(fromAddress, value, address(this), extraData);
        internalTransfer(fromAddress, feeRecipient, fee);
        return true;
    } 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		

    /**
     * Mint some tokens to the sender's address.
     */
    function mintTokens (uint newSupply) onlyOwner external {
        totalSupply = totalSupply.add(newSupply);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(newSupply);
        emit Transfer(address(0x0), msg.sender, newSupply);
    }

    /**
     * ERC20 tokens are not designed to hold any other tokens (or Ether) on their balances. There were thousands
     * of cases when people accidentally transfer tokens to a contract address while there is no way to get them
     * back. This function adds a possibility to "rescue" tokens that were accidentally sent to this smart contract.
     * @param tokenContract - ERC20-compatible token
     * @param value - amount to rescue
     */
    function rescueLostTokens (ERC20CompatibleToken tokenContract, uint256 value) external rescueAccountOnly {
        tokenContract.transfer(rescueAccount, value);
    }

    /**
     * Utility function that allows to change the rescueAccount address, which can "rescue" tokens accidentally sent to
     * this smart contract address.
     * @param newRescueAccount - account which will become authorized to rescue tokens
     */ 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
    function changeRescueAccount (address newRescueAccount) external rescueAccountOnly {
        rescueAccount = newRescueAccount;
    }
 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
}
