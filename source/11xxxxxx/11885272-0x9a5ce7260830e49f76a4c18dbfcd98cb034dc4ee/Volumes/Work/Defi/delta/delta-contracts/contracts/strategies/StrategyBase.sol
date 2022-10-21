pragma solidity 0.5.16;

import "./RewardTokenProfitNotifier.sol";
import "../interfaces/IStrategy.sol";

contract StrategyBase is IStrategy, RewardTokenProfitNotifier {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ProfitsNotCollected(address);
    event Liquidating(address, uint256);

    address public underlying;
    address public vault;
    mapping(address => bool) public unsalvagableTokens;
    address public uniswapRouterV2;

    modifier restricted() {
        require(
            msg.sender == vault ||
                msg.sender == address(controller()) ||
                msg.sender == address(governance()),
            "The sender has to be the controller or vault or governance"
        );
        _;
    }

    constructor(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardToken,
        address _uniswap
    ) public RewardTokenProfitNotifier(_storage, _rewardToken) {
        underlying = _underlying;
        vault = _vault;
        unsalvagableTokens[_rewardToken] = true;
        unsalvagableTokens[_underlying] = true;
        uniswapRouterV2 = _uniswap;
    }
}

