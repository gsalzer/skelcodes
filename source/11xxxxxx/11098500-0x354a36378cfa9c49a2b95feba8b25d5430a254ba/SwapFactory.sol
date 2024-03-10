// SPDX-License-Identifier: No License (None)
pragma solidity =0.6.12;

//import "./SafeMath.sol";
//import "./Ownable.sol";
import "./SwapPair.sol";


interface IValidator {
    // returns: user balance, native (foreign for us) encoded balance, foreign (native for us) encoded balance
    function checkBalances(address pair, address foreignSwapPair, address user) external returns(uint256);
    // returns: user balance
    function checkBalance(address pair, address foreignSwapPair, address user) external returns(uint256);
    // returns: oracle fee
    function getOracleFee(uint256 req) external returns(uint256);  //req: 1 - cancel, 2 - claim, returns: value
}

interface IGatewayVault {
    function vaultTransfer(address token, address recipient, uint256 amount) external returns (bool);
    function vaultApprove(address token, address spender, uint256 amount) external returns (bool);
}

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns(bool);
}

contract SwapJNTRFactory is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => address payable)) public getPair;
    mapping(address => address) public foreignPair;
    address[] public allPairs;
    address public foreignFactory;

    mapping(address => bool) public canMint;  //if token we cen mint and burn token

    uint256 public fee;
    address payable public validator;
    address public system;  // system address mey change fee amount
    bool public paused;
    address public gatewayVault; // GatewayVault contract

    address public newFactory;            // new factory address to upgrade
    event PairCreated(address indexed tokenA, address indexed tokenB, address pair, uint);
    event SwapRequest(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);
    event Swap(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);

    event ClaimRequest(address indexed tokenA, address indexed tokenB, address indexed user);
    event ClaimApprove(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);

    modifier notPaused() {
        require(!paused,"Swap paused");
        _;
    }

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem() {
        require(msg.sender == system, "Caller is not the system");
        _;
    }

    constructor (address _system, address _vault) public {
        system = _system;
        newFactory = address(this);
        gatewayVault = _vault;
    }

    function setFee(uint256 _fee) external onlySystem returns(bool) {
        fee = _fee;
        return true;
    }

    function setSystem(address _system) external onlyOwner returns(bool) {
        system = _system;
        return true;
    }

    function setValidator(address payable _validator) external onlyOwner returns(bool) {
        validator = _validator;
        return true;
    }

    function setPause(bool pause) external onlyOwner returns(bool) {
        paused = pause;
        return true;
    }

    function setForeignFactory(address _addr) external onlyOwner returns(bool) {
        foreignFactory = _addr;
        return true;
    }
    
    function setNewFactory(address _addr) external onlyOwner returns(bool) {
        newFactory = _addr;
        return true;
    }
    
    function setMintableToken(address _addr, bool _canMint) external onlyOwner returns(bool) {
        canMint[_addr] = _canMint;
        return true;
    }
    // TakenA should be JNTR token
    // for local swap (tokens on the same chain): pair = address(1) when TokenA = JNTR, and address(2) when TokenB = JNTR
    function createPair(address tokenA, address tokenB, bool local) public onlyOwner returns (address payable pair) {
        require(getPair[tokenA][tokenB] == address(0), 'PAIR_EXISTS'); // single check is sufficient
        if (local) {
            pair = payable(address(1));
            getPair[tokenA][tokenB] = pair;
            getPair[tokenB][tokenA] = pair;
            emit PairCreated(tokenA, tokenB, pair, allPairs.length);
            return pair;            
        }

        bytes memory bytecode = type(SwapJNTRPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        foreignPair[pair] = getForeignPair(tokenB, tokenA);
        SwapJNTRPair(pair).initialize(foreignPair[pair], tokenA, tokenB);

        getPair[tokenA][tokenB] = pair;
        allPairs.push(pair);
        emit PairCreated(tokenA, tokenB, pair, allPairs.length);
    }

    function getForeignPair(address tokenA, address tokenB) internal view returns(address pair) {
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                foreignFactory,
                keccak256(abi.encodePacked(tokenA, tokenB)),
                hex'a79d0b2d0d229d9f2750acf6e4ca00b89da9065d62058701247d526ed6b3e65d' // init code hash
            ))));
    }

    // set already existed pairs in case of contract upgrade
    function setPairs(address[] memory tokenA, address[] memory tokenB, address payable[] memory pair) external onlyOwner returns(bool) {
        uint256 len = tokenA.length;
        while (len > 0) {
            len--;
            getPair[tokenA[len]][tokenB[len]] = pair[len];
            if (pair[len] > address(8)) // we can use address(0)- address(8) as special marker
                foreignPair[pair[len]] = SwapJNTRPair(pair[len]).foreignSwapPair();
            allPairs.push(pair[len]);
            emit PairCreated(tokenA[len], tokenB[len], pair[len], allPairs.length);            
        }
        return true;
    }
    // calculates the CREATE2 address for a pair without making any external calls
    function pairAddressFor(address tokenA, address tokenB) external view returns (address pair, bytes32 bytecodeHash) {
        bytes memory bytecode = type(SwapJNTRPair).creationCode;
        bytecodeHash = keccak256(bytecode);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(tokenA, tokenB)),
                bytecodeHash    // hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    //user should approve tokens transfer before calling this function.
    // for local swap (tokens on the same chain): pair = address(1) when TokenA = JNTR, and address(2) when TokenB = JNTR
    function swap(address tokenA, address tokenB, uint256 amount) external payable notPaused returns (bool) {
        require(amount != 0, "Zero amount");
        address payable pair = getPair[tokenA][tokenB];
        require(pair != address(0), 'PAIR_NOT_EXISTS');

        if (canMint[tokenA])
            IBEP20(tokenA).burnFrom(msg.sender, amount);
        else {
            require(gatewayVault != address(0), "No vault address");
            IBEP20(tokenA).transferFrom(msg.sender, gatewayVault, amount);
        }

        if (pair == address(1)) { //local pair
            if (canMint[tokenB])
                IBEP20(tokenB).mint(msg.sender, amount);
            else
                IGatewayVault(gatewayVault).vaultTransfer(tokenB, msg.sender, amount);
            emit Swap(tokenA, tokenB, msg.sender, amount);
        }
        else {  // foreign pair
            require(msg.value >= fee,"Insufficient fee");
            // transfer fee to validator. May be changed to request tokens for compensation
            validator.transfer(msg.value);
            SwapJNTRPair(pair).deposit(msg.sender, amount);
            emit SwapRequest(tokenA, tokenB, msg.sender, amount);
        }
        return true;
    }

    function _claim(address tokenA, address tokenB, address user) internal {
        address payable pair = getPair[tokenA][tokenB];
        require(pair > address(9), 'PAIR_NOT_EXISTS');
        IValidator(validator).checkBalance(pair, foreignPair[pair], user);
        emit ClaimRequest(tokenA, tokenB, user);
    }
    // amountB - amount of foreign token to swap
    function claimTokenBehalf(address tokenA, address tokenB, address user) external onlySystem notPaused returns (bool) {
        _claim(tokenA, tokenB, user);
        return true;
    }

    function claim(address tokenA, address tokenB) external payable notPaused returns (bool) {
        uint256 claimFee = IValidator(validator).getOracleFee(1);
        require (msg.value >= claimFee, "Not enough fee");
        _claim(tokenA, tokenB, msg.sender);
        return true;
    }

    // On both side (BEP and ERC) we accumulate user's deposits (balance).
    // If balance on one side it greater then on other, the difference means user deposit.
    function balanceCallback(address payable pair, address user, uint256 balanceForeign) external returns(bool) {
        require (validator == msg.sender, "Not validator");
        address tokenA;
        address tokenB;
        address swapAddress = address(uint160(user)+1);
        uint256 swappedBalance = SwapJNTRPair(pair).balanceOf(swapAddress);
        require(balanceForeign > swappedBalance, "No tokens deposit");
        uint256 amount = balanceForeign - swappedBalance;
        (tokenA, tokenB) = SwapJNTRPair(pair).claimApprove(user, amount);
        if (canMint[tokenA])
            IBEP20(tokenA).mint(user, amount);
        else
            IGatewayVault(gatewayVault).vaultTransfer(tokenA, user, amount);        
        emit ClaimApprove(tokenA, tokenB, user, amount);
        return true;
    }
}
