//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./IERC1155.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC20.sol";
import "./VRFConsumerBase.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

/**
 * @title DrawCard
 * @dev draw card contract
 */
contract DrawCards is ReentrancyGuard, Pausable, VRFConsumerBase{
    
    address public operatorAddress;
    address public dealAddress;
    
    uint256 constant private DRAW_CARD_FEE = 100 * 10 ** 18;
    uint256 constant private INIT_BALANCE_A = 500;
    uint256 constant private INIT_BALANCE_B = 1000;
    uint256 constant private MAX_DRAW_COUNT = 10;
    /* Here are the VRF details for Ethereum mainnet:
      KeyHash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
      Coordinator: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
      Fee: 2000000000000000000 */

    /* mainnet link param */
    uint256  public linkFee = 2 * 10 ** 18; // 2 LINK
    bytes32 constant private keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 public linkRandomResult;
    uint256 private randomNonce;

    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    bool public isInit;
    bool public randomFlag;

    IERC1155 private nft;
    IERC20 private mee;

    event ExchangeCard1(address user, uint256 value);
    event DrawMyCards(address user, uint256[] ids);

    modifier onlyOperator() {
        require(operatorAddress == _msgSender(), "DrawCard: not operator call");
        _;
    }

    /* mainnet constructor */
    constructor(address _operatorAddress, address _dealAddress, address _nft, address _mee) public VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) {
        require(!isContract(_dealAddress),"DrawCard: make sure not contract address");
        operatorAddress = _operatorAddress;
        dealAddress = _dealAddress;
        nft = IERC1155(_nft);
        mee = IERC20(_mee);
    } 


    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /** 
     * @notice received card 
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external nonReentrant returns(bytes4) {

        require(msg.sender == address(nft), "DrawCard: only accept self nft");

        _receiveCards(_from,_id,_amount,_data);

        _operator;
        
        return ERC1155_RECEIVED_VALUE;
    }

    /** 
     * @notice batch received 
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external nonReentrant returns(bytes4) {
        require(msg.sender == address(nft), "DrawCard: only accept self nft");
        require(_ids.length == _amounts.length,"DrawCard: id length must equal amount length");

        for (uint256 i = 0; i < _ids.length; i++) {
            _receiveCards(_from,_ids[i],_amounts[i],_data);
        }

        _operator;
        
        return ERC1155_BATCH_RECEIVED_VALUE;
    }
   
    function _receiveCards(address _from, uint256 _id, uint256 _amount, bytes memory _data) internal pure{
        require(_from == address(0x0),"DrawCard: must mint card");
        require(_id >= 1 && _id <= 6,  "DrawCard: card id not good");

        if(_id != 1) {
            require(_amount == INIT_BALANCE_B);
        }else{
            require(_amount == INIT_BALANCE_A);
        }

        _data;
    }
    
    /** 
     * @notice when card is ready for init 
     */
    function init() public onlyOperator{
        require(!isInit,"DrawCard: already init!");
        
        for (uint256 i = 2; i <= 6; i++) {
            /* token 2 - 5 is 1000 piece */
            require(nft.balanceOf(address(this),i) == INIT_BALANCE_B,"DrawCard: cards value not right!");
        }
        /* token 1 is 500 piece */
        require(nft.balanceOf(address(this),1) == INIT_BALANCE_A,"DrawCard: cards value not right!");

        isInit = true;
    }
    
    /**
     * @notice draw card functions
     * @param time draw card time
     * @param seed seed for produce a random number
     */
    function drawCard(uint256 time, uint256 seed) public whenNotPaused nonReentrant {
        require(isInit,"DrawCard: not init yet!");
        require(time > 0 && time <= MAX_DRAW_COUNT,"DrawCard: draw card time not good!");
        require(time <= countCard(),"DrawCard: not enough card!");

        uint256 costMee = DRAW_CARD_FEE.mul(time);
        require(mee.transferFrom(msg.sender,dealAddress,costMee),"DrawCard: failed to transfer token!");

        if(randomFlag){
          _getRandomNumber(seed);
          seed = linkRandomResult;
        }
        
        uint256[] memory ids = new uint256[](5);

        for(uint256 i = 0; i < time; i++) {
          uint256 id = _drawCard(seed);
          nft.safeTransferFrom(address(this),msg.sender,id,1,"");
          ids[id.sub(2)] = ids[id.sub(2)].add(1);
          randomNonce = randomNonce.add(1);
        }

        emit DrawMyCards(msg.sender,ids);
    }

    /** 
     * @notice check if have card for lottery
     * @return count the remain card count
     */
    function countCard() public view returns(uint256 count){
        for(uint256 i = 2; i <= 6; i++){
            count = count.add(nft.balanceOf(address(this),i));
        }
    }
    
    function _drawCard(uint256 _seed) internal view returns(uint256 id){
        uint256 _id = _getRand(_seed).mod(5).add(2);
        id = _backRightId(_id);
    }
    
    function _getRandomNumber(uint256 _userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= linkFee, "DrawCard: Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, linkFee, _userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        requestId;
        linkRandomResult = randomness;
    }

    function _getRand(uint256 _seed) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender,blockhash(block.number),block.difficulty,block.coinbase,now,randomNonce,_seed)));
    }

    function _backRightId(uint256 _id)internal view returns(uint256) {
        uint256 rawId = _id;
      
        for(rawId; rawId <= rawId.add(4); rawId++){
            uint256 id;
            id = rawId > 6 ? rawId.mod(6).add(1) : rawId;
            if(nft.balanceOf(address(this),id) > 0) {
                return id;
            }
        }

        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    /** 
     * @notice transfer cards to deal address for exchange id 1 card 
     */
    function exchangeCard1(uint256 number) public whenNotPaused nonReentrant{
       require(number > 0, "DrawCard: can not exchange 1 card 0 piece!");
       require(nft.balanceOf(address(this),1) >= number,"DrawCard: not enought card 1 for exchange!");
       
       uint256[] memory ids = new uint256[](5);
       uint256 value = number.mul(2);
       uint256[] memory values = new uint256[](5);
       
       for(uint256 i = 0; i < 5; i++) {
           ids[i] = i.add(2);
           values[i] = value;
       }
       
       nft.safeBatchTransferFrom(msg.sender,dealAddress,ids,values,"");
       
       /* transfer card 1 for user */
       nft.safeTransferFrom(address(this), msg.sender, 1, number, "");

       emit ExchangeCard1(msg.sender,number);
    }

    /****** Operator Functions ******/
    function setRandomFlag(bool flag) public onlyOperator {
        randomFlag = flag;
    }

    function pause() public onlyOperator{
       _pause();
    }

    function unpause() public onlyOperator {
      _unpause();
    }

    //@dev link request randomNumber fee in mainnet is 2 link, in case the fee change
    function setLinkFee(uint256 fee) public onlyOperator {
      linkFee = fee;
    }

    //@notice withdraw the remain link in this contract
    function withdrawLink() public onlyOperator {
      uint256 value = LINK.balanceOf(address(this));
      require(value > 0, "DrawCard: insufficient link value for withdraw");
      require(LINK.transfer(operatorAddress,value),"DrawCard: transfer link failed");
    }

}

