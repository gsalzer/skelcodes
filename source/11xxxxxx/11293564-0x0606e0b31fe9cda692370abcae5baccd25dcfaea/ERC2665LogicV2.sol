// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./ERC2665V1.sol";
import "./ERC2665V2.sol";
import "./TheCryptographLogicV1.sol";
import "./CryptographFactoryV1.sol";
import "./CryptographIndexV1.sol";
import "./ERC20Generic.sol";

/// @author Guillaume Gonnaud 2020
/// @title  Cryptograph ERC2665 Mimic Smart Contract
/// @notice Provide the logic code for third parties to read cryptographs as if they were ERC2665 tokens (they are not, hence no "write" interactions are enabled)
contract ERC2665LogicV2 is VCProxyData, ERC2665HeaderV1, ERC2665StoragePublicV2 {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall and hence its memory state is irrelevant
    constructor() public {
        //Self intialize (nothing)
    }

    function init(address _auctionHouse, address _indexCry) external{
        require(auctionHouse == address(0), "Already initialized");
        auctionHouse = payable(_auctionHouse);
        indexCry = _indexCry;
    }
	
	function setWeth(address _wethContract) external{
		address publisher = CryptographFactoryStoragePublicV1(address(CryptographIndexStoragePublicV1(indexCry).factory())).officialPublisher();
		require(msg.sender == publisher);
		
		contractWETH = _wethContract;
	}

    /// @notice Transfer a cryptograph in the ERC2665 proxy
    /// @dev Call the internal transfer function
    /// @param _from The address of the previous owner
    /// @param _to The address of the new owner
    /// @param _cryptograph The address of the cryptrograph
    /// @param _lastSoldFor The amount of the last cryptograph platform transaction for this cryptograph
    function transferACryptograph(address _from, address _to, address _cryptograph, uint256 _lastSoldFor ) external {
        require((msg.sender == auctionHouse), "Only the cryptograph auction house smart contract can call this function");
        transferACryptographInternal(_from, _to, _cryptograph, _lastSoldFor);
    }


    //Called by the Index when a minting is happening
    function MintACryptograph(address _newCryptograph) external {
        require((msg.sender == indexCry), "Only the cryptograph index smart contract can call this function");
        index2665ToAddress[totalSupplyVar] = _newCryptograph;
        totalSupplyVar++;
        balanceOfVar[address(0)] = balanceOfVar[address(0)] + 1;
        isACryptograph[_newCryptograph] = true;

        //Weakness in ERC-721 spec : Created and assigned to address 0.
        //Meaning : let's not emit event
        // emit Transfer(address(0), address(0), uint256(_newCryptograph));
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external pure returns(bool) {

        return (
            interfaceID == 0x80ac58cd || //ERC721
            interfaceID == 0x5b5e139f || //metadata extension
            interfaceID == 0x780e9d63 || //enumeration extension
            interfaceID == 0x509ffea4 //ERC2665
        );
        
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0), "ERC721 NFTs assigned to the zero address are considered invalid");
        return balanceOfVar[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address){
        require(isACryptograph[address(_tokenId)], "_tokenId is not a Valid Cryptograph");
        address retour = TheCryptographLogicV1(address(_tokenId)).owner();
        require(retour != address(0),
            "ERC721 NFTs assigned to the zero address are considered invalid");
        return retour;
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `msg.value` < `getTransferFee(_tokenId)`.
    ///  If the fee is not to be paid in ETH, then token publishers SHOULD provide a way to pay the
    ///  fee when calling this function or it's overloads, and throwing if said fee is not paid.
    ///  Throws if `_to` is the zero address. Throws if `_tokenId` is not a valid NFT.
    ///  When transfer is complete, this function checks if `_to` is a smart
    ///  contract (code size > 0). If so, it calls `onERC2665Received` on `_to`
    ///  and throws if the return value is not
    ///  `bytes4(keccak256("onERC2665Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable{
        transferFromInternal(_from, _to, _tokenId, msg.sender, msg.value);

        require(_to != address(0));
        if(isContract(_to)){
            //bytes4(keccak256("onERC2665Received(address,address,uint256,bytes)")) == bytes4(0xac3cf292)
            require(ERC2665TokenReceiver(_to).onERC2665Received(msg.sender, _from, _tokenId, data) == bytes4(0xac3cf292));
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        transferFromInternal(_from, _to, _tokenId, msg.sender, msg.value);

        require(_to != address(0));
        if(isContract(_to)){
            //bytes4(keccak256("onERC2665Received(address,address,uint256,bytes)")) == bytes4(0xac3cf292)
            require(ERC2665TokenReceiver(_to).onERC2665Received(msg.sender, _from, _tokenId, "") ==  bytes4(0xac3cf292));
        }
    }

   /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. Throws if `msg.value` < `getTransferFee(_tokenId)`.
    ///  If the fee is not to be paid in ETH, then token publishers SHOULD provide a way to pay the
    ///  fee when calling this function and throw if said fee is not paid.
    ///  Throws if `_to` is the zero address. Throws if `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable{
        transferFromInternal(_from, _to, _tokenId, msg.sender, msg.value);
    }



    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner. After a successful call and if
    ///  `msg.value == getTransferFee(_tokenId)`, then a subsequent atomic call to
    ///  `getTransferFee(_tokenId)` would eval to 0. If the fee is not to be paid in ETH,
    ///  then token publishers MUST provide a way to pay the fee when calling this function,
    ///  and throw if the fee is not paid.
    ///  Any ETH sent to this function will be used to pay the transfer fee, and if the
    ///  ETH sent is twice (or more) the non-0 current transfer fee, the next transfer fee 
    ///  will be prepaid as well.  
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable{

        address owner = TheCryptographLogicV1(address(_tokenId)).owner();
        require(msg.sender == owner || approvedOperator[owner][msg.sender], "Only the owner or an operator can approve a token transfer");
        require(isACryptograph[address(_tokenId)], "_tokenId is not a Valid Cryptograph");

        //Reset the renatus timer
        TheCryptographLogicV1(address(_tokenId)).renatus();

        uint256 leftover = msg.value;

        //If the transfer fee is being paid
        if(leftover >= transferFees[_tokenId]){

            leftover =  leftover - transferFees[_tokenId];
            transferFees[_tokenId] = 0;
            
            //Prepay the next subsequent transfer
            if(leftover >= (lastSoldFor[_tokenId] * 15 /100)){
                leftover = leftover -  (lastSoldFor[_tokenId] * 15 /100);
                transferFeePrepaid[_tokenId] = true;
            }

        }

        //Marking the auction has now being handled by ERC2665
        AuctionHouseLogicV1(auctionHouse).approveERC2665{value: msg.value - leftover }(address(_tokenId), msg.sender, _approved);

        if(leftover != 0){
            //Send back the extra money to the payer
            (bool trashBool, ) = msg.sender.call{value:leftover}("");
            require(trashBool, "Could not send the leftover money back");
        }

        approvedTransferAddress[_tokenId] = _approved; 

        emit Approval(msg.sender, _approved, _tokenId);

    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        approvedOperator[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address){
        require(isACryptograph[address(_tokenId)], "_tokenId is not a Valid Cryptograph");

        return approvedTransferAddress[_tokenId];
    }
  
    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return approvedOperator[_owner][_operator];
    }

    /// @notice Query what is the transfer fee for a specific token
    /// @dev If a call would returns 0, then any subsequent calls witht the same argument
    /// must also return 0 until the Transfer event has been emitted.
    /// @param _tokenId The NFT to find the Transfer Fee amount for
    /// @return The amount of Wei that need to be sent along a call to a transfer function
    function getTransferFee(uint256 _tokenId) external view returns (uint256){
        return transferFees[_tokenId];
    }

    /// @notice Query what is the transfer fee for a specific token if the fee is to be paid
    /// @dev If a call would returns 0, then any subsequent calls with the same arguments
    /// must also return 0 until the Transfer event has been emitted. If _currencySymbol == 'ETH',
    /// then this function must return the same result as if `getTransferFee(uint256 _tokenId)` was called.
    /// @param _tokenId The NFT to find the Transfer Fee amount for
    /// @param _currencySymbol The currency in which the fee is to be paid
    /// @return The amount of Wei that need to be sent along a call to a transfer function
    function getTransferFee(uint256 _tokenId, string calldata _currencySymbol) external view returns (uint256){
        //keccak256(bytes("ETH")) == bytes32(0xaaaebeba3810b1e6b70781f14b2d72c1cb89c0b2b320c43bb67ff79f562f5ff4)
        //keccak256(bytes("WETH")) == bytes32(0x0f8a193ff464434486c0daf7db2a895884365d2bc84ba47a68fcf89c1b14b5b8)
        if(keccak256(bytes(_currencySymbol)) == bytes32(0xaaaebeba3810b1e6b70781f14b2d72c1cb89c0b2b320c43bb67ff79f562f5ff4) ||
            keccak256(bytes("WETH")) == bytes32(0x0f8a193ff464434486c0daf7db2a895884365d2bc84ba47a68fcf89c1b14b5b8)
        ){
            return transferFees[_tokenId];
        } else {
            return 0;
        }
    }


    function name() external pure returns(string memory _name){
        return "Cryptograph";
    }

    function symbol() external pure returns(string memory _symbol){
        return "Cryptograph";
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns(string memory){
        require(isACryptograph[address(_tokenId)], "_tokenId is not a Valid Cryptograph");
   
        return string(abi.encodePacked("https://cryptograph.co/tokenuri/", addressToString(address(_tokenId))));
    }


    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256){
        return totalSupplyVar;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256){
        require(_index < totalSupplyVar, "index >= totalSupply()");
        return uint256(index2665ToAddress[_index]);
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
        require(_owner != address(0), "_owner == 0");
        require(_index < balanceOfVar[_owner], "_index >= balanceOf(_owner)");

        return indexedOwnership[_owner][_index];
    }

    /// @notice Get the address of a Cryptograph from their tokenID
    /// @dev literally just a typecast
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the Cryptograph that would be associated with this ID
    function addressFromTokenId(uint256 _tokenId) external pure returns (address){
            return address(_tokenId);
    }

    /// @notice Get the tokenID of a Cryptograph from their address
    /// @dev literally just a typecast
    /// @param _tokenAddress The address for a Cryptograph
    /// @return The tokenId of the Cryptograph that would be associated with this address
    function tokenIdFromAddress(address _tokenAddress) external pure returns (uint256){
            return uint256(_tokenAddress);
    }

    /// @notice Extend the renatus timer for a cryptograph
    /// @dev only callable by approved operators or the owner
    /// @param _tokenId The identifier for an NFT
    function renatus(uint256 _tokenId) public {
        require(isACryptograph[address(_tokenId)], "renatus need to be called for a Valid Cryptograph");

        address owner = TheCryptographLogicV1(address(_tokenId)).owner();
        require(approvedOperator[owner][msg.sender] || owner == msg.sender);

        //Extending the renatus timer
        TheCryptographLogicV1(address(_tokenId)).renatus();
    }

    /// @notice Emit a Renatus transfer event destroying the token for it to be reborn later
    /// @dev only callable by the token itself
    function triggerRenatus() public{
        require(isACryptograph[msg.sender], "Only the token itself can notify us of a renatus hapenning");
        emit Transfer(TheCryptographLogicV1(address(msg.sender)).owner(), address(0), uint256(msg.sender));
    }
    
    /// @notice Transfer a cryptograph in the ERC2665 proxy
    /// @dev Will fire the Transfer event and update the enumerable arrays, as well as setting the new transfer fee
    /// @param _from The address of the previous owner
    /// @param _to The address of the new owner
    /// @param _cryptograph The address of the cryptrograph
    /// @param _lastSoldFor The amount of the last cryptograph platform transaction for this cryptograph
    function transferACryptographInternal(address _from, address _to, address _cryptograph, uint256 _lastSoldFor) internal{

        //Check that the Cryptograph exist
         require(isACryptograph[_cryptograph], 
            "Only minted cryptogrtaphs can be transferred");

        //Adjusting the last sold and transfer fees
        if(_lastSoldFor != lastSoldFor[uint256(_cryptograph)]){
            lastSoldFor[uint256(_cryptograph)] = _lastSoldFor;
        }

        //Checking if the fee was prepaid
        if(!transferFeePrepaid[uint256(_cryptograph)]){
            transferFees[uint256(_cryptograph)] = (_lastSoldFor * 15) / 100; //15% transfer fee
        } else {
            transferFees[uint256(_cryptograph)] = 0;
        }
        transferFeePrepaid[uint256(_cryptograph)] = false;
  

        //Reseting the approved address
        approvedTransferAddress[uint256(_cryptograph)] = address(0);


        //Emitting the event
        emit Transfer(_from, _to, uint256(_cryptograph));

        uint256 posInArray;

        //Adjusting the ownership array of the actors
        if(_from != address(0x0)){

            if(balanceOfVar[_from] != 1){

                //Case where we still have more cryptographs in the index.

                //Grabbing the position of the transferred cryptograph in the previous owner ownership array
                posInArray = cryptographPositionInOwnershipArray[uint256(_cryptograph)];

                //Replacing this position content with the content of the last element in the owner array;
                indexedOwnership[_from][posInArray] = indexedOwnership[_from][balanceOfVar[_from]-1];

                //Updating the last element new index position
                cryptographPositionInOwnershipArray[indexedOwnership[_from][posInArray]] = posInArray;

                //refund some gas
                delete indexedOwnership[_from][balanceOfVar[_from]-1];

            }  else {
                //refund some gas
                delete indexedOwnership[_from][0];
            }
        }

        //Some caching
        posInArray = balanceOfVar[_to];

        //Adjusting the arrays of the receiver
        if(_to != address(0x0)){

            if(indexedOwnership[_to].length < posInArray + 1){
                indexedOwnership[_to].push(uint256(_cryptograph));
            } else {
                indexedOwnership[_to][posInArray] = uint256(_cryptograph);
            }

            cryptographPositionInOwnershipArray[uint256(_cryptograph)] = posInArray;
        }

        //Adjusting the balance of the actors
        balanceOfVar[_from] = balanceOfVar[_from] - 1;
        balanceOfVar[_to] = balanceOfVar[_to] + 1;

    }


    /// @notice transferACryptograph following a TransferFrom call to an ERC2665 endpoint
    /// @dev Will call the transferInternal as part of the process as well as notify the ecosystem of necessary changes.
    /// @param _from The address of the previous owner
    /// @param _to The address of the new owner
    /// @param _tokenId The tokenID of the cryptrograph
    /// @param _sender The adress of the msg.sender of the endpoint
    /// @param _value The amount of ETH paid with the endpoint call
    function transferFromInternal(address _from, address _to, uint256 _tokenId, address _sender, uint256 _value) internal{


        //Check that the _from token owner is correct
        address owner = TheCryptographLogicV1(address(_tokenId)).owner();
        require(owner == _from,
            "The owner of the token and _from did not match");
    
        if(transferFees[_tokenId] != 0){ //Only collect fees if there is one to pay
            //If not sent an empty value, check if the fee was prepaid.
            if(_value != 0){
                require(_value >= transferFees[_tokenId], "The transfer fee must be paid");
            } else {
                //If the fee is not prepaid, try to ERC20 transfer WETH from the token owner
                address publisher = CryptographFactoryStoragePublicV1(address(CryptographIndexStoragePublicV1(indexCry).factory())).officialPublisher();

                //Transfer the WETH fee to PA main account
                ERC20Generic(contractWETH).transferFrom(owner, publisher, transferFees[_tokenId]);

                //The fee have been paid
                transferFees[_tokenId] = 0;
            }
        }


        //Check that the msg.sender is legitimate to manipulate the token
        require(_sender == owner || approvedOperator[owner][_sender] || approvedTransferAddress[_tokenId] == _sender, "The caller is not allowed to transfer the token");

        //Calculate how much extra fee was sent
        uint256 leftover = _value - transferFees[_tokenId];

        //ERC2665 Transfer, will reset transfer fee
        transferACryptographInternal(_from, _to, address(_tokenId), lastSoldFor[_tokenId]);

        //Actual Transfer will also check that there is no auction going on
        AuctionHouseLogicV1(auctionHouse).transferERC2665{value:  _value - leftover}(address(_tokenId), _sender, _to);

        //Check if the next fee is also paid
        if(leftover >= transferFees[_tokenId]){
            //pay the next transfer fee
            leftover =  leftover - transferFees[_tokenId];
            transferFees[_tokenId] = 0;
        }

        if(leftover != 0){
            //Send back the extra money to the payer
            (bool trashBool, ) = _sender.call{value:leftover}("");
            require(trashBool, "Could not send the leftover money back");
        }
    }


    /// @notice Convert an Ethereum address to a human readable string
    /// @param _addr The adress you want to convert
    /// @return The address in 0x... format
    function addressToString(address _addr) internal pure returns(string memory)
    {
        bytes32 addr32 = bytes32(uint256(_addr)); //Put the address 20 byte address in a bytes32 word
        bytes memory alphabet = "0123456789abcdef";  //What are our allowed characters ?

        //Initializing the array that is gonna get returned
        bytes memory str = new bytes(42);

        //Prefixing
        str[0] = '0';
        str[1] = 'x';

        for (uint256 i = 0; i < 20; i++) { //iterating over the actual address

            /*
                proper offset : output starting at 2 because of '0X' prefix, 1 hexa char == 2 bytes.
                input starting at 12 because of 12 bytes of padding, byteshifted because 2byte == 1char
            */
            str[2+i*2] = alphabet[uint8(addr32[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(addr32[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /// @notice Check if an address is a contract
    /// @param _address The adress you want to test
    /// @return true if the address has bytecode, false if not
    function isContract(address _address) internal view returns(bool){
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(_address) }
        return (codehash != accountHash && codehash != 0x0);
    }

}

