// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "@bancor/contracts/solidity/contracts/utility/Utils.sol";
import "@bancor/contracts/solidity/contracts/utility/Time.sol";
import "@bancor/contracts/solidity/contracts/utility/interfaces/IOwned.sol";
import "@bancor/contracts/solidity/contracts/converter/interfaces/IConverter.sol";
import "@bancor/contracts/solidity/contracts/token/interfaces/IDSToken.sol";
import "@bancor/contracts/solidity/contracts/token/interfaces/IERC20Token.sol";

import "./IStakingRewardsStore.sol";

/**
 * @dev This contract stores staking rewards liquidity and pool specific data
 */
contract StakingRewardsStore is IStakingRewardsStore, AccessControl, Utils, Time {
    using SafeMath for uint32;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // the supervisor role is used to globally govern the contract and its governing roles.
    bytes32 public constant ROLE_SUPERVISOR = keccak256("ROLE_SUPERVISOR");

    // the owner role is used to set the values in the store.
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");

    // the manager role is used to manage the programs in the store.
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");

    // the seeder roles is used to seed the store with past values.
    bytes32 public constant ROLE_SEEDER = keccak256("ROLE_SEEDER");

    uint32 private constant PPM_RESOLUTION = 1000000;

    // the mapping between pool tokens and their respective rewards program information.
    mapping(IDSToken => PoolProgram) private _programs;

    // the set of participating pools.
    EnumerableSet.AddressSet private _pools;

    // the mapping between pools, reserve tokens, and their rewards.
    mapping(IDSToken => mapping(IERC20Token => PoolRewards)) internal _poolRewards;

    // the mapping between pools, reserve tokens, and provider specific rewards.
    mapping(address => mapping(IDSToken => mapping(IERC20Token => ProviderRewards))) internal _providerRewards;

    // the mapping between providers and their respective last claim times.
    mapping(address => uint256) private _providerLastClaimTimes;

    /**
     * @dev triggered when a program is being added
     *
     * @param poolToken the pool token representing the rewards pool
     * @param startTime the starting time of the program
     * @param endTime the ending time of the program
     * @param rewardRate the program's rewards rate per-second
     */
    event PoolProgramAdded(IDSToken indexed poolToken, uint256 startTime, uint256 endTime, uint256 rewardRate);

    /**
     * @dev triggered when a program is being removed
     *
     * @param poolToken the pool token representing the rewards pool
     */
    event PoolProgramRemoved(IDSToken indexed poolToken);

    /**
     * @dev triggered when provider's last claim time is being updated
     *
     * @param provider the owner of the liquidity
     * @param claimTime the time of the last claim
     */
    event ProviderLastClaimTimeUpdated(address indexed provider, uint256 claimTime);

    /**
     * @dev initializes a new StakingRewardsStore contract
     */
    constructor() public {
        // set up administrative roles.
        _setRoleAdmin(ROLE_SUPERVISOR, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_OWNER, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_MANAGER, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_SEEDER, ROLE_SUPERVISOR);

        // allow the deployer to initially govern the contract.
        _setupRole(ROLE_SUPERVISOR, _msgSender());
    }

    // allows execution only by an owner
    modifier onlyOwner {
        _hasRole(ROLE_OWNER);
        _;
    }

    // allows execution only by an manager
    modifier onlyManager {
        _hasRole(ROLE_MANAGER);
        _;
    }

    // allows execution only by a seeder
    modifier onlySeeder {
        _hasRole(ROLE_SEEDER);
        _;
    }

    // error message binary size optimization
    function _hasRole(bytes32 role) internal view {
        require(hasRole(role, msg.sender), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev returns whether the specified pool is participating in the rewards program
     *
     * @param poolToken the pool token representing the rewards pool
     *
     * @return whether the specified pool is participating in the rewards program
     */
    function isPoolParticipating(IDSToken poolToken) public view override returns (bool) {
        PoolProgram memory program = _programs[poolToken];

        return program.endTime > time();
    }

    /**
     * @dev returns whether the specified reserve is participating in the rewards program
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token of the added liquidity
     *
     * @return whether the specified reserve is participating in the rewards program
     */
    function isReserveParticipating(IDSToken poolToken, IERC20Token reserveToken) public view override returns (bool) {
        if (!isPoolParticipating(poolToken)) {
            return false;
        }

        PoolProgram memory program = _programs[poolToken];

        return program.reserveTokens[0] == reserveToken || program.reserveTokens[1] == reserveToken;
    }

    /**
     * @dev adds a program
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveTokens the reserve tokens representing the liquidity in the pool
     * @param rewardShares reserve reward shares
     * @param endTime the ending time of the program
     * @param rewardRate the program's rewards rate per-second
     */
    function addPoolProgram(
        IDSToken poolToken,
        IERC20Token[2] calldata reserveTokens,
        uint32[2] calldata rewardShares,
        uint256 endTime,
        uint256 rewardRate
    ) external override onlyManager validAddress(address(poolToken)) {
        uint256 currentTime = time();

        addPoolProgram(poolToken, reserveTokens, rewardShares, currentTime, endTime, rewardRate);

        emit PoolProgramAdded(poolToken, currentTime, endTime, rewardRate);
    }

    /**
     * @dev adds past programs
     *
     * @param poolTokens pool tokens representing the rewards pool
     * @param reserveTokens reserve tokens representing the liquidity in the pool
     * @param rewardShares reserve reward shares
     * @param startTime starting times of the program
     * @param endTimes ending times of the program
     * @param rewardRates program's rewards rate per-second
     */
    function addPastPoolPrograms(
        IDSToken[] calldata poolTokens,
        IERC20Token[2][] calldata reserveTokens,
        uint32[2][] calldata rewardShares,
        uint256[] calldata startTime,
        uint256[] calldata endTimes,
        uint256[] calldata rewardRates
    ) external onlySeeder {
        uint256 length = poolTokens.length;
        require(
            length == reserveTokens.length &&
                length == rewardShares.length &&
                length == startTime.length &&
                length == endTimes.length &&
                length == rewardRates.length,
            "ERR_INVALID_LENGTH"
        );

        for (uint256 i = 0; i < length; ++i) {
            addPastPoolProgram(
                poolTokens[i],
                reserveTokens[i],
                rewardShares[i],
                startTime[i],
                endTimes[i],
                rewardRates[i]
            );
        }
    }

    /**
     * @dev adds a past program
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveTokens the reserve tokens representing the liquidity in the pool
     * @param rewardShares reserve reward shares
     * @param startTime the starting time of the program
     * @param endTime the ending time of the program
     * @param rewardRate the program's rewards rate per-second
     */
    function addPastPoolProgram(
        IDSToken poolToken,
        IERC20Token[2] calldata reserveTokens,
        uint32[2] calldata rewardShares,
        uint256 startTime,
        uint256 endTime,
        uint256 rewardRate
    ) private validAddress(address(poolToken)) {
        require(startTime < time(), "ERR_INVALID_TIME");

        addPoolProgram(poolToken, reserveTokens, rewardShares, startTime, endTime, rewardRate);
    }

    /**
     * @dev adds a program
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveTokens the reserve tokens representing the liquidity in the pool
     * @param rewardShares reserve reward shares
     * @param endTime the ending time of the program
     * @param rewardRate the program's rewards rate per-second
     */
    function addPoolProgram(
        IDSToken poolToken,
        IERC20Token[2] calldata reserveTokens,
        uint32[2] calldata rewardShares,
        uint256 startTime,
        uint256 endTime,
        uint256 rewardRate
    ) private {
        require(startTime < endTime && endTime > time(), "ERR_INVALID_DURATION");
        require(rewardRate > 0, "ERR_ZERO_VALUE");
        require(rewardShares[0].add(rewardShares[1]) == PPM_RESOLUTION, "ERR_INVALID_REWARD_SHARES");

        require(_pools.add(address(poolToken)), "ERR_ALREADY_PARTICIPATING");

        PoolProgram storage program = _programs[poolToken];
        program.startTime = startTime;
        program.endTime = endTime;
        program.rewardRate = rewardRate;
        program.rewardShares = rewardShares;

        // verify that reserve tokens correspond to the pool.
        IConverter converter = IConverter(payable(IConverterAnchor(poolToken).owner()));
        uint256 length = converter.connectorTokenCount();
        require(length == 2, "ERR_POOL_NOT_SUPPORTED");

        require(
            (address(converter.connectorTokens(0)) == address(reserveTokens[0]) &&
                address(converter.connectorTokens(1)) == address(reserveTokens[1])) ||
                (address(converter.connectorTokens(0)) == address(reserveTokens[1]) &&
                    address(converter.connectorTokens(1)) == address(reserveTokens[0])),
            "ERR_INVALID_RESERVE_TOKENS"
        );
        program.reserveTokens = reserveTokens;
    }

    /**
     * @dev removes a program
     *
     * @param poolToken the pool token representing the rewards pool
     */
    function removePoolProgram(IDSToken poolToken) external override onlyManager {
        require(_pools.remove(address(poolToken)), "ERR_POOL_NOT_PARTICIPATING");

        delete _programs[poolToken];

        emit PoolProgramRemoved(poolToken);
    }

    /**
     * @dev updates the ending time of a program
     * note that the new ending time must be in the future
     *
     * @param poolToken the pool token representing the rewards pool
     * @param newEndTime the new ending time of the program
     */
    function setPoolProgramEndTime(IDSToken poolToken, uint256 newEndTime) external override onlyManager {
        require(isPoolParticipating(poolToken), "ERR_POOL_NOT_PARTICIPATING");

        PoolProgram storage program = _programs[poolToken];
        require(newEndTime > time(), "ERR_INVALID_DURATION");

        program.endTime = newEndTime;
    }

    /**
     * @dev returns a program
     *
     * @return the program's starting and ending times
     */
    function poolProgram(IDSToken poolToken)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            IERC20Token[2] memory,
            uint32[2] memory
        )
    {
        PoolProgram memory program = _programs[poolToken];

        return (program.startTime, program.endTime, program.rewardRate, program.reserveTokens, program.rewardShares);
    }

    /**
     * @dev returns all programs
     *
     * @return all programs
     */
    function poolPrograms()
        external
        view
        override
        returns (
            IDSToken[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            IERC20Token[2][] memory,
            uint32[2][] memory
        )
    {
        uint256 length = _pools.length();

        IDSToken[] memory poolTokens = new IDSToken[](length);
        uint256[] memory startTimes = new uint256[](length);
        uint256[] memory endTimes = new uint256[](length);
        uint256[] memory rewardRates = new uint256[](length);
        IERC20Token[2][] memory reserveTokens = new IERC20Token[2][](length);
        uint32[2][] memory rewardShares = new uint32[2][](length);

        for (uint256 i = 0; i < length; ++i) {
            IDSToken poolToken = IDSToken(_pools.at(i));
            PoolProgram memory program = _programs[poolToken];

            poolTokens[i] = poolToken;
            startTimes[i] = program.startTime;
            endTimes[i] = program.endTime;
            rewardRates[i] = program.rewardRate;
            reserveTokens[i] = program.reserveTokens;
            rewardShares[i] = program.rewardShares;
        }

        return (poolTokens, startTimes, endTimes, rewardRates, reserveTokens, rewardShares);
    }

    /**
     * @dev returns the rewards data of a specific reserve in a specific pool
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     *
     * @return rewards data
     */
    function poolRewards(IDSToken poolToken, IERC20Token reserveToken)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        PoolRewards memory data = _poolRewards[poolToken][reserveToken];

        return (data.lastUpdateTime, data.rewardPerToken, data.totalClaimedRewards);
    }

    /**
     * @dev updates the reward data of a specific reserve in a specific pool
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     * @param lastUpdateTime the last update time
     * @param rewardPerToken the new reward rate per-token
     * @param totalClaimedRewards the total claimed rewards up until now
     */
    function updatePoolRewardsData(
        IDSToken poolToken,
        IERC20Token reserveToken,
        uint256 lastUpdateTime,
        uint256 rewardPerToken,
        uint256 totalClaimedRewards
    ) external override onlyOwner {
        PoolRewards storage data = _poolRewards[poolToken][reserveToken];
        data.lastUpdateTime = lastUpdateTime;
        data.rewardPerToken = rewardPerToken;
        data.totalClaimedRewards = totalClaimedRewards;
    }

    /**
     * @dev seeds pool rewards data for multiple pools
     *
     * @param poolTokens pool tokens representing the rewards pool
     * @param reserveTokens reserve tokens representing the liquidity in the pool
     * @param lastUpdateTimes last update times (for both the network and reserve tokens)
     * @param rewardsPerToken reward rates per-token (for both the network and reserve tokens)
     * @param totalClaimedRewards total claimed rewards up until now (for both the network and reserve tokens)
     */
    function setPoolsRewardData(
        IDSToken[] calldata poolTokens,
        IERC20Token[] calldata reserveTokens,
        uint256[] calldata lastUpdateTimes,
        uint256[] calldata rewardsPerToken,
        uint256[] calldata totalClaimedRewards
    ) external onlySeeder {
        uint256 length = poolTokens.length;
        require(
            length == reserveTokens.length && length == lastUpdateTimes.length && length == rewardsPerToken.length,
            "ERR_INVALID_LENGTH"
        );

        for (uint256 i = 0; i < length; ++i) {
            IDSToken poolToken = poolTokens[i];
            _validAddress(address(poolToken));

            IERC20Token reserveToken = reserveTokens[i];
            _validAddress(address(reserveToken));

            PoolRewards storage data = _poolRewards[poolToken][reserveToken];
            data.lastUpdateTime = lastUpdateTimes[i];
            data.rewardPerToken = rewardsPerToken[i];
            data.totalClaimedRewards = totalClaimedRewards[i];
        }
    }

    /**
     * @dev returns rewards data of a specific provider
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     *
     * @return rewards data
     */
    function providerRewards(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint32
        )
    {
        ProviderRewards memory data = _providerRewards[provider][poolToken][reserveToken];

        return (
            data.rewardPerToken,
            data.pendingBaseRewards,
            data.totalClaimedRewards,
            data.effectiveStakingTime,
            data.baseRewardsDebt,
            data.baseRewardsDebtMultiplier
        );
    }

    /**
     * @dev updates provider rewards data
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     * @param rewardPerToken the new reward rate per-token
     * @param pendingBaseRewards the updated pending base rewards
     * @param totalClaimedRewards the total claimed rewards up until now
     * @param effectiveStakingTime the new effective staking time
     * @param baseRewardsDebt the updated base rewards debt
     * @param baseRewardsDebtMultiplier the updated base rewards debt multiplier
     */
    function updateProviderRewardsData(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken,
        uint256 rewardPerToken,
        uint256 pendingBaseRewards,
        uint256 totalClaimedRewards,
        uint256 effectiveStakingTime,
        uint256 baseRewardsDebt,
        uint32 baseRewardsDebtMultiplier
    ) external override onlyOwner {
        ProviderRewards storage data = _providerRewards[provider][poolToken][reserveToken];

        data.rewardPerToken = rewardPerToken;
        data.pendingBaseRewards = pendingBaseRewards;
        data.totalClaimedRewards = totalClaimedRewards;
        data.effectiveStakingTime = effectiveStakingTime;
        data.baseRewardsDebt = baseRewardsDebt;
        data.baseRewardsDebtMultiplier = baseRewardsDebtMultiplier;
    }

    /**
     * @dev seeds specific provider's reward data for multiple providers
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token in the rewards pool
     * @param providers owners of the liquidity
     * @param rewardsPerToken new reward rates per-token
     * @param pendingBaseRewards updated pending base rewards
     * @param totalClaimedRewards total claimed rewards up until now
     * @param effectiveStakingTimes new effective staking times
     * @param baseRewardsDebts updated base rewards debts
     * @param baseRewardsDebtMultipliers updated base rewards debt multipliers
     */
    function setProviderRewardData(
        IDSToken poolToken,
        IERC20Token reserveToken,
        address[] memory providers,
        uint256[] memory rewardsPerToken,
        uint256[] memory pendingBaseRewards,
        uint256[] memory totalClaimedRewards,
        uint256[] memory effectiveStakingTimes,
        uint256[] memory baseRewardsDebts,
        uint32[] memory baseRewardsDebtMultipliers
    ) external onlySeeder validAddress(address(poolToken)) validAddress(address(reserveToken)) {
        uint256 length = providers.length;
        require(
            length == rewardsPerToken.length &&
                length == pendingBaseRewards.length &&
                length == totalClaimedRewards.length &&
                length == effectiveStakingTimes.length &&
                length == baseRewardsDebts.length &&
                length == baseRewardsDebtMultipliers.length,
            "ERR_INVALID_LENGTH"
        );

        for (uint256 i = 0; i < length; ++i) {
            ProviderRewards storage data = _providerRewards[providers[i]][poolToken][reserveToken];

            uint256 baseRewardsDebt = baseRewardsDebts[i];
            uint32 baseRewardsDebtMultiplier = baseRewardsDebtMultipliers[i];
            require(
                baseRewardsDebt == 0 ||
                    (baseRewardsDebtMultiplier >= PPM_RESOLUTION && baseRewardsDebtMultiplier <= 2 * PPM_RESOLUTION),
                "ERR_INVALID_MULTIPLIER"
            );

            data.rewardPerToken = rewardsPerToken[i];
            data.pendingBaseRewards = pendingBaseRewards[i];
            data.totalClaimedRewards = totalClaimedRewards[i];
            data.effectiveStakingTime = effectiveStakingTimes[i];
            data.baseRewardsDebt = baseRewardsDebts[i];
            data.baseRewardsDebtMultiplier = baseRewardsDebtMultiplier;
        }
    }

    /**
     * @dev updates provider's last claim time
     *
     * @param provider the owner of the liquidity
     */
    function updateProviderLastClaimTime(address provider) external override onlyOwner {
        uint256 time = time();
        _providerLastClaimTimes[provider] = time;

        emit ProviderLastClaimTimeUpdated(provider, time);
    }

    /**
     * @dev returns provider's last claim time
     *
     * @param provider the owner of the liquidity
     *
     * @return provider's last claim time
     */
    function providerLastClaimTime(address provider) external view override returns (uint256) {
        return _providerLastClaimTimes[provider];
    }
}

