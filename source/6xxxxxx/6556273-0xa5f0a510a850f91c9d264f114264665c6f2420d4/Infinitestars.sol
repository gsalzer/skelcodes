pragma solidity ^0.4.24;

library Ball {
    

    
    //uint256 public constant QUEUE_INT_SIZE = 100 ether;
    
    struct Data{
        uint256 index;
        address owner;
        uint256 outCount;
        uint createAt;
    }
    
    struct Queue{
        uint256 startIdx;
        uint256 size ;
        mapping(uint256 => Data) map;
    }
    
    function lifo(Data[] storage ds,Data ind) internal  returns(Data  ans){
        ans = ds[0];
        for(uint256 i=0;i<ds.length-1;i++){
            Data storage nd = ds[i+1];
            ds[i] = nd;
        }
        ds[ds.length-1] = ind;
    }
    
    function getByIndex(Data[] storage ds,uint256 idx) internal view returns(Data storage ) {
        for(uint256 i=0;i<ds.length;i++){
            Data storage d = ds[i];
            if(idx ==d.index){
                return d;
            }
        }       
        revert("not find getByIndex Ball");
    }
    
    function isBrandNew(Data storage d) internal view returns(bool){
        return d.owner == address(0);
    }
    
    function replace(Data storage tar,Data  sor) internal {
        tar.index = sor.index;
        tar.owner = sor.owner;
        tar.outCount = sor.outCount;
        tar.createAt = sor.createAt;
    }
    
    function removeByIndex(Data[] storage array,uint256 index) internal {
        if (index >= array.length) return;

        for (uint256 i = index; i<array.length-1; i++){
            array[i] = array[i+1];
        }
        delete array[array.length-1];
        array.length--;
    }
    
    
    function removeByOwner(Data[] storage ds,address owner,uint256 count) internal{
        for(uint256 i=0;i<ds.length;i++){
            if( ds[i].owner == owner ) {
                removeByIndex(ds,i);
                i--;
                count--;
            }
            if(count ==0) return;
        }
        revert("removeByOwner count not = 0");
    }
    
    function countByOwner(Data[] storage ds,address owner) internal view returns(uint256 ans){
        for(uint256 i=0;i<ds.length;i++){
            if( ds[i].owner == owner ) {
                ans++;
            }
        }        
    }
    
    

    function getEnd(Queue storage q)  internal view returns(uint256 ){
            return q.startIdx + q.size;
    }        
    
    function getWishEnd(Queue storage q,uint256 wishSize)  internal view returns(uint256 ){
        if(q.size > wishSize){
            return q.startIdx + wishSize;
        }else{
            return q.startIdx + q.size;
        }
    }    
    



    
    function getRealIdx(Queue storage q,uint256 index) internal view  returns(uint256 ){
        uint256 realIdx = q.startIdx + index;
         require(getEnd(q)>realIdx,"getEnd()>q.startIdx+idx");
        return realIdx;
    }
    
    function get(Queue storage q,uint256 index) internal view returns(Data ){
        return q.map[getRealIdx(q,index)];
    }
    
    function offer(Queue storage q,Data b) internal {
        uint256 lastIdx= q.size ++;
        q.map[getRealIdx(q,lastIdx)] = b;
    }
    
    function removeAtStart(Queue storage q,uint256 count)  internal{
        require(q.size >= count ,"getSize(q) >= count");
        for(uint256 i=q.startIdx;i<getWishEnd(q,count);i++){
            delete q.map[i];
        }
        q.startIdx += count;
        q.size -= count;
        
    }
    
    
    
    
}

