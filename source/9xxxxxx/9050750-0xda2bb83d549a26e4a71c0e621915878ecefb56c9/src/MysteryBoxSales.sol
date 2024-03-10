pragma solidity 0.5.9;

import "./Interfaces/ERC721.sol";
import "./AverageBlockTime.sol";

contract MysteryBoxSales is ERC721 {

    uint256 lastSaleId;
    struct Sale {
        ERC721[] nftContracts;
        uint256[] tokenIds;
        address payable seller;
        uint96 revealTime;
        address priceToken;
        uint128 price;
        uint128 fee;
        address[] participants;
        address payable revealer;
        string metadata;
    }

    mapping (uint256 => Sale) private sales;

    // revealTime => revealer => whether revealer was able to reveal in time
    mapping (uint256 => mapping(address => bool)) canGetReward;

    // revealTime => revealer => priceToken => fee to collect
    mapping (uint256 => mapping(address => mapping(address => uint256))) blockHashReward;

    AverageBlockTime averageBlockTimeOracle;

    constructor(AverageBlockTime _averageBlockTimeOracle) public {
        averageBlockTimeOracle = _averageBlockTimeOracle;
    }

    event MysteryBoxSaleCreated(
        uint256 saleId,
        string name,
        address indexed seller,
        uint96 revealTime,
        address priceToken,
        uint128 price,
        uint256[] tokenIds,
        ERC721[] tokenContracts,
        address indexed revealer,
        uint128 fee,
        string metadataURI
    );
    event BlockHash(uint256 indexed revealTime, bytes32 hash); // TODO separate contrat
    event MysteryBoxSaleWithdrawn(uint256 indexed saleId, address indexed seller);
    event MysteryBoxSaleProceedsWithdrawn(uint256 indexed saleId, address indexed seller, uint256 pay);

    event MysteryBoxBought(uint256 indexed saleId, uint256 participantIndex, address indexed buyer);
    event MysteryBoxWithdrawn(uint256 indexed saleId, uint256 participantIndex, address indexed buyer);

    function createSale(
        string calldata _name,
        ERC721[] calldata _nftContracts,
        uint256[] calldata _tokenIds,
        uint96 _revealTime,
        address payable _priceToken,
        uint128 _price,
        address payable _revealer,
        uint128 _fee,
        string calldata _metadata
    )
    external {
        require(_nftContracts.length == _tokenIds.length, "tokenIds length != nftContracts length");
        require(_fee <= _price, "fee too high");
        // solium-disable-next-line security/no-block-members
        require(_revealTime > block.timestamp, "revealTime in the past");

        _escrow(msg.sender, _nftContracts, _tokenIds, _tokenIds.length);
        address payable[3] memory addrs;
        addrs[0] = msg.sender;
        addrs[1] = _priceToken;
        addrs[2] = _revealer;
        _createSale(_name, _nftContracts, _tokenIds, addrs, [_revealTime, _price, _fee], _metadata);
    }

    function _createSale(
        string memory _name,
        ERC721[] memory _nftContracts,
        uint256[] memory _tokenIds,
        address payable[3] memory _addresses, // seller, priceToken, revealer
        uint128[3] memory _values, // _revealTime, price, fee
        string memory _metadata
    ) internal {
        uint256 saleId = ++lastSaleId;
        sales[saleId] = Sale(
            _nftContracts,
            _tokenIds,
            _addresses[0],
            uint96(_values[0]),
            _addresses[1],
            uint128(_values[1]),
            uint128(_values[2]),
            new address[](0),
            _addresses[2],
            _metadata
        );
        emit MysteryBoxSaleCreated(
            saleId,
            _name,
            _addresses[0],
            uint96(_values[0]),
            _addresses[1],
            uint128(_values[1]),
            _tokenIds,
            _nftContracts,
            _addresses[2],
            uint128(_values[2]),
            _metadata
        );
    }


    function buy(uint256 _saleId) public payable {
        gift(msg.sender, _saleId);
    }

    function numBoxesLeftToBuy(uint256 _saleId) external view returns(uint256) {
        // solium-disable-next-line security/no-block-members
        if(block.timestamp < sales[_saleId].revealTime) {
            return sales[_saleId].tokenIds.length - sales[_saleId].participants.length;
        } else {
            return 0;
        }
    }

    function gift(address recipient, uint256 _saleId) public payable { // TODO support erc20 native meta transaction ?
        Sale storage sale = sales[_saleId];
        address priceToken = sale.priceToken;
        uint256 numTokens = sale.tokenIds.length;
        uint256 numParticipants = sale.participants.length;
        uint256 revealTime = sale.revealTime;
        // solium-disable-next-line security/no-block-members
        require(block.timestamp < revealTime, "not on sale");
        require(numParticipants < numTokens, "all mystery boxes has been purchased");

        sale.participants.push(recipient);
        // shuffling as we go by swapping tokenIds + corresponding nftContracts
        if(numTokens > 2) {
            bytes32 lastBlockHash = blockhash(block.number-1);
            uint256 swap1 = uint256(keccak256(abi.encodePacked(lastBlockHash, uint8(1)))) % numTokens;
            uint256 swap2 = uint256(keccak256(abi.encodePacked(lastBlockHash, uint8(2)))) % numTokens;
            if(swap1 == swap2) {
                swap1 = (swap2 + 1) % numTokens;
            }
            uint256 t1 = sale.tokenIds[swap1];
            sale.tokenIds[swap1] = sale.tokenIds[swap2];
            sale.tokenIds[swap2] = t1;
            ERC721 c1 = sale.nftContracts[swap1];
            ERC721 c2 = sale.nftContracts[swap2];
            if(c1 != c2) {
                sale.nftContracts[swap1] = c2;
                sale.nftContracts[swap2] = c1;
            }
        }

        {
            uint256 price = sale.price;
            // record fee to be rewarded to revealer once blockHash is saved
            blockHashReward[revealTime][sale.revealer][priceToken] += sale.fee;

            if(priceToken == address(0)) {
                require(msg.value == price, "msg.value != price");
            } else {
                require(transferTokenFrom(priceToken, msg.sender, address(this), price), "failed to transfer price");
            }
        }

        emit MysteryBoxBought(_saleId, numParticipants, recipient); // TODO remove and use ERC721 Transfer event below

        // ERC721
        numBoxes[recipient] ++;
        emit Transfer(address(0), recipient, _saleId * 2**128 + numParticipants); // MINT
    }

    mapping(uint256 => bytes32) blockHashes;

    function getBlockHash(uint256 time) external returns(bytes32) {
        return blockHashes[time]; // TODO rename blockHashes to blockHashesAtTime
    }

    function getRevealerReward(uint256 revealTime, address revealer, address priceToken) external returns(uint256) {
        return blockHashReward[revealTime][revealer][priceToken];
    }

    function withdrawRevealerReward(uint256 revealTime, address priceToken) external {
        require(canGetReward[revealTime][msg.sender], "did not reveal in time");
        uint256 reward = blockHashReward[revealTime][msg.sender][priceToken];
        require(reward > 0, "not reward to collect");
        blockHashReward[revealTime][msg.sender][priceToken] = 0;
        canGetReward[revealTime][msg.sender] = false;
        if (priceToken == address(0)) {
            msg.sender.transfer(reward);
        } else {
            require(transferToken(priceToken, msg.sender, reward), "failed to transfer fee to revealer");
        }
        // TODO event ?
    }

    function recordBlockHash(uint256 revealTime) external{
        _recordBlockHash(revealTime, msg.sender);
    }

    function _recordBlockHash(uint256 revealTime, address revealer) internal returns(bytes32) {
        // solium-disable-next-line security/no-block-members
        require(revealTime < block.timestamp, "cannot record a future or present reveal");
        // solium-disable-next-line security/no-block-members
        uint256 delay = block.timestamp - revealTime;
        uint256 averageBlockTimeInMicroSeconds = averageBlockTimeOracle.getAverageBlockTimeInMicroSeconds();
        uint256 blockDelay = ((delay * 1000) / averageBlockTimeInMicroSeconds );
        require(blockDelay > 0, "cannot get current blockHash, retry later");
        uint256 blockNumber = block.number - blockDelay;
        bytes32 blockHash = blockHashes[revealTime];

        // blockHash > 0 allows revealer to get the reward later of someone alreayd revealed
        if (revealer != address(0) && (blockHash > 0 || blockDelay < 256) && !canGetReward[revealTime][revealer]) {
            canGetReward[revealTime][revealer] = true;
        }

        if (blockHash > 0) {
            return blockHash; // already recorded
        }

        if(blockDelay < 256) {
            blockHash = blockhash(blockNumber);
        } else {
            blockHash = blockhash(block.number - (((blockDelay - 1) % 255) + 1));
        }
        blockHashes[revealTime] = blockHash;
        emit BlockHash(revealTime, blockHash);
        return blockHash;
    }

    function withdrawToSeller(uint256 _saleId) external {
        withdrawToSellerRange(_saleId, 0, 2**256-1);
    }

    // solium-disable-next-line security/no-assign-params
    function withdrawToSellerRange(uint256 _saleId, uint256 start, uint256 end) public {
        Sale storage sale = sales[_saleId];
        bytes32 blockHash = blockHashes[sale.revealTime];
        address payable seller = sale.seller;
        require(blockHash != 0, "sale has not been revealed");
        require(seller != address(0), "sale already withdrawn");

        uint256 numParticipants = sale.participants.length;
        uint256 price = sale.price;
        if(price > 0 && numParticipants > 0) {
            uint256 pay = numParticipants * (price - sale.fee);
            address priceToken = sale.priceToken;
            if(address(priceToken) == address(0)) {
                seller.transfer(pay);
            } else {
                require(transferToken(priceToken, seller, pay), "cannot transfer pay to seller");
            }
            sale.price = 0;
            emit MysteryBoxSaleProceedsWithdrawn(_saleId, seller, pay);
        }

        uint256 numTokens = sale.tokenIds.length;
        uint256 firstTokenIndex = getTokenIndexReceived(blockHash, _saleId, numParticipants);
        if(end > numTokens - numParticipants) {
            end = numTokens - numParticipants;
        }
        for(uint256 i = start; i < end; i++) {
            uint256 tokenIndex = (firstTokenIndex + i) % numTokens;
            sale.nftContracts[tokenIndex].transferFrom(address(this), seller, sale.tokenIds[tokenIndex]);
            sale.nftContracts[tokenIndex] = ERC721(0);
            sale.tokenIds[tokenIndex] = 0;
        }

        if(end == numTokens - numParticipants) {
            emit MysteryBoxSaleWithdrawn(_saleId, seller);
            sale.seller = address(0);
        }
    }

    function _splitID(uint256 _tokenId) internal pure returns(uint256 saleId, uint256 participantIndex) {
        saleId = _tokenId / 2**128;
        participantIndex = uint128(_tokenId);
    }

    // ERC721 BOX STANDARD ? ////////////////////////////////////////////////
    function open(uint256 _tokenId) external {
        (uint256 saleId, uint256 participantIndex) = _splitID(_tokenId);
        withdrawToken(saleId, participantIndex);
    }

    function peek(uint256 _tokenId) external view returns(ERC721 nftContract, uint256 tokenId) {
        (uint256 saleId, uint256 participantIndex) = _splitID(_tokenId);
        bytes32 blockHash = blockHashes[sales[saleId].revealTime];
        if(blockHash == 0) {
            return (ERC721(0),0);
        }
        return getTokenReceived(saleId, participantIndex);
    }
    //////////////////////////////////////////////////////////////////////////

    function withdrawTokensInBatch(uint256 _saleId, uint256[] calldata _participantIndices) external {
        bytes32 blockHash;
        {
            uint256 revealTime = sales[_saleId].revealTime;
            blockHash = blockHashes[revealTime];
            if( blockHash == 0) {
                blockHash = _recordBlockHash(revealTime, address(0)); // if no blockHash make it yourself but do not record reward
            }
        }

        uint256 numParticipants = sales[_saleId].participants.length;
        uint256 numIndices = _participantIndices.length;
        for(uint256 i = 0; i < numIndices; i++) {
            uint256 _participantIndex = _participantIndices[i];
            require(_participantIndex < numParticipants, "particpantIndex too big");
            address participant = sales[_saleId].participants[_participantIndex];
            require(participant == msg.sender, "participants not matching");
            sales[_saleId].participants[_participantIndex] = address(0);
            {
                uint256 tokenIndex = getTokenIndexReceived(blockHash, _saleId, _participantIndex);
                sales[_saleId].nftContracts[tokenIndex].transferFrom(address(this), participant, sales[_saleId].tokenIds[tokenIndex]);
                sales[_saleId].nftContracts[tokenIndex] = ERC721(0);
                sales[_saleId].tokenIds[tokenIndex] = 0;
                emit MysteryBoxWithdrawn(_saleId, _participantIndex, participant); // TODO remove and use ERC721 Transfer event below ?
            }

            // ERC721
            emit Transfer(participant, address(0), _saleId * 2**128 + _participantIndex); // BURN // no need to reset operator
        }
        // ERC721
        numBoxes[msg.sender] -= numIndices;
    }

    function withdrawToken(uint256 _saleId, uint256 _participantIndex) public {
        uint256 revealTime = sales[_saleId].revealTime;
        bytes32 blockHash = blockHashes[revealTime];
        if( blockHash == 0) {
            blockHash = _recordBlockHash(revealTime, address(0)); // if no blockHash make it yourself but do not record reward
        }
        require(_participantIndex < sales[_saleId].participants.length, "particpantIndex too big");
        address participant = sales[_saleId].participants[_participantIndex];
        require(participant == msg.sender, "only participant can withdrawn");
        sales[_saleId].participants[_participantIndex] = address(0);
        uint256 tokenIndex = getTokenIndexReceived(blockHash, _saleId, _participantIndex);
        sales[_saleId].nftContracts[tokenIndex].transferFrom(address(this), participant, sales[_saleId].tokenIds[tokenIndex]);
        sales[_saleId].nftContracts[tokenIndex] = ERC721(0);
        sales[_saleId].tokenIds[tokenIndex] = 0;
        emit MysteryBoxWithdrawn(_saleId, _participantIndex, participant); // TODO remove and use ERC721 Transfer event below ?

        // ERC721
        numBoxes[participant] --;
        emit Transfer(participant, address(0), _saleId * 2**128 + _participantIndex); // BURN
    }

    function getTokenIndexReceived(bytes32 blockHash, uint256 _saleId, uint256 _participantIndex) internal view returns(uint256 tokenIndex) {
        return (uint256(keccak256(abi.encodePacked(blockHash, _saleId))) + _participantIndex) % sales[_saleId].tokenIds.length;
    }

    function getTokenReceived(uint256 _saleId, uint256 _participantIndex) internal view returns(ERC721 nftContract, uint256 tokenId) {
        uint256 index = getTokenIndexReceived(blockHashes[sales[_saleId].revealTime], _saleId, _participantIndex);
        return (sales[_saleId].nftContracts[index], sales[_saleId].tokenIds[index]);
    }

     function isReadyForReveal(
        uint256 _saleId
    )
        external
        view
        returns
    (bool) {
        bytes32 blockHash = blockHashes[sales[_saleId].revealTime];
        // solium-disable-next-line security/no-block-members
        return sales[_saleId].revealTime > 0 && blockHash == 0 && block.timestamp > sales[_saleId].revealTime;
    }

    function exists(uint256 _saleId) external view returns (bool) {
        return sales[_saleId].revealTime > 0;
    }

    function getRevealedToken(
        uint256 _saleId,
        uint256 _participantIndex
    ) external view returns (ERC721 nftContract, uint256 tokenId){
        bytes32 blockHash = blockHashes[sales[_saleId].revealTime];
        if(blockHash == 0) {
            return (ERC721(0),0);
        }
        return getTokenReceived(_saleId, _participantIndex);
    }

    function _escrow(
        address _seller,
        ERC721[] memory _nftContracts,
        uint256[] memory _tokenIds,
        uint256 _numToEscrow
    ) internal {
        for(uint256 i = 0; i < _numToEscrow; i++){
            address ownerOfToken = _nftContracts[i].ownerOf(_tokenIds[i]);
            require(ownerOfToken == _seller, "only the owner can be seller");
            _nftContracts[i].transferFrom(ownerOfToken, address(this), _tokenIds[i]);
        }
    }

    /// ERC721 ///////////////
    mapping(uint256 => address) operators;
    mapping(address => mapping(address => bool)) operatorsForAll;
    mapping(address => uint256) numBoxes;

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "token does not exist");
        return numBoxes[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address){
        (uint256 saleId, uint256 participantIndex) = _splitID(_tokenId);
        address[] storage participants = sales[saleId].participants;
        address owner = participants[participantIndex];
        require(owner != address(0), "token does not exist");
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external {
        _transferFrom(_from, _to, _tokenId);
        require(_checkERC721Receiver(_from, _to, _tokenId, data), "erc721 transfer rejected");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(_from, _to, _tokenId);
        require(_checkERC721Receiver(_from, _to, _tokenId, ""), "erc721 transfer rejected");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(_from, _to, _tokenId);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0), "token does not exist");
        require(_from != address(0), "from is zero address");
        address operator = operators[_tokenId];
        require(msg.sender == _from || operatorsForAll[_from][_to] || msg.sender == operator, "not approved");
        (uint256 saleId, uint256 participantIndex) = _splitID(_tokenId);
        require(sales[saleId].participants[participantIndex] == _from, "current owner != _from");
        sales[saleId].participants[participantIndex] = _to;
        if (operator != address(0)) {
            operators[_tokenId] = address(0);
        }
        numBoxes[_from] --;
        numBoxes[_to] ++;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        (uint256 saleId, uint256 participantIndex) = _splitID(_tokenId);
        require(sales[saleId].participants[participantIndex] == msg.sender, "current owner != msg.sender");
        operators[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external{
        require(_operator != address(0), "operator is zero address");
        operatorsForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address){
        ownerOf(_tokenId);
        return operators[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        require(_owner != address(0), "token does not exist");
        require(_operator != address(0), "operator is zero address");
        return operatorsForAll[_owner][_operator];
    }

    bytes4 constant ERC721_RECEIVED = 0x150b7a02;
    function _checkERC721Receiver(address _from, address _to, uint256 _id, bytes memory _data) internal returns (bool) {
        if (!isContract(_to)) {
            return true;
        }
        return (ERC721TokenReceiver(_to).onERC721Received(_from, _from, _id, _data) == ERC721_RECEIVED);
    }

    /// ERC721 Metadata
    function name() external view returns (string memory _name) {
        return "Mystery Market";
    }

    function symbol() external view returns (string memory _symbol) {
        return "MYSTERY";
    }

    function toHexString(uint256 x) internal pure returns (string memory) {
        uint256 numZeroes = numZeroesFor(x);
        bytes memory s = new bytes(64 - numZeroes);
        uint256 start = numZeroes / 2;
        for (uint i = start; i < 32; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(31 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));

            uint256 index = 2*(i-start);
            s[index] = char(hi);
            s[index+1] = char(lo);
        }
        return string(s);
    }

    function numZeroesFor(uint256 x) internal pure returns (uint256) {
        uint256 numZeroes = 0;
        for (uint256 i = 0; i < 32; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(31 - i)))));
            if (b != 0) {
                break;
            }
            numZeroes += 2;
        }
        return numZeroes;
    }

    function char(byte b) internal pure returns (byte c) {
        if (uint8(b) < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        ownerOf(_tokenId);
        (uint256 saleId, uint256 participantIndex) = _splitID(_tokenId);
        string memory metadataURI = sales[saleId].metadata;
        bytes memory bs = bytes(metadataURI);
        if (bs.length > 7 &&
            bs[0] == 'h' &&
            bs[1] == 't' &&
            bs[2] == 't' &&
            bs[3] == 'p'
        ) {
            return
            string(
                abi.encodePacked(
                    metadataURI,
                    "/metadata_0x",toHexString(_tokenId),
                    ".json"
                )
            );
        } else {
            return metadataURI;
        }
    }

    function peekTokenURI(uint256 _tokenId) external view returns (string memory) {
        ownerOf(_tokenId);
        (uint256 saleId, uint256 participantIndex) = _splitID(_tokenId);
        bytes32 blockHash = blockHashes[sales[saleId].revealTime];
        if(blockHash != 0) {
            (ERC721 nftContract, uint256 tokenId) = getTokenReceived(saleId, participantIndex);
            return nftContract.tokenURI(tokenId);
        }
        return sales[saleId].metadata;
    }

    /// ERC165
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return interfaceID == 0x01ffc9a7 || interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }

    /// UTILS
    function isContract(address addr) internal view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codehash;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function transferToken (
        address token,
        address receiver,
        uint256 amount
    )
        internal
        returns (bool transferred)
    {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let success := call(sub(gas, 10000), token, 0, add(data, 0x20), mload(data), 0, 0)
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            switch returndatasize
            case 0 { transferred := success }
            case 0x20 { transferred := iszero(or(iszero(success), iszero(mload(ptr)))) }
            default { transferred := 0 }
        }
    }

    function transferTokenFrom (
        address token,
        address from,
        address receiver,
        uint256 amount
    )
        internal
        returns (bool transferred)
    {
        bytes memory data = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, receiver, amount);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let success := call(sub(gas, 10000), token, 0, add(data, 0x20), mload(data), 0, 0)
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            switch returndatasize
            case 0 { transferred := success }
            case 0x20 { transferred := iszero(or(iszero(success), iszero(mload(ptr)))) }
            default { transferred := 0 }
        }
    }

}

