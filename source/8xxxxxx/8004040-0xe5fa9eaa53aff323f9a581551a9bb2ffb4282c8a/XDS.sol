pragma solidity ^0.5.8;
import './ERC20.sol';

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

contract VDPoolBasic {
    function price() external view returns (uint256);
    function buyToken(uint256 ethAmount) external returns (uint256);
    function currentLevel() external view returns(uint256);
    function currentLevelRemaining() external view returns(uint256);
}

contract InvitationBasic {
    function signUp(address referrer, address addr, uint256 phase, uint256 ePhase) external;
    function isRoot(address addr) external view returns (bool);
    function newRoot(address addr, uint256 phase) external;
    function getParent(address addr) external view returns(address);
    function getAncestors(address addr) external view returns(address[] memory);
    function isSignedUp(address addr) public view returns (bool);
    function getPoints(uint256 phase, address addr) external view returns (uint256);
    function newSignupCount(uint256 phase) external view returns (uint256);
    function getTop(uint256 phase) external view returns(address[] memory);
    function distributeBonus(uint256 len) external pure returns(uint256[] memory);
}

contract LuckyDrawBasic {
    function buyTicket(address addr, uint256 phase) external;
    function aggregateIcexWinners(uint256 phase) external;
    function getWinners(uint256 phase) external view returns(address[] memory);
}