library CommUtils{

    function removeByIdx(uint256[] array,uint256 idx) public pure returns(uint256[] memory){
        uint256[] memory ans = copy(array,array.length-1);
        while((idx+1) < array.length){
            ans[idx] = array[idx+1];
            idx++;
        }
        return ans;
    }
    
    function copy(uint256[] array,uint256 len) public pure returns(uint256[] memory){
        uint256[] memory ans = new uint256[](len);
        len = len > array.length? array.length : len;
        for(uint256 i =0;i<len;i++){
            ans[i] = array[i];
        }
        return ans;
    }
    
    function getHash(uint256[] array) public pure returns(uint256) {
        uint256 baseStep =100;
        uint256 pow = 1;
        uint256 ans = 0;
        for(uint256 i=0;i<array.length;i++){
            ans= ans+ uint256(array[i] *pow ) ;
            pow= pow* baseStep;
        }
        return ans;
    }
    
    function contains(address[] adrs,address adr)public pure returns(bool){
        for(uint256 i=0;i<adrs.length;i++){
            if(adrs[i] ==  adr) return true;
        }
        return false;
    }

    
    function random(uint256 max,uint256 mixed) public view returns(uint256){
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        hashVal += 31*uint256(block.coinbase);
        hashVal += 19*mixed;
        hashVal += 17*uint256(block.difficulty);
        hashVal += 13*uint256(block.gaslimit );
        hashVal += 11*uint256(now );
        hashVal += 7*uint256(block.timestamp );
        hashVal += 3*uint256(tx.origin);
        return uint256(hashVal % max);
    } 
    
    function getIdxArray(uint256 len) public pure returns(uint256[]){
        uint256[] memory ans = new uint256[](len);
        for(uint128 i=0;i<len;i++){
            ans[i] = i;
        }
        return ans;
    }
    
    function genRandomArray(uint256 digits,uint256 templateLen,uint256 base) public view returns(uint256[]) {
        uint256[] memory ans = new uint256[](digits);
        uint256[] memory idxs  = getIdxArray( templateLen);
       for(uint256 i=0;i<digits;i++){
            uint256  idx = random(idxs.length,i+base);
            uint256 wordIdx = idxs[idx];
            ans[i] = wordIdx;
            idxs = removeByIdx(idxs,idx);
           
       }
       return ans;
    }
   
   
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subb(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    
   /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function multiplies(uint256 a, uint256 b) 
        private 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }
    
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = multiplies(z,x);
            return (z);
        }
    }
    
    function pwrFloat(uint256 tar,uint256 numerator,uint256 denominator,uint256 pwrN) public pure returns(uint256) {
        for(uint256 i=0;i<pwrN;i++){
            tar = tar * numerator / denominator;
        }
        return tar ;
        
    }

    
    function mulRate(uint256 tar,uint256 rate) public pure returns (uint256){
        return tar *rate / 100;
    }  
    
    
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }    
    
    
}


