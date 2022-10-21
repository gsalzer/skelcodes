pragma solidity ^0.5.0;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

}


contract Ownable {
  address payable public owner;
  address private manager;

  constructor() public {
    owner = msg.sender;
    manager = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  modifier onlyOwnerOrManager() {
     require((msg.sender == owner)||(msg.sender == manager), "only for owner or manager");
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = address(uint160(newOwner));
  }

  function setManager(address _manager) public onlyOwnerOrManager {
      manager = _manager;
  }
 
}

contract BigFamily is Ownable {
    event eventJoin(address indexed _user, address indexed _father);
    event eventPay(address indexed _from, address indexed _to, uint256 _amount);
    //event eventDebug(uint number);
    
    uint256 constant public DEFAULT_JOIN_FEE = 0.5 ether;
    uint256 constant private DEFAULT_JOIN_FEE_1 = DEFAULT_JOIN_FEE - 0.05 ether;
    uint256 constant private DEFAULT_JOIN_FEE_2 = DEFAULT_JOIN_FEE - 0.1 ether;
    uint256 constant private DEFAULT_JOIN_FEE_3 = DEFAULT_JOIN_FEE - 0.15 ether;
    uint256 constant private DEFAULT_JOIN_FEE_4 = DEFAULT_JOIN_FEE - 0.2 ether;
    uint256 constant private DEFAULT_JOIN_FEE_5 = DEFAULT_JOIN_FEE - 0.25 ether;
    uint256 constant private MIN_JOIN_FEE = 0.2 ether;

    struct Family{
        address[] mOffsprings;
        address mGrandParent;
        uint256 mJoinFee;
        uint256 mIncome;
    }
    
    mapping (address => Family) private mFamilies;
    address[] private mParents;//for mapping keys
    
    //////////////////////////////////////////////////////////////////////////////

    constructor() public {
        mParents.push(msg.sender);
        mFamilies[msg.sender].mJoinFee = DEFAULT_JOIN_FEE_1;
    }
    
    function getJoinFee(address _parent) public view returns(uint256){
        uint256 NS = mFamilies[_parent].mOffsprings.length;
        if(NS > 0) {
            if (NS <= 5) return DEFAULT_JOIN_FEE_1;
            else if(NS <= 20) return DEFAULT_JOIN_FEE_2;
            else if(NS <= 50) return DEFAULT_JOIN_FEE_3;
            else if(NS <= 100) return DEFAULT_JOIN_FEE_4;
            else if(NS <= 500) return DEFAULT_JOIN_FEE_5;
            else return MIN_JOIN_FEE;
        }else if(checkJoined(_parent)){
            return DEFAULT_JOIN_FEE_1;
        }
        else{
            return DEFAULT_JOIN_FEE;
        }
    }
    
    function getLowestJoinFee() public view returns(uint256){
        uint256 minFee = DEFAULT_JOIN_FEE;
        for(uint i=0; i<mParents.length; i++){
            address father = mParents[i];
            uint256 fee = mFamilies[father].mJoinFee;
            if (fee < minFee)
                minFee = fee;
            if (minFee == MIN_JOIN_FEE) //Note the lenght could be large
                return MIN_JOIN_FEE;
         }
         return minFee;
    }

    function selectParentWithFee(uint256 _fee) internal view returns(address){
        if(_fee < MIN_JOIN_FEE) return address(0);
        
        uint PN = mParents.length; //Note the mParent lenght could increase at anytime; fee could decrease at anytime
        uint256 N = 0;
        for(uint i=0; i<PN; i++){
             address father = mParents[i];
             uint256 fee = mFamilies[father].mJoinFee;
             if (_fee >= fee){
                N += 1;
             }
        }
        if (N > 0){
            uint256 index = 0;
            address[] memory candidates = new address[](N);
            for(uint i=0; i<PN; i++){
                 address father = mParents[i];
                 uint256 fee = mFamilies[father].mJoinFee;
                 if (_fee >= fee){
                    candidates[index] = father;
                    index += 1;
                 }
                 if (index >= N)
                    break;
            }
            index = block.timestamp % N;
            return candidates[index];
        }else{
            return address(0);
        }
    }
    
    function checkParentExist(address _parent) public view returns(bool){
        for(uint i=0; i< mParents.length; i++){
            if(mParents[i] == _parent)
                return true;
        }
        return false;
    }
    
    function findParent(address _offspring) public view returns(address){
        for(uint i=0; i<mParents.length; i++){
            address[] memory sons = mFamilies[mParents[i]].mOffsprings;
            for(uint j=0; j<sons.length; j++){
                if (_offspring == sons[j]) return mParents[i];
            }
        }
        
        return address(0);
    }
    
    function checkJoined(address _from) public view returns(bool) {
        if (checkParentExist(_from)) return true;
        
        for(uint i=0; i<mParents.length; i++){
            address[] memory sons = mFamilies[mParents[i]].mOffsprings;
            for(uint j=0; j<sons.length; j++){
                if (_from == sons[j]) return true;
            }
        }
        
        return false;
    }
    
    function joinFamily(address payable _parent) public payable {
        require(_parent != msg.sender, "Father can't be yourself.");
        require(!checkJoined(msg.sender), "You already joined."); 
        uint256 fee = getJoinFee(_parent);
        require(msg.value >= fee, "insufficient joining fee");
        
        emit eventPay(msg.sender, address(this), msg.value);
         
        if(!checkParentExist(_parent)){
            //then the sender is the ancestor
            mParents.push(msg.sender);
            mFamilies[msg.sender].mJoinFee = DEFAULT_JOIN_FEE_1;
            emit eventJoin(msg.sender, address(0));
        }else{
            mFamilies[_parent].mOffsprings.push(msg.sender);
            if (mFamilies[_parent].mGrandParent == address(0)){
                address gp = findParent(_parent);
                if (gp != address(0))
                    mFamilies[_parent].mGrandParent = gp;
            }
            mFamilies[_parent].mJoinFee = getJoinFee(_parent);
            
            //pay for parent 
            uint256 ff = SafeMath.div(SafeMath.mul(fee, 7), 10);
            _parent.transfer(ff);
            mFamilies[_parent].mIncome += ff;
            emit eventPay(address(this), _parent, ff);
            
            //pay for grandparent if exists
            address payable gp = address(uint160(mFamilies[_parent].mGrandParent));
            if (gp != address(0)){
                uint256 gf = SafeMath.div(SafeMath.mul(fee, 2), 10);
                gp.transfer(gf);
                emit eventPay(address(this), gp, gf);
            }
            
            emit eventJoin(msg.sender, _parent);
        }
        
    }
    
    function becomeAncestor() public payable{
        joinFamily(address(0));
    }
    
    function autoSelectParent() public view returns(address){
        uint256 minFee = getLowestJoinFee();
        require(minFee>=MIN_JOIN_FEE, "Joining fee calculation error!");
        address father = selectParentWithFee(minFee);
        return father;
    }
    
    function withdraw() public onlyOwnerOrManager {
        address payable self = address(uint160(address(this)));
        if (self.balance >= 0.1 ether)
            owner.transfer(self.balance);
    }
    
    function checkBalance() public view onlyOwnerOrManager returns(uint256){
        address payable self = address(uint160(address(this)));
        return self.balance;
    }
    
    function countChildern(address _from) public view returns(uint256){
        if (checkParentExist(_from)){
            uint cn = 0;
            for(uint i=0; i<mParents.length; i++){
                cn += mFamilies[mParents[i]].mOffsprings.length;
            }
            return cn;
        }else{
            return 0;
        }
    }
    
    function countGrandChildern(address _from) public view returns(uint256){
        if (checkParentExist(_from)){
            uint cn = 0;
            for(uint i=0; i<mParents.length; i++){
                address parent = mParents[i];
                for (uint j=0; j<mFamilies[parent].mOffsprings.length; j++){
                    address child = mFamilies[parent].mOffsprings[j];
                    if (checkParentExist(child)){
                        cn += mFamilies[child].mOffsprings.length;
                    }
                }
            }
            return cn;
        }else{
            return 0;
        }
    }
    
    function getIncome(address _from) public view returns(uint256){
        if (checkParentExist(_from)){
            for(uint i=0; i<mParents.length; i++){
                if(mParents[i] == _from)
                    return mFamilies[mParents[i]].mIncome;
            }
            return 0;
        }else{
            return 0;
        }
    }

    function countFamily() public view returns(uint256){
        return mParents.length;
    }

    function checkChild(address _from, address _child) public view returns(bool){
        if (checkParentExist(_from)){
            for(uint i=0; i<mParents.length; i++){
                if(mParents[i] == _from){
                    address[] memory children = mFamilies[mParents[i]].mOffsprings;
                    for(uint j=0; j<children.length; j++){
                        if(children[j] == _child)
                            return true;
                    }
                }
            }
            return false;
        }else{
            return false;
        }
    }

    function checkOwner(address _from) public view returns(bool){
        if(_from == owner) return true;
        else return false;
    }
    

}