contract XDS is StandardToken {
    using address_make_payable for address;

    /*
     * CONSTANTS
     */

    uint16[] public bonusRate = [200, 150, 100, 50];

    /*
     * STATES
     */
    address public settler;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    address public reservedAccount;
    uint256 public reservedAmount;
    address public foundationAddr;

    uint256 public firstBlock = 0;
    uint256 public blockPerPhase = 0;

    mapping (uint256 => uint256) public ethBalance;
    mapping (uint256 => mapping (address => uint256)) public addressInvestment;
    mapping (address => uint256) public totalInvestment;
    mapping (address => uint256) public crBonus; // controlled release bonus
    address[] icexInvestors;
    mapping (uint256 => address[]) public topInvestor;
    mapping (uint256 => bool) public settled;

    InvitationBasic invitationContract;
    LuckyDrawBasic luckydrawContract;
    VDPoolBasic vdPoolContract;

    uint256 public signUpFee = 0;
    uint256 public rootFee = 0;
    uint256 referrerBonus = 0;
    uint256 ancestorBonus = 0;
    uint16 topInvestorCounter = 0;
    uint16 icexCRBonusRatio = 75;
    uint256 crBonusReleasePhases = 10;
    uint256 ethBonusReleasePhases = 20;

    uint256 luckyDrawRate = 10;
    uint256 invitationRate = 70;
    uint256 topInvestorRate = 20;

    uint256 foundationRate = 50;

    uint256 icexRewardETHPool = 0;

    /*
     * EVENTS
     */
    /// Emitted only once after token sale starts.
    event SaleStarted();

    event Settled(uint256 phase, uint256 ethDistributed, uint256 ethToPool);

    event LuckydrawSettle(uint256 phase, address indexed who, uint256 ethAmount);
    event InvitationSettle(uint256 phase, address indexed who, uint256 ethAmount);
    event InvestorSettle(uint256 phase, address indexed who, uint256 ethAmount);

    /*
     * MODIFIERS
     */
    /// only master can call the function
    modifier onlyOwner {
        require(master == msg.sender, "only master can call");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _blockPerPhase, uint256 _totalSupply, uint256 _reservedAmount, address _reservedAccount, address _foundationAddr) public {
        master = msg.sender;  // master account
        settler = master;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        currentSupply = _reservedAmount;

        reservedAmount = _reservedAmount;
        reservedAccount = _reservedAccount;
        balances[reservedAccount] = reservedAmount;
        emit Transfer(address(this), reservedAccount, reservedAmount);

        foundationAddr = _foundationAddr; // foundation account

        blockPerPhase = _blockPerPhase; // block number per phase
    }

    /*
     * EXTERNAL FUNCTIONS
     */

    function setOwner(address newOwner) external onlyOwner {
        master = newOwner;
    }

    function setSettler(address newSettler) external onlyOwner {
        settler = newSettler;
    }

    function transfer(address _to, uint256 _value) external onlyPayloadSize(2 * 32) {
        if ( _to == address(this)) {
            require(_value == rootFee, "only valid value is root fee for this recipient");
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            require(!isSignedUp(), "not qulifiled as new root");
            invitationContract.newRoot(msg.sender, currentPhase());
        } else if ( _value == signUpFee && invitationContract.isSignedUp(_to) && !isSignedUp()) {
            uint256 fee = _value;
            balances[msg.sender] = balances[msg.sender].sub(fee);

            uint256 phase = currentPhase();
            uint256 ePhase = phase;
            if (phase < bonusRate.length) {
                ePhase = bonusRate.length - 1;
            }

            invitationContract.signUp(_to, msg.sender, phase, ePhase);
            //direct referrer
            balances[_to] = balances[_to].add(referrerBonus);
            emit Transfer(msg.sender, _to, referrerBonus);
            fee = fee.sub(referrerBonus);

            // go up referrer tree
            address[] memory ancestors = invitationContract.getAncestors(msg.sender);
            for ( uint256 i = 0; i < ancestors.length && fee >= ancestorBonus; i++) {
                if (ancestors[i] == address(0)) {
                    break;
                }
                balances[ancestors[i]] = balances[ancestors[i]].add(ancestorBonus);
                emit Transfer(msg.sender, ancestors[i], ancestorBonus);
                fee = fee.sub(ancestorBonus);
            }

            balances[foundationAddr] = balances[foundationAddr].add(fee);
            emit Transfer(msg.sender, foundationAddr, fee);
        } else {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        }
    }

    function setInvitationContract(address addr, uint256 _rootFee, uint256 _signUpFee, uint256 _ancestorBonus, uint256 _referrerBonus, uint256 _invitationRate) external onlyOwner {
        invitationContract = InvitationBasic(addr);

        rootFee = _rootFee; // price to be root
        signUpFee = _signUpFee; // sign up ticker price
        ancestorBonus = _ancestorBonus;  // ancestor node bonus
        referrerBonus = _referrerBonus;  // referrer node bonus
        invitationRate = _invitationRate;
    }

    function setVdPoolContract(address addr, uint16 _topInvestorCounter, uint256 _topInvestorRate, uint256 _foundationRate) external onlyOwner {
        vdPoolContract = VDPoolBasic(addr);

        topInvestorCounter = _topInvestorCounter;  // number of top investor used during settlment
        topInvestorRate = _topInvestorRate;  // top investor settle rate

        foundationRate = _foundationRate; // foudation share
    }

    function setLuckyDrawContract(address addr, uint256 _luckyDrawRate) external onlyOwner {
        luckydrawContract = LuckyDrawBasic(addr);
        luckyDrawRate = _luckyDrawRate;
    }

    function settle(uint256 phase) external {
        require(settler == address(0) || settler == msg.sender, "only settler can call");
        require(phase >= 0, "invalid phase");
        require(phase < currentPhase(), "phase not matured yet");
        require (!settled[phase], "phase already settled");

        uint256 pool = 0;
        uint256 toPool = 0;
        if (phase < bonusRate.length) {
            if(ethBalance[phase] > 0) {
                toPool = ethBalance[phase].mul(bonusRate.length).div(bonusRate.length + ethBonusReleasePhases);
                icexRewardETHPool = icexRewardETHPool.add(toPool);
                transferToFoundation(ethBalance[phase].sub(toPool));
            }
            // settling last phase of ICEX, combine pools
            if (phase == bonusRate.length - 1) {
                pool = icexRewardETHPool;
            }
        } else {
            pool = ethBalance[phase];
            distributeCRBonus(phase);
        }

        if (pool > 0 ) {
            settleLuckydraw(phase, pool, phase < bonusRate.length);
            settleTopInvestor(phase, pool);
            settleInvitation(phase, pool);
        }

        settled[phase] = true;
        emit Settled(phase, pool, toPool);
    }

    function start(uint256 _firstBlock) external onlyOwner {
        require(!saleStarted(), "Sale has not started yet");
        require(firstBlock == 0 , "Resonance already started");
        firstBlock = _firstBlock;
        emit SaleStarted();
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () external payable {
        issueToken(msg.sender);
    }

    function price() external view returns(uint256) {
        return vdPoolContract.price();
    }

    function currentLevel() external view returns(uint256) {
        return vdPoolContract.currentLevel();
    }

    function currentRemainingEth() external view returns(uint256) {
        return vdPoolContract.currentLevelRemaining();
    }

    function currentBonusRate() external view returns(uint16) {
        uint256 phase = currentPhase();
        if (phase < bonusRate.length){
            return bonusRate[phase];
        }
        return 0;
    }

    function isSignedUp() public view returns (bool) {
        return invitationContract.isSignedUp(msg.sender);
    }

    function topInvestors(uint256 phase) external view returns (address[] memory) {
        return topInvestor[phase];
    }

    function luckyWinners(uint256 phase) external view returns (address[] memory) {
        return luckydrawContract.getWinners(phase);
    }

    function invitationWinners(uint256 phase) external view returns(address[] memory) {
        return invitationContract.getTop(phase);
    }

    function drain(uint256 amount) external onlyOwner {
        transferToFoundation(amount);
    }

    /*
     * PUBLIC FUNCTIONS
     */
    function saleStarted() public view returns (bool) {
        return (firstBlock > 0 && block.number >= firstBlock);
    }

    function currentPhase() public view returns(uint256) {
        return (block.number - firstBlock).div(blockPerPhase);
    }

    function issueToken(address recipient) public payable {
        require(saleStarted(), "Sale is not in progress");
        require(msg.value >= 0.1 ether, "minimal of 0.1 eth required");
        uint256 phase = currentPhase();
        uint256 totalEth = msg.value;

        updateTopInvestor(recipient, msg.value, phase);
        // ICEX
        if (phase < bonusRate.length){
            uint256 bonus = totalEth.mul(bonusRate[phase]).div(100);
            totalEth = totalEth.add(bonus);
            if (crBonus[recipient] == 0 ) {
                icexInvestors.push(recipient);
            }
        }

        uint256 tokens = vdPoolContract.buyToken(totalEth);

        totalInvestment[recipient] = totalInvestment[recipient].add(msg.value);
        currentSupply = currentSupply.add(tokens);

        require(currentSupply <= totalSupply, "exceed token supply cap");

        if (phase < bonusRate.length){
            uint256 crTokens = tokens.mul(bonusRate[phase]).div(100 + bonusRate[phase]).mul(icexCRBonusRatio).div(100);
            require(crTokens >= 0 && tokens > crTokens, 'invalid cr bonus value');
            crBonus[recipient] = crBonus[recipient].add(crTokens.div(crBonusReleasePhases));
            balances[recipient] = balances[recipient].add(tokens).sub(crTokens);
            emit Transfer(address(this), recipient, tokens.sub(crTokens));
        } else {
            balances[recipient] = balances[recipient].add(tokens);
            emit Transfer(address(this), recipient, tokens);
        }

        uint256 foundation = msg.value.mul(foundationRate).div(100);
        transferToFoundation(foundation);
        ethBalance[phase] = ethBalance[phase].add(msg.value).sub(foundation);
        luckydrawContract.buyTicket(recipient, phase);
    }

    /*
     * INTERNAL FUNCTIONS
     */

    function updateTopInvestor(address addr, uint256 ethAmount, uint256 phase) internal {
        uint256 ePhase = phase;
        if (phase < bonusRate.length) {
            ePhase = bonusRate.length - 1; // save it for the last phase of ICEX
        }
        addressInvestment[ePhase][addr] = addressInvestment[ePhase][addr].add(ethAmount);

        for (uint256 k = 0; k < topInvestor[ePhase].length; k++){
            if (topInvestor[ePhase][k] == addr) {
                for (uint256 i = k; i > 0; i--){
                    if (addressInvestment[ePhase][topInvestor[ePhase][i]] > addressInvestment[ePhase][topInvestor[ePhase][i-1]]) {
                        (topInvestor[ePhase][i], topInvestor[ePhase][i-1]) = (topInvestor[ePhase][i-1], topInvestor[ePhase][i]);
                    } else {
                      break;
                    }
                }
                return;
            }
        }

        if (topInvestor[ePhase].length < topInvestorCounter){
            topInvestor[ePhase].push(addr);
        } else if (addressInvestment[ePhase][addr] > addressInvestment[ePhase][topInvestor[ePhase][topInvestor[ePhase].length - 1]]){
            topInvestor[ePhase][topInvestor[ePhase].length - 1] = addr;
        }

        for (uint256 i = topInvestor[ePhase].length - 1; i > 0; i--){
            if (addressInvestment[ePhase][topInvestor[ePhase][i]] > addressInvestment[ePhase][topInvestor[ePhase][i-1]]) {
                (topInvestor[ePhase][i], topInvestor[ePhase][i-1]) = (topInvestor[ePhase][i-1], topInvestor[ePhase][i]);
            } else {
              break;
            }
        }
    }

    function transferToFoundation(uint256 ethAmount) internal {
        address payable addr = foundationAddr.make_payable();
        addr.transfer(ethAmount);
    }

    function settleLuckydraw(uint256 phase, uint256 ethAmount, bool isIcex) internal {
        if (isIcex) {
            luckydrawContract.aggregateIcexWinners(phase);
        }
        address[] memory winners = luckydrawContract.getWinners(phase);

        uint256 bonus = ethAmount.mul(luckyDrawRate).div(100).div(winners.length);
        if (winners.length == 0 && bonus > 0){
            transferToFoundation(bonus);
            return;
        }

        for (uint256 i = 0; i < winners.length; i++) {
            address payable addr = winners[i].make_payable();
            addr.transfer(bonus);
            emit LuckydrawSettle(phase, winners[i], bonus);
        }
    }

    function settleTopInvestor (uint256 phase, uint256 ethAmount) internal {
        uint256 bonus = ethAmount.mul(topInvestorRate).div(100);
        if (topInvestor[phase].length == 0 && bonus > 0){
            transferToFoundation(bonus);
            return;
        }

        uint256 len = topInvestor[phase].length;
        uint256[] memory factors = invitationContract.distributeBonus(len);
        for (uint256 i = 0; i < topInvestor[phase].length; i++) {
            address payable addr = topInvestor[phase][i].make_payable();
            uint256 iBonus = bonus.mul(factors[i]).div(len).div(len);
            addr.transfer(iBonus);
            emit InvestorSettle(phase, addr, iBonus);
        }
    }

    function settleInvitation (uint256 phase, uint256 ethAmount) internal {
        uint256 totalBonus = ethAmount.mul(invitationRate).div(100);
        address[] memory winners = invitationContract.getTop(phase);
        if (winners.length == 0 && totalBonus > 0){
            transferToFoundation(totalBonus);
            return;
        }

        uint256 len = winners.length;
        uint256[] memory factors = invitationContract.distributeBonus(len);
        for (uint256 i = 0; i < factors.length; i++) {
            uint256 bonus = totalBonus.mul(factors[i]).div(len).div(len);
            address payable addr = winners[i].make_payable();
            addr.transfer(bonus);
            emit InvitationSettle(phase, winners[i], bonus);
        }
    }

    function distributeCRBonus(uint256 phase) internal {
        if (phase < bonusRate.length || phase >= bonusRate.length + crBonusReleasePhases) {
          return;
        }

        for (uint256 i = 0; i < icexInvestors.length; i++) {
            address addr = icexInvestors[i];
            balances[addr] = balances[addr].add(crBonus[addr]);
            emit Transfer(address(this), addr, crBonus[addr]);
        }
    }
}

