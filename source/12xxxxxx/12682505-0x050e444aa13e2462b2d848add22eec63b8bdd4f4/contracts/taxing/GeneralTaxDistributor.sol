// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IGeneralTaxDistributor.sol";
import "../common/IFerrumDeployer.sol";
import "../common/math/RandomHelper.sol";
import "../common/IBurnable.sol";
import "../staking/interfaces/IRewardPool.sol";

/**
 * General tax distributor.
 */
contract GeneralTaxDistributor is IGeneralTaxDistributor, Ownable {
    using SafeERC20 for IERC20;
    enum TargetType {NotSet, Burn, Address, RewardPool}
    struct TokenInfo {
        uint248 bufferSize;
        uint8 tokenSpecificConfig; // 1 or 0
    }
    struct TargetConfig {
        uint8 len; // Max 27 weights
        uint32 totalW;
        uint216 weights;
    }
    struct TargetInfo {
        address tgt;
        TargetType tType;
    }

    mapping(address => bool) public allowedActors;
    mapping(address => TokenInfo) public tokenInfo;
    uint256 public immutable lowThresholdX1000;
    mapping(address => TargetConfig) public tokenTargetConfigs;
    mapping(address => TargetInfo[]) public tokenTargetInfos;
    TargetConfig public globalTargetConfig;
    TargetInfo[] public targetInfos;
    RandomHelper.RandomState roller;

    constructor() {
        bytes memory data = IFerrumDeployer(msg.sender).initData();
        (lowThresholdX1000) = abi.decode(data, (uint256));
    }

    function addAllowedActor(address actor) external onlyOwner {
        allowedActors[actor] = true;
    }

    function removeAllowedActor(address actor) external onlyOwner {
        delete allowedActors[actor];
    }

    function setTokenInfo(
        address tokenAdress,
        uint256 bufferSize,
        uint8 tokenSpecificConfig
    ) external onlyOwner {
        tokenInfo[tokenAdress] = TokenInfo({
            bufferSize: uint248(bufferSize),
            tokenSpecificConfig: tokenSpecificConfig
        });
    }

    function setTokenTargetInfos(
        address tokenAddess,
        TargetInfo[] memory infos,
        uint216 weights
    ) external onlyOwner {
        require(infos.length < 27, "GTD: infos too large");
        uint32 totalW = calcTotalW(uint8(infos.length), weights);
        TargetConfig memory conf =
            TargetConfig({
                len: uint8(infos.length),
                totalW: totalW,
                weights: weights
            });
        tokenTargetConfigs[tokenAddess] = conf;
        delete tokenTargetInfos[tokenAddess];
        for (uint256 i = 0; i < infos.length; i++) {
            tokenTargetInfos[tokenAddess].push(infos[i]);
        }
    }

    function setGlobalTargetInfos(TargetInfo[] memory infos, uint216 weights)
        external
        onlyOwner
    {
        require(infos.length < 27, "GTD: infos too large");
        uint32 totalW = calcTotalW(uint8(infos.length), weights);
        TargetConfig memory conf =
            TargetConfig({
                len: uint8(infos.length),
                totalW: totalW,
                weights: weights
            });
        globalTargetConfig = conf;
        delete targetInfos;
        for (uint256 i = 0; i < infos.length; i++) {
            targetInfos.push(infos[i]);
        }
    }

    function calcTotalW(uint8 len, uint256 weights)
        internal
        pure
        returns (uint32)
    {
        uint32 sum = 0;
        require(len < 256 / 8, "GTD: len too long");
        for (uint8 i = 0; i < len; i++) {
            uint8 mi = 8 * i;
            uint256 mask = 0xf << mi;
            uint256 poolRatio = mask & weights;
            poolRatio = poolRatio >> mi;
            require(poolRatio <= 256, "GTD: pool ratio too large");
            sum += uint32(poolRatio);
        }
        return sum;
    }

    function distributeTaxDirect(address token, address origSender)
        external
        returns (uint256)
    {
        RandomHelper.RandomState memory _state = roller;
        return _distributeTax(token, origSender, _state);
    }

    function distributeTax(address token, address origSender)
        external
        override
        returns (uint256 amount) {
        RandomHelper.RandomState memory _state = roller;
        bool _result = false;
        (_state, _result) = RandomHelper.rollingRandBool(
            _state,
            origSender,
            lowThresholdX1000
        );
        if (!_result) {
            return 0;
        } // Only randomly, once in a while, do the more expensive operation
        require(allowedActors[msg.sender], "GTD: Not allowed");
        return _distributeTax(token, origSender, _state);
    }

    function _distributeTax(
        address token,
        address origSender,
        RandomHelper.RandomState memory _roller
    ) internal returns (uint256) {
        // Check balance, if less than buffer
        TokenInfo memory ti = tokenInfo[token];
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < ti.bufferSize) {
            return 0;
        }
        require(allowedActors[msg.sender], "GTD: Not allowed");

        // Now lets distribute the balance
        (bytes26 newRoll, uint256 randX2p32) =
            RandomHelper.rollingRand(_roller.roll, origSender);
		console.log("Log %s and rand %s", uint208(newRoll), randX2p32);
        _roller.roll = newRoll;
        roller = _roller;
        TargetConfig memory target =
            ti.tokenSpecificConfig != 0
                ? tokenTargetConfigs[token]
                : globalTargetConfig;
        if (target.len == 0) {
            ti.tokenSpecificConfig = 0;
            target = globalTargetConfig;
        }
        uint8 idx = rollAndIndex(randX2p32, target); // Use round robbin distribution
        return distributeToTarget(idx, ti.tokenSpecificConfig, token, balance);
    }

    function rollAndIndex(uint256 randX2p32, TargetConfig memory _conf)
        internal
        pure
        returns (uint8)
    {
        uint256 sum = 0;
        uint256 w = _conf.weights;
        randX2p32 = (randX2p32 * _conf.totalW) / (2**32);
        for (uint8 i = 0; i < _conf.len; i++) {
            uint8 mi = 8 * i;
            uint256 mask = 0xf << mi;
            uint256 poolRatio = mask & w;
            poolRatio = poolRatio >> mi;
            sum += poolRatio;
            if (sum >= randX2p32 && poolRatio != 0) {
                return i;
            }
        }
        return 0;
    }

    function distributeToTarget(
        uint8 idx,
        uint8 fromToken,
        address token,
        uint256 balance
    ) internal returns (uint256) {
        TargetInfo memory tgt =
            fromToken != 0 ? tokenTargetInfos[token][idx] : targetInfos[idx];
        if (tgt.tType == TargetType.Burn) {
            IBurnable(token).burn(balance);
            return balance;
        }
        if (tgt.tType == TargetType.Address) {
            IERC20(token).safeTransfer(tgt.tgt, balance);
            return balance;
        }
        if (tgt.tType == TargetType.RewardPool) {
            IERC20(token).safeTransfer(tgt.tgt, balance);
            return IRewardPool(tgt.tgt).addMarginalReward(token);
        }
        return 0;
    }
}

