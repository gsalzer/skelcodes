pragma solidity ^0.4.24;
import "./StandardToken.sol";

contract ReapChain is StandardToken { // CHANGE THIS. Update the contract name.
    
    struct Presales {
        uint presalesTime; // 1:1st, 2:2nd, 3:3rd..
        uint256 presalesAmount;
        uint256 presalesETH;
        uint256 presalesBTC;
        uint256 presalesCASH;
        string reason;
    }
    
    uint public totalHolderCount;
    uint public totalPresaleHolderCount;
    mapping (uint => uint) public totalRoundPresaleHolderCount;
    mapping (uint => address) public holderList;
    mapping (uint => address) public presaleHolderList;
    mapping (uint => mapping (uint => address)) public roundPresaleHolderList;
    mapping (address => bool) public isHolders;
    mapping (address => bool) public isLockHolders;
    mapping (address => uint) public presaleJoinCount;
    mapping (address => mapping (uint => Presales)) public holderPresaleInfo;
    mapping (uint => uint256) public presalesAmount;
    
    mapping (uint => uint256) public totalEthInWei;
    mapping (uint => uint256) public totalBtcInWei;
    mapping (uint => uint256) public totalCash;
    mapping (address => bool) public subOwner;
    
    bool public locked;
    
    mapping (address => uint256) public holderLockBalance;
    
    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public constant name = "ReapChain";                   // Token Name
    uint8 public constant decimals = 18;                // How many decimals to show. To be standard complicant keep it 18
    string public constant symbol = "REAP";                 // An identifier: eg SBX, XPR etc..
    address public fundsWallet;           // Where should the raised ETH go?
    
    
    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    constructor() public {
        balances[msg.sender] = 4900000000000000000000000000;               // Give the creator all initial tokens. This is set to 1000 for example. If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE THIS)
        totalSupply_ = 4900000000000000000000000000;                        // Update total supply (1000 for example) (CHANGE THIS)
        fundsWallet = msg.sender;                                    // The owner of the contract gets ETH
        locked = true;
        
    }
    function lockStart() public {
        require(fundsWallet == msg.sender);
        locked = true;
    }
    function lockStop() public {
        require(fundsWallet == msg.sender);
        locked = false;
    }
    function presaleHolderLock(uint _presales) public {
        require(fundsWallet == msg.sender);
        for(uint i=0 ; i < totalRoundPresaleHolderCount[_presales] ; i++) {
            isLockHolders[roundPresaleHolderList[_presales][i]] = true;
        }
    }
    function presaleHolderRelease(uint _presales) public {
        require(fundsWallet == msg.sender);
        for(uint i=0 ; i < totalRoundPresaleHolderCount[_presales] ; i++) {
            isLockHolders[roundPresaleHolderList[_presales][i]] = false;
        }
    }
    function lockAddress(address _address) public {
        require(fundsWallet == msg.sender);
        isLockHolders[_address] = true;
    }
    function releaseAddress(address _address) public {
        require(fundsWallet == msg.sender);
        isLockHolders[_address] = false;
    }
    function setHolderLockBalance(address _address, uint _lockAmount) public {
        require(fundsWallet == msg.sender);
        holderLockBalance[_address] = _lockAmount;
    }
    function addSubOwner(address _address) public {
        require(fundsWallet == msg.sender);
        subOwner[_address] = true;
    }
    function removeSubOwner(address _address) public {
        require(fundsWallet == msg.sender);
        subOwner[_address] = false;
    }
    function manualPresales(uint _presales, address _to, uint256 _amount, uint256 _presalesETH, uint256 _presalesBTH, uint256 _presalesCASH, string _reason) public {
        require(fundsWallet == msg.sender || subOwner[msg.sender] == true);
        require(balances[msg.sender] >= _amount);
        
        if (msg.sender != _to && isHolders[_to] != true) {
            isHolders[_to] = true;
            holderList[totalHolderCount] = _to;
            totalHolderCount = totalHolderCount + 1;
        }
        presalesAmount[_presales] = presalesAmount[_presales] + _amount;
        
        totalEthInWei[_presales] = totalEthInWei[_presales] + _presalesETH;
        totalBtcInWei[_presales] = totalBtcInWei[_presales] + _presalesBTH;
        totalCash[_presales] = totalCash[_presales] + _presalesCASH;
        
        holderPresaleInfo[_to][presaleJoinCount[_to]].presalesTime = _presales;
        holderPresaleInfo[_to][presaleJoinCount[_to]].presalesAmount = _amount;
        holderPresaleInfo[_to][presaleJoinCount[_to]].presalesETH = _presalesETH;
        holderPresaleInfo[_to][presaleJoinCount[_to]].presalesBTC = _presalesBTH;
        holderPresaleInfo[_to][presaleJoinCount[_to]].presalesCASH = _presalesCASH;
        holderPresaleInfo[_to][presaleJoinCount[_to]].reason = _reason;
        
        if (presaleJoinCount[_to] == 0) {
            presaleHolderList[totalPresaleHolderCount] = _to;
            totalPresaleHolderCount = totalPresaleHolderCount + 1;
            
            roundPresaleHolderList[_presales][totalRoundPresaleHolderCount[_presales]] = _to;
            totalRoundPresaleHolderCount[_presales] = totalRoundPresaleHolderCount[_presales] + 1;
        } else {
            bool isPresaleHolder = false;
            for (uint i=0;i<totalRoundPresaleHolderCount[_presales];i++) {
                if (roundPresaleHolderList[_presales][i] == _to) {
                    isPresaleHolder = true;
                    break;
                }
            }
            if (!isPresaleHolder) {
                roundPresaleHolderList[_presales][totalRoundPresaleHolderCount[_presales]] = _to;
                totalRoundPresaleHolderCount[_presales] = totalRoundPresaleHolderCount[_presales] + 1;
            }
        }
        presaleJoinCount[_to] = presaleJoinCount[_to] + 1;
        
        if (_presales == 1 || _presales == 2) {
            isLockHolders[_to] = true;
        }
        
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = balances[_to] + _amount;
        
        
        emit Transfer(msg.sender, _to, _amount);
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= holderLockBalance[msg.sender]);
        require(_value <= balances[msg.sender] - holderLockBalance[msg.sender]);
        require(_to != address(0));
        require(locked == false || msg.sender == fundsWallet);
        require(isLockHolders[msg.sender] == false);
        
        if (fundsWallet != _to && isHolders[_to] != true) {
            isHolders[_to] = true;
            holderList[totalHolderCount] = _to;
            totalHolderCount = totalHolderCount + 1;
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
    address _from,
    address _to,
    uint256 _value
    )
    public
    returns (bool)
    {
        require(balances[_from] >= holderLockBalance[_from]);
        require(_value <= balances[_from] - holderLockBalance[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));
        require(locked == false || _from == fundsWallet);
        require(isLockHolders[_from] == false);
        
        if (fundsWallet != _to && isHolders[_to] != true) {
            isHolders[_to] = true;
            holderList[totalHolderCount] = _to;
            totalHolderCount = totalHolderCount + 1;
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
}