contract Infinitestars {
    
    using Player for Player.Map;
    using CommUtils for string;
    using InfinitestarsData for InfinitestarsData.Data;
    using Ball for Ball.Data[];
    uint256 public constant WITHDRAWAL_AUTO_BUY_COUNT = 1;
    uint256 public constant BALL_PRICE = 0.5 ether;
    uint256 public constant REGESTER_FEE = 0.02 ether;
    uint256 public constant REGISTER_FREE_COUNT = 100;
    InfinitestarsData.Data data;
    uint256 private regesterCount =0;
    bool private gameEnabled = false;


    function enableGame() public{
        require(Player.isAdmin(msg.sender),"it`s not admin");
        gameEnabled = true;
    }
    
    modifier enabling(){
        require(gameEnabled,"game not start");
        _;
    }

    function buyBall(uint256 count) enabling public payable  {
        uint256 sp =data.buyBall(count,msg.sender);
        broadcastBuy(msg.sender,count,sp);
    }
    
    function broadcastBuy(address adr,uint256 count,uint256 starsPickValue) private {
        bytes32 b = data.players.getName(adr);
        emit OnBuyed (adr,b,count,starsPickValue);
    }
    
    function buyBallWithReferrer(uint256 count,string referrer) enabling public payable  {
        uint256 sp =data.buyBallWithReferrer(count,msg.sender,referrer);
        broadcastBuy(msg.sender,count,sp);
    }    

    function getInit()  public view returns(
        bytes32, //0 your name
        bytes32, //1  refername
        uint256,  //2 currentIdx
        uint256,    //3 shourt Prize
        uint256,     //4 the player gains
        uint256,     //5 refferSumReward
        bool ,      //6 played
        uint256 ,    //7 blance
        uint256     //8  Your live ball
    
    ){
       // (uint256 count,uint256 firstAt,uint256 lastAt, uint256 payOutCount,uint256 nextPayOutAt) = data.getOutInfoOfSender();
        return (
            data.players.getName(),
            data.players.getReferrerName(msg.sender),
            data.currentIdx,
            data.shortPrize,
            data.players.getAmmount(msg.sender),
            data.referralbonusMap[msg.sender],
            data.playedMap[msg.sender],
            address(this).balance,
            data.balls.countByOwner(msg.sender)
        );
    }
    
    
    function getOutInfoOfSender()  public view returns(
            uint256 , //your out ball
            uint256 , //firstAt
            uint256 ,  //lastAt      
            uint256,   //  payOutCount,
            uint256 ,   //   nextPayOutAt    
            uint256     // payedCount
        ){
        return data.getOutInfoOfSender();
    }      

    
    function outBall() enabling public {
        data.toPayedBall();
        data.toOutBall();
    }
    
    function listLiveBall() public view returns(
        uint256[] , //index;
        address[] , //owner;
        uint256[] , //outCount;
        uint[]  //createAt;
        ){
        return listBall(data.balls);
    }
    
    function listBall(Ball.Data[] list) private pure returns(
        uint256[] indexs, //index;
        address[] owners, //owner;
        uint256[] outCounts, //outCount;
        uint[] createAts //createAt;
        ){
        indexs = new uint256[](list.length);    
        owners = new address[](list.length);    
        outCounts = new uint256[](list.length);    
        createAts = new uint[](list.length);    
        for(uint256 i=0;i<list.length;i++){
            indexs[i]=list[i].index;
            owners[i]=list[i].owner;
            outCounts[i]=list[i].outCount;
            createAts[i]=list[i].createAt;
        }
        
    }
    
  
    
    function registerName(string  name) enabling public payable {
        require(msg.value >= REGESTER_FEE,"fee not enough");
        require(data.playedMap[msg.sender] ,"it`s not play");
        regesterCount++;
        data.registerName(name);
        if(REGISTER_FREE_COUNT>=regesterCount){
            data.players.deposit(msg.sender,REGESTER_FEE);
        }
    }    
    
    function isEmptyName(string _n) public view returns(bool){
        return data.players.isEmptyName(_n.nameFilter());
    }    
    
    
    function withdrawalBuy(uint256 ammount) enabling public payable{
        
        address self = msg.sender;
        uint256 fee = CommUtils.mulRate(ammount,1);
        uint256 gains = data.players.getAmmount(msg.sender);
        uint256 autoPayA = WITHDRAWAL_AUTO_BUY_COUNT*BALL_PRICE;
        ammount-= fee;
        require(ammount<=gains ,"getAmmount is too low ");
        require(data.balls.countByOwner(self)>0 ,"must has live ball ");
        require(gains >= autoPayA,"gains >= autoPayA");
        require(ammount>= autoPayA,"ammount>= ammount");
        data.players.transferAuthor(fee);
        ammount -= autoPayA;
        data.buyBall(WITHDRAWAL_AUTO_BUY_COUNT,self);
        uint256 contractBlc = address(this).balance;
        bool b =false;
        if(contractBlc >= ammount){
            data.players.minus(self,ammount);
            self.transfer(ammount);
            b= true;
        }else if(ammount>=BALL_PRICE){
            uint256 mod = ammount % BALL_PRICE;
            uint256 count = (ammount - mod) / BALL_PRICE;
            data.buyBall(count,self);
            data.players.deposit(msg.sender,mod);
            b= true;
        }        
        emit OnWithdrawaled (self,ammount,b); 
    }
    

    event OnBuyed(
        address buyer,
        bytes32 buyerName,
        uint256 count,
        uint256 starsPickValue
    );
    
    event OnWithdrawaled(
        address who,
        uint256 ammount,
        bool ok
    );
    
    

}



