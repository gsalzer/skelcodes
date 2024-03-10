pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./tacoswapv2/interfaces/ITacoswapV2Pair.sol";
import "./tacoswapv2/interfaces/ITacoswapV2Factory.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IETacoChef.sol";
import "./MigratorDummy.sol";


/**
 *@title MigratorFull contract
 * - Users can:
 *   #Migrate` migrates LP tokens from TacoChef to eTacoChef
 *   #migrateUserInfo
 * - only owner can
 *   #MigratePools
 **/

contract MigratorFull {
    IMasterChef public oldChef;
    IETacoChef public newChef;
    MigratorDummy public dummyMigrator;

    address public uniFactory;
    address public sushiFactory;
    ITacoswapV2Factory public factory;

    uint256 public desiredLiquidity = type(uint256).max;

    IERC20 private _taco;
    IERC20 private _etaco;

    mapping(address => bool) public isMigrated;

    /**
     *  @param _oldChef The address of TacoChef contract.
     *  @param _newChef The address of eTacoChef.
     *  @param _dummyMigrator The address of MigratorDummy.
     *  @param _uniFactory The address of UniSwapV2Factory.
     *  @param _sushiFactory The address of SushiSwapFactory.
     *  @param _factory The address of TacoSwapFactory.
     *  @param tacoToken_ The address of TacoToken
     *  @param etaco_ The address of eTacoToken
     **/
    constructor(
        address _oldChef,
        address _newChef,
        address _dummyMigrator,
        address _uniFactory,
        address _sushiFactory,
        address _factory,
        address tacoToken_,
        address etaco_
    ) {
        require(_oldChef != address(0x0), "Migrator::set zero address");
        require(_dummyMigrator != address(0x0), "Migrator::set zero address");
        require(_newChef != address(0x0), "Migrator::set zero address");
        require(_uniFactory != address(0x0), "Migrator::set zero address");
        require(_sushiFactory != address(0x0), "Migrator::set zero address");
        require(tacoToken_ != address(0x0), "TacoToETaco::set zero address");
        require(etaco_ != address(0x0), "TacoToETaco::set zero address");
        _taco = IERC20(tacoToken_);
        _etaco = IERC20(etaco_);
        uniFactory = _uniFactory;
        sushiFactory = _sushiFactory;
        oldChef = IMasterChef(_oldChef);
        newChef = IETacoChef(_newChef);
        dummyMigrator = MigratorDummy(_dummyMigrator);
        factory = ITacoswapV2Factory(_factory);
    }

    /**
     *  @dev Migrates LP tokens from TacoChef to eTacoChef.
     *   DummyToken is neaded to pass require in TacoChef contracts migrate function.
     **/
    function migrate(ITacoswapV2Pair orig) public returns (IERC20) {
        require(
            msg.sender == address(oldChef),
            "Migrator: not from old master chef"
        );

        uint256 lp = orig.balanceOf(msg.sender);

        IERC20 dummyToken = IERC20(dummyMigrator.lpTokenToDummyToken(address(orig)));

        newChef.approveDummies(address(dummyToken));

        orig.transferFrom(msg.sender, address(newChef), lp);
        dummyToken.transferFrom(address(newChef), address(oldChef), lp);

        return dummyToken;
    }

    function migrateLP(ITacoswapV2Pair orig) public returns (ITacoswapV2Pair) {
        require(msg.sender == address(newChef), "not from master chef");
        require(
            orig.factory() == uniFactory || orig.factory() == sushiFactory,
            "Migrator: not from old factory"
        );

        address token0 = orig.token0();
        address token1 = orig.token1();
        ITacoswapV2Pair pair = ITacoswapV2Pair(factory.getPair(token0, token1));
        if (pair == ITacoswapV2Pair(address(0))) {
            pair = ITacoswapV2Pair(factory.createPair(token0, token1));
        }
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return pair;
        desiredLiquidity = lp;
        orig.transferFrom(msg.sender, address(orig), lp);
        orig.burn(address(pair));
        pair.mint(msg.sender);
        desiredLiquidity = type(uint256).max;
        return pair;
    }

    /**
     *  @dev Migrates UserInfo from TacoChef to eTacoChef.
     *   Can be called by user one time only.
     **/
    function migrateUserInfo() external {
        require(!isMigrated[msg.sender], "Migrator: Already migrated");
        uint256 oldPoolLength = oldChef.poolLength();
        for (uint256 i = 0; i < oldPoolLength; i++) {
            (, , , uint256 accTacoPerShare) = oldChef.poolInfo(i);
            (uint256 amount, ) = oldChef.userInfo(i, msg.sender);
            if (amount == 0) continue;
            newChef.setUser(i, msg.sender, amount, amount * accTacoPerShare / 1e12);
        }
        swap();
        isMigrated[msg.sender] = true;
    }

    
    /**
     *  @dev Migrates UserInfo from TacoChef to eTacoChef.
     *   Can be called by user one time and required to call deposit function.
     **/
    function swap() public {
        uint256 _amount = _taco.balanceOf(msg.sender);
        _taco.transferFrom(msg.sender, address(this), _amount);
        _etaco.transfer(msg.sender, _amount);
    }
}

