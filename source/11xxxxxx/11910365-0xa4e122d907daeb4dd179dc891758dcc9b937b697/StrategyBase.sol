pragma solidity >=0.6.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IJar.sol";
import "./IStakingRewards.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapRouterV2.sol";
import './Ownable.sol';

abstract contract StrategyBase is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Tokens
    address public want; //The LP token, Harvest calls this "rewardToken", which is a better name tbh
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // User accounts
    address public strategist; //The address the performance fee is sent to
    address public jar;

    // Dex
    address public uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public currentRouter = uniRouter;
    

    constructor(
        address _want,
        address _strategist
    ) public {
        require(_want != address(0));
        require(_strategist != address(0));

        want = _want;
        strategist = _strategist;
    }

    // **** Modifiers **** //
    
    //Replaced with Ownable, which allows me to transfer ownership of the contract
    /*modifier onlyStrategist { 
        require(msg.sender == strategist, "!strategist");
        _;
    }*/

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public virtual view returns (uint256);

    function getHarvestable() external virtual view returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external virtual pure returns (string memory);

    // **** Setters **** //

    function setJar(address _jar) external onlyOwner {
        require(jar == address(0), "jar already set");
        jar = _jar;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    function depositLocked(uint256 _secs) public virtual;

    // Jar only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == jar, "!jar");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(jar, balance);
    }

    // Withdraw partial funds, normally used with a jar withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == jar, "!jar");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(jar, _amount);
    }

    // Withdraw funds, used to swap between strategies
    function withdrawForSwap(uint256 _amount)
        external
        returns (uint256 balance)
    {
        require(msg.sender == jar, "!jar");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(jar, balance);
    }
    
    // Withdraw locked funds
    function withdrawLocked(bytes32 kek_id)
        external
        returns (uint256 balance)
    {
        require(msg.sender == jar, "!jar");
        _withdrawSomeLocked(kek_id);

        balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(jar, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function _withdrawSomeLocked(bytes32 kek_id) internal virtual;

    function harvest() public virtual;

    // **** Emergency functions ****

    //In case of an emergency, pass ownership to the Frax deployer
    address public frax_deployer = 0xa448833bEcE66fD8803ac0c390936C79b5FD6eDf;

    /**
     * @param _target address of the target contract
     * @param _data calldata used to identify what function to execute on the target 
     */
    function execute(address _target, bytes memory _data)
        public
        payable
        onlyOwner
        returns (bytes memory response)
    {
        require(_target != address(0), "!target");
        require(msg.sender == frax_deployer);

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(add(response, 0x20), size)
                }
        }
    }

    // **** Internal functions ****
    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        // Swap with uniswap (we give unlimited approval to the Uniswap/Sushiswap routers)
        //IERC20(_from).safeApprove(univ2Router2, 0);
        //IERC20(_from).safeApprove(univ2Router2, _amount);

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(currentRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _swapUniswapWithPath(
        address[] memory path,
        uint256 _amount
    ) internal {
        require(path[1] != address(0));

        // Swap with uniswap
        //IERC20(path[0]).safeApprove(univ2Router2, 0);
        //IERC20(path[0]).safeApprove(univ2Router2, _amount);

        IUniswapRouterV2(currentRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    //Distribution of performance fee is handled in StrategyFraxFarmBase.harvest()
    function _distributePerformanceFeesAndDeposit() internal {
        uint256 _want = IERC20(want).balanceOf(address(this));

        if (_want > 0) {
            deposit();
        }
    }
}