library InfinitestarsData {
    

    using Ball for Ball.Data[];
    using Ball for Ball.Queue;
    using Ball for Ball.Data;
    using Player for Player.Map;
    using CommUtils for string;
    
    
    uint256 public constant  LIVE_BALL_COUNT = 3;
    uint256 public constant BALL_PRICE = 0.5 ether;
    uint256 public constant FEE = BALL_PRICE /100;
    uint256 public constant OUT_LIMT = 2;
    uint256 public constant SHORT_PRIZE_PLUS = BALL_PRICE * 3 / 100;
    uint256 public constant LEVEL_1_REWARD = BALL_PRICE * 10 /100;
    uint256 public constant LEVEL_2_REWARD = BALL_PRICE * 3 /100;
    uint256 public constant LEVEL_3_REWARD = BALL_PRICE * 2 /100;
    uint256 public constant MAINTTAIN_FEE =  BALL_PRICE * 1 /100;
    uint256 public constant OUT_TIME = 60*60*24*2;
    uint256 public constant PAY_TIME = 60*60*24*1;
    //uint256 public constant OUT_TIME = 60*8;
    //uint256 public constant PAY_TIME = 60*4 ;
    
    uint256 public constant QUEUE_BATCH_SIZE = 30;
    //uint256 public constant OUT_TIME = 60;
    uint256 public constant PAY_PROFIT = 0.085 ether;
    //uint256 public constant PAY_AMMOUNT = (BALL_PRICE* 40/100) - FEE;

    
    struct Data{
        Ball.Data[] balls ;
        Ball.Queue outingBalls ;
        Ball.Queue payedQueue ;
        Player.Map players;
        uint256 shortPrize;
        uint256 currentIdx;
        mapping(address => bool) playedMap;
        mapping(address => uint256) playBallCountMap;
        mapping(address=> uint256 ) referralbonusMap;      
    }


    function getOutInfoOfSender(Data storage d) internal view returns(
            uint256 count,
            uint256 firstAt,
            uint256 lastAt,
            uint256 payOutCount,
            uint256 nextPayOutAt,
            uint256 payedCount
        ){
        // (uint256 stI , uint256 endI ) = d.outingBalls.getRange();    
         for(uint256 i=d.outingBalls.startIdx;i<d.outingBalls.getEnd();i++){
            Ball.Data storage ob = d.outingBalls.map[i];  
            if(ob.owner == msg.sender){
                if(firstAt==0  ||  ob.createAt<firstAt){
                    firstAt = ob.createAt;
                }
                if(lastAt == 0 || ob.createAt > lastAt){
                    lastAt = ob.createAt;
                }
                if( (now - ob.createAt) > PAY_TIME ){
                    payOutCount ++;
                }else{
                   if(nextPayOutAt==0) nextPayOutAt = ob.createAt;
                }
                count++;
            }
        }
         for( i=d.payedQueue.startIdx;i<d.payedQueue.getEnd();i++){
            ob = d.payedQueue.map[i];  
            if(ob.owner == msg.sender){
                if(firstAt==0  ||  ob.createAt<firstAt){
                    firstAt = ob.createAt;
                }
                if(lastAt == 0 || ob.createAt > lastAt){
                    lastAt = ob.createAt;
                }
                payOutCount ++;
                payedCount++;
                count++;
            }
        }         
         
        firstAt = now - firstAt;
        lastAt = now - lastAt;
        nextPayOutAt = now - nextPayOutAt;
    }

    function buyBallWithReferrer(Data storage d,uint256 count,address owner,string referrer) internal returns (uint256) {
        require(!d.playedMap[msg.sender] ,"it`s not play game player can apply referrer");
        d.players.applyReferrer(referrer);
        return buyBall(d,count,owner);
    }
    
    function buyBall(Data storage d,uint256 count,address owner) internal returns (uint256) {
        d.players.withdrawalFee(count *BALL_PRICE);
        for(uint256 i=0;i<count;i++){
            claimBall(d,owner);            
        }
        d.playedMap[owner] = true;
        d.playBallCountMap[owner] += count;
        d.players.transferAuthorAll();
        toPayedBall(d);
        toOutBall(d);
        return drawShortPrize(d,count);
    }
    
    // function reviveBall(Data storage d,uint256 count) internal {
    //     d.outingBalls.removeByOwner(msg.sender,count);
    //     buyBall(d,count,msg.sender);
    // }
    
    function drawShortPrize(Data storage d,uint256 count) private returns (uint256 ans) {
        uint256 threshold = count * 5 ;
        uint256 value = CommUtils.random(1000,5);
        if(threshold>value){
            ans = d.shortPrize;
            d.players.deposit(msg.sender,d.shortPrize);
            d.shortPrize = 0;
        }
    }
    
    function claimBall(Data storage d,address _owner) private{
        Ball.Data memory b = Ball.Data({
            index : d.currentIdx++,
            owner : _owner,
            outCount : 0,
            createAt : now
        });
        require(d.balls.length <= LIVE_BALL_COUNT ,"live ball is over 3");
        if(d.balls.length <LIVE_BALL_COUNT){
            d.balls[d.balls.length++] = b;
        }else{
            Ball.Data memory outb= lifo(d,b);
            revive(d,outb);
        }
        distributeReward(d,_owner);
        
    }
    
    function distributeReward(Data storage d,address _owner) private {
        d.players.depositAuthor(FEE);
        d.players.depositAuthor(MAINTTAIN_FEE);
        d.shortPrize += SHORT_PRIZE_PLUS;
        address l1 = d.players.getReferrer(_owner);
        if(l1 == address(0)){
            d.players.depositAuthor(LEVEL_1_REWARD + LEVEL_2_REWARD + LEVEL_3_REWARD);
            return ;
        }
        depositReferrer(d,l1,LEVEL_1_REWARD);
        address l2 = d.players.getReferrer(l1);
        if(l2 == address(0)){
            d.players.depositAuthor( LEVEL_2_REWARD + LEVEL_3_REWARD);
             return ;
        }
        depositReferrer(d,l2,LEVEL_2_REWARD);
        address l3 = d.players.getReferrer(l2);
        if(l3 == address(0)){
            d.players.depositAuthor(  LEVEL_3_REWARD);
            return;
        }
        depositReferrer(d,l3,LEVEL_3_REWARD);
    }
    
    function depositReferrer(Data storage d,address a,uint256 v) private {
        d.players.deposit(a,v);
        d.referralbonusMap[a]+= v;
    }
    
    function lifo(Data storage d,Ball.Data  inb) private returns(Ball.Data ans){
        ans = d.balls.lifo(inb);
        d.players.depositAuthor(FEE);
        //d.players.deposit(ans.owner,PAY_AMMOUNT);
    }
    
    
    function revive(Data storage d,Ball.Data b) private{
        require(b.outCount<=OUT_LIMT,"outCount>OUT_LIMT");
         if(b.outCount==OUT_LIMT){
            d.players.deposit(b.owner,PAY_PROFIT);
            b.createAt = now;
            //Ball.Data storage outP= d.outingBalls[d.outingBalls.length ++];
            d.outingBalls.offer(b);
            //outP.replace(b);
        }else{
            b.outCount ++;
            b.index = d.currentIdx++;
            Ball.Data memory newOut  = lifo(d,b);
            revive(d,newOut);
        }
    }
    
    function registerName(Data storage d,string  name) internal  {
        require(d.playedMap[msg.sender] ,"it`s  play game player can registerName");
        require(msg.value >= 0.02 ether);
        require(d.players.getName()=="");
        d.players.registerName(name.nameFilter());
    }    
    
    
    function toOutBall(Data storage d) internal{
        
        uint256 end  = d.payedQueue.getWishEnd(QUEUE_BATCH_SIZE);
        uint256 rmCount = 0;
        for(uint256 i=d.payedQueue.startIdx;i<end;i++){
            Ball.Data storage b = d.payedQueue.map[i];

            if(now - b.createAt> OUT_TIME ){
                address owner = b.owner;
                d.playBallCountMap[owner]--;
                rmCount++;
                removePlayerBallEmpty(d,owner);
            }
        }
        d.payedQueue.removeAtStart( rmCount);
    }
    
    function toPayedBall(Data storage d) internal{
        uint256 end = d.outingBalls.getWishEnd(QUEUE_BATCH_SIZE);
        uint256 rmCount = 0;
        for(uint256 i=d.outingBalls.startIdx;i<end;i++){
            Ball.Data storage b = d.outingBalls.map[i];
            if(now - b.createAt >= PAY_TIME ){
                d.players.deposit(b.owner,BALL_PRICE);
                rmCount++;
                d.payedQueue.offer(b);
            }
        }   
        d.outingBalls.removeAtStart(rmCount);
    }
    
    function removePlayerBallEmpty(Data storage d,address addr) private{
        uint256 allBallCount = d.playBallCountMap[addr] ;
        if(allBallCount <= 0){
            d.players.remove(addr);
            delete d.playedMap[addr];
        }
    }
    
    
}

