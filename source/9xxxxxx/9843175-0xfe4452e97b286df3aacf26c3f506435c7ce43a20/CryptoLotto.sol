pragma solidity >=0.4.21 <0.6.0;

contract CryptoLotto {
  uint256 constant public TxCharge = 0.01 * 1 ether;
  uint256 constant public MaxFund = 50 * 1 ether;
  uint256 constant public MinDrawValue = 0.1 * 1 ether;
  uint256 constant public MinSponsorValue = 0.5 * 1 ether;
  
  event EventDraw(address drawer, int code); 
  event EventSponsor(address sponsor, int code); 
  event EventDebug(uint256 code); 
  
  uint8 public ITEM_NUMBER;
  address payable mContractOwner;
  
  struct Lotto_info{
      uint256 mFund;
      address payable mSponsor;
      bool mLocked;
      uint256 mTxNum;
  }
  mapping(uint8 => Lotto_info) mLottoItems;
 
  constructor(uint8 _itemNumber) public {
    require(_itemNumber > 0);
    ITEM_NUMBER = _itemNumber;
    mContractOwner = msg.sender;
  }
  
  function getDifficulty(uint8 itemID) public view returns(uint256){
      require(itemID >=0 && itemID < ITEM_NUMBER);
      uint256 curFund = mLottoItems[itemID].mFund;
      uint256 factor = curFund / MinDrawValue;
      return  factor * factor;
  }
  
  function sponsorable(uint8 itemID) public view returns(bool){
       require(itemID >=0 && itemID < ITEM_NUMBER);
       uint256 curFund = mLottoItems[itemID].mFund;
       if(curFund == 0) return true;
       else return false;
  }
  
  function becomeSponsor(uint8 itemID) public payable returns(bool){
      require(itemID >=0 && itemID < ITEM_NUMBER);
      require(msg.value >= MinSponsorValue);
      require(sponsorable(itemID));
      
      if (!mLottoItems[itemID].mLocked){
          mLottoItems[itemID].mLocked = true;
          mLottoItems[itemID].mFund = msg.value;
          mLottoItems[itemID].mSponsor = msg.sender;
          mLottoItems[itemID].mLocked = false;
          emit EventSponsor(msg.sender, 1);
          return true;
      }else{
        msg.sender.transfer(msg.value);
        emit EventSponsor(msg.sender, 0);
        return false; //revert the fund
      }
  }
  
  function drawable(uint8 itemID) public view returns(bool){
      if(itemID >=0 && itemID < ITEM_NUMBER && mLottoItems[itemID].mFund >= MinSponsorValue)
        return true;
      else
        return false;
  }
 
  function draw(uint8 itemID, uint256 guess, uint256 seed) public payable returns(int) {
    require(drawable(itemID));
    require(msg.value >= MinDrawValue);
    
    if (!mLottoItems[itemID].mLocked){
      uint256 curFund = mLottoItems[itemID].mFund;
      curFund += msg.value;
      
      uint256 difficulty = getDifficulty(itemID);
      //emit EventDebug(difficulty); 
      uint256 rnd = rand(seed, difficulty);
      //emit EventDebug(rnd); 
      if (rnd == guess % difficulty){
          require(curFund > TxCharge);
          require(curFund <= address(this).balance);
          uint256 reward = curFund - TxCharge;
          
          mLottoItems[itemID].mLocked = true;
          msg.sender.transfer(reward);
          mLottoItems[itemID].mFund = 0;
          mLottoItems[itemID].mTxNum = 0;
          mLottoItems[itemID].mSponsor = address(0);
          mContractOwner.transfer(TxCharge);          
          mLottoItems[itemID].mLocked = false;
          
          emit EventDraw(msg.sender, 1);
          return 1; //lucky draw
      }else if(curFund >= MaxFund){ //reach the max fund, then the sponsor gets the rewards
          require(curFund > TxCharge);
          require(curFund <= address(this).balance);
          uint256 reward = curFund - TxCharge;
          
          mLottoItems[itemID].mLocked = true;
          mLottoItems[itemID].mSponsor.transfer(reward);
          mLottoItems[itemID].mFund = 0;
          mLottoItems[itemID].mTxNum = 0;
          mLottoItems[itemID].mSponsor = address(0);
          mContractOwner.transfer(TxCharge);          
          mLottoItems[itemID].mLocked = false;
          
          emit EventDraw(msg.sender, 2);
          return 2; //this round is over
      }
      else{
          require(msg.value > TxCharge);
          
          mLottoItems[itemID].mLocked = true;
          mLottoItems[itemID].mFund += msg.value - TxCharge;
          mLottoItems[itemID].mTxNum += 1;
          mContractOwner.transfer(TxCharge);
          mLottoItems[itemID].mLocked = false;
          
          emit EventDraw(msg.sender, -1);
          return -1; //unlucky
      }
    }else{
      msg.sender.transfer(msg.value);
      emit EventDraw(msg.sender, 0);
      return 0; //revert the fund
    }
  }
  

  function getTxNum(uint8 itemID) public view returns(uint256){
    require(itemID >=0 && itemID < ITEM_NUMBER);
    return mLottoItems[itemID].mTxNum;
  }
  
  function checkReward(uint8 itemID) public view returns(uint256){
    require(itemID >=0 && itemID < ITEM_NUMBER);
    return mLottoItems[itemID].mFund;
  }
  
  function rand(uint256 seed, uint max) private view returns (uint256 result){
      /*
      uint256 lastBlockNumber = block.number - 1;
      uint256 hashVal = uint256(blockhash(lastBlockNumber));
      return uint256((hashVal + seed) % max);
      */ //the above does not work on JVM
      return uint256((block.timestamp + block.difficulty + seed) % max);
  }

  function isOwner(address _from, uint8 itemID) public view returns(bool){
    require(itemID >=0 && itemID < ITEM_NUMBER);
    return mLottoItems[itemID].mSponsor == _from;
  }

}
