pragma solidity ^0.5.12;

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender)external view returns(uint256);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract Future1exchange {
    
    using SafeMath for uint256;
    
    address public owner;
    address public feeAddress;
    uint32 public requestCancelMinimumTime;
    uint256 public referPercent;
    
    // events ---
    event Created(bytes32 _tradeHash);
    event SellerCancelDisabled(bytes32 _tradeHash);
    event SellerRequestedCancel(bytes32 _tradeHash);
    event CancelledBySeller(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash);
    event Released(bytes32 _tradeHash);
    event DisputeResolved(bytes32 _tradeHash);

    constructor (address feeadd) public {
        owner = msg.sender;
        feeAddress = feeadd;
        requestCancelMinimumTime = 2 hours;
    }

    struct Escrow {
        bool escrowStatus;
        uint256 setTimeSellerCancel;
        uint256 sellerFee;
        uint256 buyerFee;
        uint256 eType;
        bool sellerDispute;
        bool buyerDispute;
    }
    
     struct User{
        address userAddr;
        address referralAddr;
        address referralTokenAddr;
        uint256 referralType;
        bool registerStatus;
    }
    
    mapping (address => User) public referral_map;
    mapping (bytes32 => Escrow) public escrow_map;
    mapping (address => mapping(address => uint256)) public _token;
    mapping (address => mapping(address => uint256)) public _referralFee;
    mapping (bytes32 => bool) private hashComformation;
    
    
    modifier onlyOwner() {
        require(msg.sender == owner, "This function is  only called by Owner..");
        _;
    }
    
    /** @dev external - Set the new owner address, only called by current owner.
     * @param _newOwner - The new owner address.
     */
    function setOwner(address _newOwner) onlyOwner external {
        require(_newOwner != address(0), "Invalid Address");
        owner = _newOwner;
    }
    
    /** @dev external - Set the new fee address, only called by  owner.
     * @param _newFeeAddress - The new fee address.
     */
    function setFeeAddress(address _newFeeAddress) onlyOwner external {
        require(_newFeeAddress != address(0), "Invalid Address");
        feeAddress = _newFeeAddress;
    }
    
    /** @dev external - Set the new owner address, only called by  owner.
     * @param _newRequestCancelMinimumTime - The new time for requestCancel.
     */
    function setRequestCancellationMinimumTime(uint32 _newRequestCancelMinimumTime) onlyOwner external {
        requestCancelMinimumTime = _newRequestCancelMinimumTime;
    }
    
    /** @dev external - Set the new owner address, only called by  owner.
     * @param _feePercent - The new fee percent.
     */
    function setFeePercent(uint256 _feePercent) onlyOwner external {
        require(_feePercent > 0, "Invalid Fee Percent");
        referPercent = _feePercent;
    }
    
    /** @dev external - Collect the referral fee from user.
     * @param _from - The Address who send the fee to the contract for referral.
     * @param _tokenContract - The Token Contract Address which is selected for referrance by _from.
     * @param _amount - The Fee Amount
     * @return bool - true.
     */
    function feeCollect(address _from,address _tokenContract, uint256 _amount) external returns(bool) {
        require(_from != address(0) && _tokenContract != address(0), "Empty Address");
        require(tokenallowance(_tokenContract,_from,address(this)) >= _amount, "Insufficient Allowance");
        Token(_tokenContract).transferFrom(_from,address(this),_amount);
        _referralFee[_from][_tokenContract] = _referralFee[_from][_tokenContract].add(_amount);
        return true;
    }

    /** @dev external - Create the escrow process only call by seller.
     * @param _tradeId - The unique id for particular trade.
     * @param _user - _user[0] - _seller, _user[1] - _buyer, _user[2] - _tokenContract - The token contract address for token  (or) give address(0) for ether.
     * @param _amount - The escrow amount of particular trade is ether/token.
     * @param _sellerFee - The seller transaction/admin fee .
     * @param _buyerFee - The buyer transaction/admin fee.
     * @param _type - If the amount is ether it is 1 otherwise it is 2.
     * @param _sellerCancelInSeconds - To time for cancel the trade by seller.
     * @param _ref[0] - The referral address for seller, _Ref[1] -  The referral address for buyer.
     * @param _Tokens[0] -  The referral token address for seller, _Tokens[1] - The referral token address for buyer.
     * @param _Type[0] - The referral type for seller is 0 - ether / 1 - token, _Type[1] - The referral type for buyer 0 - ether / 1 - token.
     * @param _mrs - _mrs[0]- _messageHash, _mrs[1] - r of signature , _mrs[2] - s of signature.
     * @param _v - v of signature
     * @return bool - true.
     */
    function createEscrow(uint16 _tradeId,address[3] calldata _user, uint256 _amount,uint256 _sellerFee, uint256 _buyerFee,uint16 _type,uint32 _sellerCancelInSeconds, address[2] calldata _ref, address[2] calldata _Tokens, uint256[2] calldata _Type, bytes32[3] calldata _mrs, uint8 _v)  payable external returns(bool) {
        require(hashComformation[_mrs[0]] != true, "Hash already exists");
        require(ecrecover(_mrs[0],_v,_mrs[1],_mrs[2]) == feeAddress,"Invalid Signature");
        
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_user[0],_user[1],_amount));
        
        registerUser(_user[0],_user[1],_ref[0],_ref[1],_Tokens[0],_Tokens[1],_Type[0],_Type[1]); //register
        
        require (msg.sender == _user[0],"Invalid User..");
        require (_type==1 || _type == 2, "Invalid Type.. ");
        require(escrow_map[_tradeHash].escrowStatus==false, "Status Checking Failed.. ");
        
        
        if(_Tokens[0] !=  address(0)) {// checking seller referral_token 
            require(_Type[0]==1 && _referralFee[_user[0]][_Tokens[0]]>0,"Insufficient Fee Balance or type mismatch" );
            
        }
        if(_Tokens[0] ==  address(0) && _type == 2){
            require( _Type[0]==0 && msg.value >= _sellerFee, "Type mismatch or msg.value less then sellerfee"); 
            _referralFee[_user[0]][_Tokens[0]] += msg.value; //_referralFee[_seller][_Tokens[0]].add(msg.value);
        }
         
        if(_Tokens[0] ==  address(0) && _type == 1){
            require( _Type[0]==0 && msg.value >= _amount.add(_sellerFee), "Type mismatch or msg.value less then sellerfee"); 
            _referralFee[_user[0]][_Tokens[0]] += _sellerFee; //_referralFee[_seller][_Tokens[0]].add(msg.value);
        }
    
        require(_referralFee[_user[0]][_Tokens[0]] >= _sellerFee, "Insufficient Fee for this Trade");
        
        if(_type == 1){
            require(_user[2] == address(0), "Invalid Token Address For this Type");
            require(_amount<=msg.value && msg.value >0, "Invalid Amount..");                  
        }
        
        if(_type == 2){
            Token(_user[2]).transferFrom(_user[0],address(this), _amount);
            
            
        }
        
        uint256 _sellerCancelAfter = _sellerCancelInSeconds == 0 ? 1 : ((now).add(_sellerCancelInSeconds));
        
        escrow_map[_tradeHash].escrowStatus = true;
        escrow_map[_tradeHash].setTimeSellerCancel = _sellerCancelAfter;
        escrow_map[_tradeHash].sellerFee = _sellerFee;
        escrow_map[_tradeHash].buyerFee = _buyerFee;
        escrow_map[_tradeHash].eType = _type;
        
        emit Created(_tradeHash); //event
        hashComformation[_mrs[0]] = true;
        return true;
    }
    
    /** @dev private - Register the User for referral process.
     * @param _seller - The seller address of particular trade.
     * @param _buyer - The buyer address of particular trade.
     * @param _sellrefer - The referral address for seller.
     * @param _buyrefer -  The referral address for buyer.
     * @param _sellerToken -  The referral token address for seller. 
     * @param _buyerToken - The referral token address for buyer.
     * @param _sellerFeeType - The referral type for seller is 0 - ether / 1 - token.
     * @param _buyerFeeType - The referral type for buyer 0 - ether / 1 - token.
     * @return bool - true.
     */
    function registerUser(address _seller, address _buyer,address _sellrefer,address _buyrefer, address _sellerToken, address _buyerToken, uint256 _sellerFeeType, uint256 _buyerFeeType)  private returns(bool) {
        
        //seller
        if(_sellrefer!= address(0)) { // referralAddr checking for referral fee 
            referral_map[_seller].referralAddr =_sellrefer;
            referral_map[_seller].registerStatus =true;
        }
       
        if(_sellerFeeType == 1) {// referral token for admin fee/referral fee
            referral_map[_seller].userAddr = _seller;
            referral_map[_seller].referralTokenAddr = _sellerToken;
            referral_map[_seller].referralType = _sellerFeeType;
        }
        
        else if(_sellerFeeType == 0) {// referral ether for admin fee/referral fee
            referral_map[_seller].userAddr = _seller;
            referral_map[_seller].referralTokenAddr = address(0);
            referral_map[_seller].referralType = _sellerFeeType;
        }

        //buyer
        if(_buyrefer != address(0)) { // referralAddr checking for referral fee
            referral_map[_buyer].referralAddr = _buyrefer;
            referral_map[_buyer].registerStatus =true;
        }
        
        if(_buyerFeeType ==1) {// referral token for admin fee/referral fee
            referral_map[_buyer].userAddr = _buyer;
            referral_map[_buyer].referralTokenAddr = _buyerToken;
            referral_map[_buyer].referralType = _buyerFeeType;
        }
        
        else if(_buyerFeeType == 0) { // referral ether for admin fee/referral fee
            referral_map[_buyer].userAddr = _buyer;
            referral_map[_buyer].referralTokenAddr = address(0);
            referral_map[_buyer].referralType = _buyerFeeType;
        }
        
        return true;
    }
    

    /** @dev external - Withdraw the admin fees collected by the contract. Only the owner can call this .
     * @param _to - The withdrawal address.
     * @param _amount - The withdrawal amount.
     * @param _type - If Ether __type = 1, else _type = 2.
     * @param _tokenContract -  The withdrawal token address.
     */
    function withdrawFees(address payable _to, uint256 _amount,uint16 _type, address _tokenContract) onlyOwner external {
        if(_type == 1) {
            require(_amount <= _token[address(this)][address(0)],"Insufficient ether balance"); 
            _token[address(this)][address(0)] = _token[address(this)][address(0)].sub(_amount);
            _to.transfer(_amount);
        }
        
        else if(_type == 2) {
            require(_amount <= _token[address(this)][_tokenContract],"Insufficient token balance");
            _token[address(this)][_tokenContract] = _token[address(this)][_tokenContract].sub(_amount);
            Token(_tokenContract).transfer(_to,_amount);
        }
    }

    /** @dev external - Withdraw the referral fees  by the seller/buyer/referral address.
     * @param _amount - The withdrawal amount.
     * @param _type - If Ether __type = 1, else _type = 2.
     * @param _tokenContract -  The withdrawal token address.
     * @param _refType - if the new referral token  _refType = 0, if already registered referraltoken _refType = 1
     */
    function withdrawReferral(uint256 _amount,uint16 _type, address _tokenContract, uint256 _refType) external {
        if(_type == 1) { //ether 
            require(_amount <= _referralFee[msg.sender][address(0)], "Insufficient ether balance"); 
            _referralFee[msg.sender][address(0)] =  _referralFee[msg.sender][address(0)].sub(_amount);
            msg.sender.transfer(_amount);
        }
        else if(_type == 2) { //token 
            if(_refType == 0) { // Any user can withdraw their particular token amount 
                require(_amount <=  _referralFee[msg.sender][_tokenContract], "Insufficient token balance");
                _referralFee[ msg.sender][_tokenContract] = _referralFee[ msg.sender][_tokenContract].sub(_amount);
                Token(_tokenContract).transfer( msg.sender,_amount);
                
            }
            else if(_refType == 1) {  // If seller/ buyer comes, withdraw their referral token amount 
                require(_amount <=  _referralFee[msg.sender][referral_map[msg.sender].referralTokenAddr], "Insufficient token balance");
                _referralFee[ msg.sender][referral_map[msg.sender].referralTokenAddr] = _referralFee[ msg.sender][referral_map[msg.sender].referralTokenAddr].sub(_amount);
                Token(referral_map[msg.sender].referralTokenAddr).transfer(msg.sender,_amount);
            }
        }
    }

    /** @dev payable -  After the payment successfull, the buyer clicks mark as paid on that time this function calls.
     * @param _tradeId - The unique id for particular trade.
     * @param _seller - The seller address of particular trade.
     * @param _buyer - The buyer address of particular trade.
     * @param _amount - The escrow amount of particular trade is ether/token.
     * @param _mrs - _mrs[0]- _messageHash, _mrs[1] - r of signature , _mrs[2] - s of signature.
     * @param _v - v of signature
     * @return bool - true.
     */
    function disableSellerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount, bytes32[3] memory _mrs, uint8 _v) payable public returns(bool) {        
        require(hashComformation[_mrs[0]] != true, "Hash already exists");
        require(ecrecover(_mrs[0],_v,_mrs[1],_mrs[2]) == feeAddress,"Invalid Signature");
        
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        require(escrow_map[_tradeHash].escrowStatus == true, "Status Checking Failed.. ");
        require(escrow_map[_tradeHash].setTimeSellerCancel !=0,  "Seller Cancel time is Differ.. ");
        require(msg.sender == _buyer, "Invalid User.. ");
        
        if(referral_map[_buyer].referralTokenAddr !=  address(0)) { // checking buyer referral_token 
            require(_referralFee[_buyer][referral_map[_buyer].referralTokenAddr]>0,"Insufficient Fee Balance.." );
        }
        
        if(referral_map[_buyer].referralTokenAddr ==  address(0) && (escrow_map[_tradeHash].eType == 2)) {
            require(msg.value >= escrow_map[_tradeHash].buyerFee, "Need more deposit amount for fee");
            _referralFee[_buyer][referral_map[_buyer].referralTokenAddr] = _referralFee[_buyer][referral_map[_buyer].referralTokenAddr].add(msg.value);
        }
        
        if(referral_map[_buyer].referralTokenAddr ==  address(0) && (escrow_map[_tradeHash].eType == 1)) {
            _referralFee[_buyer][referral_map[_buyer].referralTokenAddr] = _referralFee[_buyer][referral_map[_buyer].referralTokenAddr].add(escrow_map[_tradeHash].buyerFee);
        }
        
        
        require(_referralFee[_buyer][referral_map[_buyer].referralTokenAddr] >= escrow_map[_tradeHash].buyerFee, "Insufficient Fee for this Trade");
        
       escrow_map[_tradeHash].setTimeSellerCancel = 0;
       
       emit SellerCancelDisabled(_tradeHash); // Event
       hashComformation[_mrs[0]] = true;
       return true;
    }
 
    /** @dev external -  If the buyer wants to cancel the trade, the escrow send back ether to seller.
     * @param _tradeId - The unique id for particular trade.
     * @param _seller - The seller address of particular trade.
     * @param _buyer - The buyer address of particular trade.
     * @param _amount - The escrow amount of particular trade is ether/token.
     * @param tokenadd - The token address which is escrowed by seller.
     * @param _mrs - _mrs[0]- _messageHash, _mrs[1] - r of signature , _mrs[2] - s of signature.
     * @param _v - v of signature
     * @return bool - true.
     */
    function buyerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount,address tokenadd, bytes32[3] calldata _mrs, uint8 _v) external returns(bool) {
        require(hashComformation[_mrs[0]] != true, "Hash already exists");
        require(ecrecover(_mrs[0],_v,_mrs[1],_mrs[2]) == feeAddress,"Invalid Signature");
        
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        require(escrow_map[_tradeHash].escrowStatus == true && msg.sender==_buyer, "Invalid Escrow status or This user not allowed to call");
        require(escrow_map[_tradeHash].setTimeSellerCancel > now, "Time  Expired Issue..");
        
        if(escrow_map[_tradeHash].eType == 1 ) {
            _seller.transfer(_amount);
        }
        if (escrow_map[_tradeHash].eType== 2) {
            Token(tokenadd).transfer(_seller,_amount);
        }
        
        delete escrow_map[_tradeHash];
        emit CancelledByBuyer(_tradeHash); //Event
        hashComformation[_mrs[0]] = true; 
        return true;
        }

    /** @dev external - If the seller wants to cancel the trade, the escrow send back ether to seller, Its only called if the buyer missed to pay the amount 
     * @param _tradeId - The unique id for particular trade.
     * @param _seller - The seller address of particular trade.
     * @param _buyer - The buyer address of particular trade.
     * @param _amount - The escrow amount of particular trade is ether/token.
     * @param tokenadd - The token address which is escrowed by seller.
     * @param _mrs - _mrs[0]- _messageHash, _mrs[1] - r of signature , _mrs[2] - s of signature.
     * @param _v - v of signature
     * @return bool - true.
     */
    function sellerCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount, address tokenadd, bytes32[3] calldata _mrs, uint8 _v) external returns(bool) {
        require(hashComformation[_mrs[0]] != true, "Hash already exists");
        require(ecrecover(_mrs[0],_v,_mrs[1],_mrs[2]) == feeAddress,"Invalid Signature");
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        
        require(escrow_map[_tradeHash].escrowStatus == true && msg.sender==_seller, "Invalid Escrow status or This user not allowed to call");
        
        if(escrow_map[_tradeHash].setTimeSellerCancel <= 1 || escrow_map[_tradeHash].setTimeSellerCancel > now) revert();
        
        if(escrow_map[_tradeHash].eType == 1 ) {
            _seller.transfer(_amount);
        }
        
        if (escrow_map[_tradeHash].eType == 2) {
            Token(tokenadd).transfer(_seller,_amount);
        }
        
        delete escrow_map[_tradeHash];
        emit CancelledBySeller(_tradeHash); // Event
        hashComformation[_mrs[0]] = true;
        return true;
        }
    
    /** @dev external - If the seller wants to cancel the request, seller calls, If the seller set time for cancel = 1 and Its only called if the buyer is unresponsive.
     * @param _tradeId - The unique id for particular trade.
     * @param _seller - The seller address of particular trade.
     * @param _buyer - The buyer address of particular trade.
     * @param _amount - The escrow amount of particular trade is ether/token.
     * @param _mrs - _mrs[0]- _messageHash, _mrs[1] - r of signature , _mrs[2] - s of signature.
     * @param _v - v of signature
     * @return bool - true.
     */
    function sellerRequestCancel(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount,  bytes32[3] calldata _mrs, uint8 _v) external returns(bool) {
        require(hashComformation[_mrs[0]] != true, "Hash already exists");
        require(ecrecover(_mrs[0],_v,_mrs[1],_mrs[2]) == feeAddress,"Invalid Signature");
        
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        
        require(_seller==msg.sender, "This user not allowed to call this function");
        
        require(escrow_map[_tradeHash].escrowStatus == true, "Status Checking Failed.. ");
        
        require (escrow_map[_tradeHash].setTimeSellerCancel == 1,  "Seller Cancel time is Differ.. ");
        
        escrow_map[_tradeHash].setTimeSellerCancel = (now).add(requestCancelMinimumTime);
        
        emit SellerRequestedCancel(_tradeHash); // Event
        hashComformation[_mrs[0]] = true;
        return true;
        
        }

    /** @dev external - Call for dispute if the clashes between seller or buyer.
     * @param _tradeId - The unique id for particular trade.
     * @param _seller - The seller address of particular trade.
     * @param _buyer - The buyer address of particular trade.
     * @param _amount - The escrow amount of particular trade is ether/token.
     * @param disputetype - if seller disputes disputetype = 1 and if buyer disputes disputetype = 2.
     * @param _mrs - _mrs[0]- _messageHash, _mrs[1] - r of signature , _mrs[2] - s of signature.
     * @param _v - v of signature
     * @return bool - true.
     */
    function consumeDispute(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount, uint16 disputetype,  bytes32[3] calldata _mrs, uint8 _v) external returns (bool) {
        require(hashComformation[_mrs[0]] != true, "Hash already exists");
        require(ecrecover(_mrs[0],_v,_mrs[1],_mrs[2]) == feeAddress,"Invalid Signature");
        
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
         
        require(msg.sender == _seller || msg.sender == _buyer, "This user not allowed to call this function");
         
        require(escrow_map[_tradeHash].escrowStatus == true, " Status Failed.. ");
         
        if(disputetype == 1) {// seller
            escrow_map[_tradeHash].sellerDispute = true;
            hashComformation[_mrs[0]] = true;
            return true;
        }
        else if(disputetype == 2) {// buyer
            escrow_map[_tradeHash].buyerDispute = true;
            hashComformation[_mrs[0]] = true;
            return true;
        }
    }

    /** @dev external - After Confirm Payment Call By Seller, release the funds.
     * @param _tradeId - The unique id for particular trade.
     * @param _seller - The seller address of particular trade.
     * @param _buyer - The buyer address of particular trade.
     * @param _amount - The escrow amount of particular trade is ether/token.
     * @param _tokenContract - The token address which is escrowed by seller.
     * @param _mrs - _mrs[0]- _messageHash, _mrs[1] - r of signature , _mrs[2] - s of signature.
     * @param _v - v of signature
     * @return bool - true.
     */
    function releseFunds(uint16 _tradeId, address payable _seller, address payable _buyer, uint256 _amount,address _tokenContract,  bytes32[3] calldata _mrs, uint8 _v) external  returns(bool) {
        require(hashComformation[_mrs[0]] != true, "Hash already exists");
        require(ecrecover(_mrs[0],_v,_mrs[1],_mrs[2]) == feeAddress,"Invalid Signature");
        require(msg.sender == _seller, "This user not allowed to call this function");
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeId,_seller,_buyer,_amount));
        require(escrow_map[_tradeHash].escrowStatus == true, "Status Failed.. ");
        uint256[2] memory reffee; 
        uint256 percDiv =uint256((100)).mul(10**18);
        reffee[0] = (escrow_map[_tradeHash].sellerFee.mul(referPercent)).div(percDiv);  // seller Referral Fee 
        reffee[1] = (escrow_map[_tradeHash].buyerFee.mul(referPercent)).div(percDiv); // buyer Referral Fee

        // seller referral process
        if(referral_map[_seller]. registerStatus == true) {
            require(_referralFee[_seller][referral_map[_seller].referralTokenAddr] >= escrow_map[_tradeHash].sellerFee, "Insufficient Referral Fee Balance for seller");
            _token[address(this)][referral_map[_seller].referralTokenAddr] = _token[address(this)][referral_map[_seller].referralTokenAddr].add(escrow_map[_tradeHash].sellerFee);
            _referralFee[referral_map[_seller].referralAddr][referral_map[_seller].referralTokenAddr] = _referralFee[referral_map[_seller].referralAddr][referral_map[_seller].referralTokenAddr].add(reffee[0]);  // seller Referral
            _token[address(this)][referral_map[_seller].referralTokenAddr] = _token[address(this)][referral_map[_seller].referralTokenAddr].sub(reffee[0]);
            _referralFee[_seller][referral_map[_seller].referralTokenAddr] = _referralFee[_seller][referral_map[_seller].referralTokenAddr].sub(escrow_map[_tradeHash].sellerFee);
        }
            
        else  // seller not registered the referral address, so only admin fee
        {
            reffee[0] = 0;
            require(_referralFee[_seller][referral_map[_seller].referralTokenAddr] >= escrow_map[_tradeHash].sellerFee, "Insufficient Referral Fee Balance for seller");
            _token[address(this)][referral_map[_seller].referralTokenAddr] =  _token[address(this)][referral_map[_seller].referralTokenAddr].add(escrow_map[_tradeHash].sellerFee);
            _token[address(this)][referral_map[_seller].referralTokenAddr] =  _token[address(this)][referral_map[_seller].referralTokenAddr].sub(reffee[0]);
            _referralFee[_seller][referral_map[_seller].referralTokenAddr] =  _referralFee[_seller][referral_map[_seller].referralTokenAddr].sub(escrow_map[_tradeHash].sellerFee);
        }

        //buyer referral process
        if(referral_map[_buyer]. registerStatus == true) {
             require(_referralFee[_buyer][referral_map[_buyer].referralTokenAddr] >= escrow_map[_tradeHash].buyerFee , "Insufficient Referral Fee Balance for buyer");
            _token[address(this)][referral_map[_buyer].referralTokenAddr] = _token[address(this)][referral_map[_buyer].referralTokenAddr].add(escrow_map[_tradeHash].buyerFee);
            _referralFee[referral_map[_buyer].referralAddr][referral_map[_buyer].referralTokenAddr] = _referralFee[referral_map[_buyer].referralAddr][referral_map[_buyer].referralTokenAddr].add(reffee[1]);  // buyer Referral
            _token[address(this)][referral_map[_buyer].referralTokenAddr] = _token[address(this)][referral_map[_buyer].referralTokenAddr].sub(reffee[1]);
            _referralFee[_buyer][referral_map[_buyer].referralTokenAddr] =  _referralFee[_buyer][referral_map[_buyer].referralTokenAddr].sub(escrow_map[_tradeHash].buyerFee);
       }
            
       else //buyer not registered the referral address, so only admin fee
       {
            reffee[1] =0;
            require(_referralFee[_buyer][referral_map[_buyer].referralTokenAddr] >= escrow_map[_tradeHash].buyerFee,  "Insufficient Referral Fee Balance for buyer");
            _token[address(this)][referral_map[_buyer].referralTokenAddr] =  _token[address(this)][referral_map[_buyer].referralTokenAddr].add(escrow_map[_tradeHash].buyerFee);
            _token[address(this)][referral_map[_buyer].referralTokenAddr] =  _token[address(this)][referral_map[_buyer].referralTokenAddr].sub(reffee[1]);
            _referralFee[_buyer][referral_map[_buyer].referralTokenAddr] = _referralFee[_buyer][referral_map[_buyer].referralTokenAddr].sub(escrow_map[_tradeHash].buyerFee);
       }

        if(escrow_map[_tradeHash].eType == 1 ) {//ether 
             _buyer.transfer(_amount.sub(escrow_map[_tradeHash].buyerFee));
        }
    
        if (escrow_map[_tradeHash].eType == 2)  {//token 
            Token(_tokenContract).transfer(_buyer,(_amount));
        }
        
        delete escrow_map[_tradeHash];
        emit Released(_tradeHash);
        hashComformation[_mrs[0]] = true;
        return true;
    }  

    /** @dev external - Its only called by Mediator, because of any issues between seller and buyer (vanish), If the sellerDispute or buyerDispute is true for this trade.
     * @param Idfavour[] - [0]The unique id for particular trade. [1] Favour: 1 (seller) Favour: 2 (buyer)
     * @param _seller - The seller address of particular trade.
     * @param _buyer - The buyer address of particular trade.
     * @param _amount - The escrow amount of particular trade is ether/token.
     * @param _tokenContract - The token address which is escrowed by seller.
     * @return bool - true.
     */
    function disputeByMediator(uint16[2] calldata Idfavour, address payable _seller, address payable _buyer, uint256 _amount, address _tokenContract,  bytes32[3] calldata _mrs, uint8 _v) external  returns(bool) {
        require(hashComformation[_mrs[0]] != true, "Hash already exists");
        require(ecrecover(_mrs[0],_v,_mrs[1],_mrs[2]) == feeAddress,"Invalid Signature");
        require(msg.sender == _seller || msg.sender == _buyer,"Only seller/buyer can call this function");
        
        bytes32 _tradeHash = keccak256(abi.encodePacked(Idfavour[0],_seller,_buyer,_amount));
         
        require(escrow_map[_tradeHash].sellerDispute == true || escrow_map[_tradeHash].buyerDispute == true, " Seller or Buyer Doesn't Call Dispute");
         
        require(escrow_map[_tradeHash].escrowStatus == true, " Status Failed..");
         
        require(Idfavour[1] == 1 || Idfavour[1] == 2,  "Invalid Favour Type");
         
        uint256[2] memory reffee;
        uint256 percDiv =uint256((100)).mul(10**18);
        reffee[0] = (escrow_map[_tradeHash].sellerFee.mul(referPercent)).div(percDiv);  // seller Referral Fee 
        reffee[1] = (escrow_map[_tradeHash].buyerFee.mul(referPercent)).div(percDiv); // buyer Referral Fee
       

        // seller referral process
        if(referral_map[_seller]. registerStatus == true) {
            require(_referralFee[_seller][referral_map[_seller].referralTokenAddr] >= escrow_map[_tradeHash].sellerFee, "Insufficient Referral Fee Balance for seller");
            _token[address(this)][referral_map[_seller].referralTokenAddr] = _token[address(this)][referral_map[_seller].referralTokenAddr].add(escrow_map[_tradeHash].sellerFee);
            _referralFee[referral_map[_seller].referralAddr][referral_map[_seller].referralTokenAddr] = _referralFee[referral_map[_seller].referralAddr][referral_map[_seller].referralTokenAddr].add(reffee[0]);  // seller Referral
            _token[address(this)][referral_map[_seller].referralTokenAddr] = _token[address(this)][referral_map[_seller].referralTokenAddr].sub(reffee[0]);
            _referralFee[_seller][referral_map[_seller].referralTokenAddr] = _referralFee[_seller][referral_map[_seller].referralTokenAddr].sub(escrow_map[_tradeHash].sellerFee);
        }
            
        else  // seller not registered the referral address, so only admin fee
        {
            reffee[0] = 0;
            require(_referralFee[_seller][referral_map[_seller].referralTokenAddr] >= escrow_map[_tradeHash].sellerFee, "Insufficient Referral Fee Balance for seller");
            _token[address(this)][referral_map[_seller].referralTokenAddr] =  _token[address(this)][referral_map[_seller].referralTokenAddr].add(escrow_map[_tradeHash].sellerFee);
            _token[address(this)][referral_map[_seller].referralTokenAddr] =  _token[address(this)][referral_map[_seller].referralTokenAddr].sub(reffee[0]);
            _referralFee[_seller][referral_map[_seller].referralTokenAddr] =  _referralFee[_seller][referral_map[_seller].referralTokenAddr].sub(escrow_map[_tradeHash].sellerFee);
        }

        //buyer referral process
        if(referral_map[_buyer]. registerStatus == true) {
             require(_referralFee[_buyer][referral_map[_buyer].referralTokenAddr] >= escrow_map[_tradeHash].buyerFee , "Insufficient Referral Fee Balance for buyer");
            _token[address(this)][referral_map[_buyer].referralTokenAddr] = _token[address(this)][referral_map[_buyer].referralTokenAddr].add(escrow_map[_tradeHash].buyerFee);
            _referralFee[referral_map[_buyer].referralAddr][referral_map[_buyer].referralTokenAddr] = _referralFee[referral_map[_buyer].referralAddr][referral_map[_buyer].referralTokenAddr].add(reffee[1]);  // buyer Referral
            _token[address(this)][referral_map[_buyer].referralTokenAddr] = _token[address(this)][referral_map[_buyer].referralTokenAddr].sub(reffee[1]);
            _referralFee[_buyer][referral_map[_buyer].referralTokenAddr] =  _referralFee[_buyer][referral_map[_buyer].referralTokenAddr].sub(escrow_map[_tradeHash].buyerFee);
       }
            
       else //buyer not registered the referral address, so only admin fee
       {
            reffee[1] =0;
            require(_referralFee[_buyer][referral_map[_buyer].referralTokenAddr] >= escrow_map[_tradeHash].buyerFee,  "Insufficient Referral Fee Balance for buyer");
            _token[address(this)][referral_map[_buyer].referralTokenAddr] =  _token[address(this)][referral_map[_buyer].referralTokenAddr].add(escrow_map[_tradeHash].buyerFee);
            _token[address(this)][referral_map[_buyer].referralTokenAddr] =  _token[address(this)][referral_map[_buyer].referralTokenAddr].sub(reffee[1]);
            _referralFee[_buyer][referral_map[_buyer].referralTokenAddr] = _referralFee[_buyer][referral_map[_buyer].referralTokenAddr].sub(escrow_map[_tradeHash].buyerFee);
       }

        
        if(escrow_map[_tradeHash].eType == 1) {//ether
            if(Idfavour[1] == 1) {//seller
                _seller.transfer(_amount);
            }
            else if (Idfavour[1] == 2) {//buyer
                _buyer.transfer(_amount.sub(escrow_map[_tradeHash].buyerFee));
            }
        }
        if(escrow_map[_tradeHash].eType == 2) {//token
            if(Idfavour[1] == 1) { //seller
                Token(_tokenContract).transfer(_seller,_amount);
            }
            else if (Idfavour[1] == 2) {//buyer
                Token(_tokenContract).transfer(_buyer,(_amount));
            }
        }

        delete escrow_map[_tradeHash];
        emit DisputeResolved(_tradeHash); // Event
        hashComformation[_mrs[0]] = true;
        return true;
        
    }
    
    function tokenallowance(address tokenAddr,address _owner,address _spender) public view returns(uint256){ // to check token allowance to contract
        return Token(tokenAddr).allowance(_owner,_spender);
    }
        
 }