library Player{

    using CommUtils for string;

    address public constant AUTHOR =  0x001C9b3392f473f8f13e9Eaf0619c405AF22FC26a7;
    address public constant DIRECTOR = 0x43beFdf21996f323E3cE6552452F11Efb7Dc1e7D;
    uint256 public constant AUTHOR_RATE = 8;
    
    struct Map{
        mapping(address=>uint256) map;
        mapping(address=>address) referrerMap;
        mapping(address=>bytes32) addrNameMap;
        mapping(bytes32=>address) nameAddrMap;
    }
    
    function remove(Map storage ps,address adr) internal{
        transferAuthor(ps,ps.map[adr]);
        delete ps.map[adr];
        bytes32 b = ps.addrNameMap[adr];
        delete ps.nameAddrMap[b];
        delete ps.addrNameMap[adr];
    }
    
    function deposit(Map storage  ps,address adr,uint256 v) internal returns(uint256) {
       ps.map[adr]+=v;
        return v;
    }

    function isAdmin(address addr) internal pure returns (bool){
        if(addr == AUTHOR) return true;
        if(addr == DIRECTOR) return true;
        if(addr == address(0x00e37c73dbe66e92149092a85be6c32e23251ed0af)) return true;
        return false;
    }

    function depositAuthor(Map storage  ps,uint256 v) internal returns(uint256) {
        uint256 devFee = CommUtils.mulRate(v,AUTHOR_RATE);
        uint256 dFee =  v- devFee;
        deposit(ps,AUTHOR,devFee);
        deposit(ps,DIRECTOR,dFee);
        return v;
    }
    
    function transferAuthorAll(Map storage  ps) internal{
        transferSafe(ps,AUTHOR, withdrawalAll(ps,AUTHOR));
        transferSafe(ps,DIRECTOR, withdrawalAll(ps,DIRECTOR));
    }
    
    function transferSafe(Map storage  ps,address addr,uint256 v) internal {
        
        if(address(this).balance>=v){
            addr.transfer(v);
        }else{
            uint256 less = v - address(this).balance;
            addr.transfer( address(this).balance);
            deposit(ps,addr,less);
        }
    }
    
    //depositAuthor
    function transferAuthor(Map storage  ps,uint256 v) internal returns(uint256) {
        uint256 devFee = CommUtils.mulRate(v,AUTHOR_RATE);
        uint256 dFee =  v- devFee;
        transferSafe(ps,AUTHOR,devFee);
        transferSafe(ps,DIRECTOR,dFee);
        return v;
    }

    function minus(Map storage  ps,address adr,uint256 num) internal  {
        uint256 sum = ps.map[adr];
        if(sum==num){
             withdrawalAll(ps,adr);
        }else{
            require(sum > num);
            ps.map[adr] = sum-num;
        }
    }
    
    function minusAndTransfer(Map storage  ps,address adr,uint256 num) internal  {
        minus(ps,adr,num);
        transferSafe(ps,adr,num);
    }    
    
    function withdrawalAll(Map storage  ps,address adr) public returns(uint256) {
        uint256 sum = ps.map[adr];
        delete ps.map[adr];
        return sum;
    }
    
    function getAmmount(Map storage ps,address adr) public view returns(uint256) {
        return ps.map[adr];
    }
    
    function registerName(Map storage ps,bytes32 _name)internal  {
        require(ps.nameAddrMap[_name] == address(0) );
        ps.nameAddrMap[_name] = msg.sender;
        ps.addrNameMap[msg.sender] = _name;
        depositAuthor(ps,msg.value);
    }
    
    function isEmptyName(Map storage ps,bytes32 _name) public view returns(bool) {
        return ps.nameAddrMap[_name] == address(0);
    }
    
    function getByName(Map storage ps,bytes32 _name)public view returns(address) {
        return ps.nameAddrMap[_name] ;
    }
    
    function getName(Map storage ps) public view returns(bytes32){
        return ps.addrNameMap[msg.sender];
    }
    
    function getName(Map storage ps,address adr) public view returns(bytes32){
        return ps.addrNameMap[adr];
    }    
    
    function getNameByAddr(Map storage ps,address adr) public view returns(bytes32){
        return ps.addrNameMap[adr];
    }    
    
    function getReferrer(Map storage ps,address adr)public view returns(address){
        address refA = ps.referrerMap[adr];
        bytes32 b= ps.addrNameMap[refA];
        return b.length == 0 ? getReferrer(ps,refA) : refA;
    }
    
    function getReferrerName(Map storage ps,address adr)public view returns(bytes32){
        return getNameByAddr(ps,getReferrer(ps,adr));
    }
    
    function setReferrer(Map storage ps,address self,address referrer)internal {
         ps.referrerMap[self] = referrer;
    }
    
    function applyReferrer(Map storage ps,string referrer)internal {
        bytes32 rbs = referrer.nameFilter();
        address referrerAdr = getByName(ps,rbs);
        if(referrerAdr != msg.sender){
            setReferrer(ps,msg.sender,referrerAdr);
        }
    }    
    
    function withdrawalFee(Map storage ps,uint256 fee) public returns (uint256){
        if(msg.value > 0){
            require(msg.value >= fee,"msg.value < fee");
            return fee;
        }
        require(getAmmount(ps,msg.sender)>=fee ,"players.getAmmount(msg.sender)<fee");
        minus(ps,msg.sender,fee);
        return fee;
    }   
    
}
