pragma solidity ^0.5.8;


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract BloctoPointExchange is Ownable {
    event Buy(address buyer, address receiver, uint256 ethAmount, uint256 daiAmount, uint256 point);

    uint256 deadline = 2**256 - 1;
    uint256 daiPerPoint;
    uint256 minPoint;
    address payable bloctoReceiver;
    address uniswapExContract;
    address daiERC20Contract;

    constructor(address owner, address _uniswapExContract, address _daiERC20Contract, address payable _bloctoReceiver, uint256 _daiPerPoint, uint256 _minPoint) public {
        transferOwnership(owner);
        uniswapExContract = _uniswapExContract;
        daiERC20Contract = _daiERC20Contract;
        bloctoReceiver = _bloctoReceiver;
        daiPerPoint = _daiPerPoint;
        minPoint = _minPoint;
    }

    function() external payable {
        if (msg.value > 0) {
          bloctoReceiver.transfer(msg.value);
        }
    }

    function getExDetail() external view returns(address _owner, address _uniswapExContract, address _daiERC20Contract, address _bloctoReceiver, uint256 _daiPerPoint, uint256 _minPoint) {
        return (owner(), uniswapExContract, daiERC20Contract, bloctoReceiver, daiPerPoint, minPoint);
    }

    function setBloctoReceiver(address payable _bloctoReceiver) external onlyOwner {
        bloctoReceiver = _bloctoReceiver;
    }

    function setDaiPerPoint(uint256 _daiPerPoint) external onlyOwner {
        daiPerPoint = _daiPerPoint;
    }

    function setMinPoint(uint256 _minPoint) external onlyOwner {
            minPoint = _minPoint;
    }

    function buyBP() external payable {
        UniswapExchangeInterface _uniswapExContract = UniswapExchangeInterface(uniswapExContract);
        ERC20Interface _daiERC20Contract = ERC20Interface(daiERC20Contract);

        uint256 daiAmount = _uniswapExContract.ethToTokenSwapInput.value(msg.value)(daiPerPoint, deadline);
        uint256 point = daiAmount / daiPerPoint;
        require(point >= minPoint, "point < minPoint");

        bool success = _daiERC20Contract.transfer(bloctoReceiver, daiAmount);
        require(success, "transfer dai fail");

        emit Buy(msg.sender, msg.sender, msg.value, daiAmount, point);
    }

    // make sure `toAddr` is blocto wallet address
    function buyBPTo(address toAddr) external payable {
        UniswapExchangeInterface _uniswapExContract = UniswapExchangeInterface(uniswapExContract);
        ERC20Interface _daiERC20Contract = ERC20Interface(daiERC20Contract);

        uint256 daiAmount = _uniswapExContract.ethToTokenSwapInput.value(msg.value)(daiPerPoint, deadline);
        uint256 point = daiAmount / daiPerPoint;
        require(point >= minPoint, "point < minPoint");

        bool success = _daiERC20Contract.transfer(bloctoReceiver, daiAmount);
        require(success, "transfer dai fail");

        emit Buy(msg.sender, toAddr, msg.value, daiAmount, point);
    }

    function estimateBP(uint256 ethAmount) external view returns(uint256) {
        UniswapExchangeInterface _uniswapExContract = UniswapExchangeInterface(uniswapExContract);
        uint256 daiAmount = _uniswapExContract.getEthToTokenInputPrice(ethAmount);
        uint256 point = daiAmount / daiPerPoint;
        return point;
    }
}
