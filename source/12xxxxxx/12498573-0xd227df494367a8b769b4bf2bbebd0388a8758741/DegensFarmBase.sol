// SPDX-License-Identifier: MIT
// Degen Farm. Collectible NFT game
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./IERC721.sol";
import "./Ownable.sol";

interface IEggs is IERC721 {
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function getUsersTokens(address _owner) external view returns (uint256[] memory);
}


interface ICreatures is IERC721 {
    function mint(
        address to, 
        uint256 tokenId, 
        uint8 _animalType,
        uint8 _rarity,
        uint32 index
        ) external;

    function getTypeAndRarity(uint256 _tokenId) external view returns(uint8, uint8);
}

interface ILand is IERC721 {
    function mint(
        address to, 
        uint256 tokenId
    ) external;
    function burn(uint256 tokenId) external;
}

interface IDung is IERC20 {
    function mint(
        address to, 
        uint256 amount 
    ) external;
}

interface IInventory is IERC1155 {
     function getToolBoost(uint8 _item) external view returns (uint16);
}

interface IAmuletPriceProvider {
     function getLastPrice(address _amulet) external view returns (uint256);
}

interface IOperatorManage {
    function addOperator(address _newOperator) external;    
    function removeOperator(address _oldOperator) external;
    function withdrawERC20(IERC20 _tokenContract, address _admin) external;
}

abstract contract DegenFarmBase is ERC1155Receiver, Ownable {
    enum AnimalType {
        Cow, Horse, Rabbit, Chicken, Pig, Cat, Dog, Goose, Goat, Sheep,
        Snake, Fish, Frog, Worm, Lama, Mouse, Camel, Donkey, Bee, Duck,
        GenesisEgg // 20
    }
    enum Rarity     {
        Normie, // 0
        Chad,   // 1
        Degen,  // 2
        Unique // 3
    }
    enum   Result     {Fail,   Dung,  Chad, Degen}
    
    //External conatrct addresses used with this farm.
    struct AddressRegistry {
        address land;
        address creatures;
        address inventory;
        address bagstoken;
        address dungtoken;
    }

    //Degens Farm Key numbers
    struct CreaturesCount {
        uint16 totalNormie;
        uint16 leftNormie;
        uint16 totalChad;
        uint16 leftChadToDiscover;
        uint16 totalDegen;
        uint16 leftDegenToDiscover;
        uint16 leftChadFarmAttempts;
        uint16 leftDegenFarmAttempts;
    }

    //Land count record
    struct LandCount {
        uint16 total;
        uint16 left;
    }
 
    // Record  represent one farming act
    struct FarmRecord {
        uint256   creatureId;
        uint256   landId;
        uint256   harvestTime;
        uint256[] amuletsPrice1;
        uint256[] amuletsPrice2;
        Result    harvest;
        uint256   harvestId; //new NFT tokenId
        bool[3]   commonAmuletInitialHold;
    }

    // Bonus for better harvest
    struct Bonus {
        uint16 amuletHold;
        uint16 amuletBullTrend;
        uint16 inventoryHold;
    }

    uint8   constant public CREATURE_TYPE_COUNT_MAX = 20;  //how much creatures types may be used

    //Creature probubility multiplier, scaled with 100. 3.00  - 300, 3.05 - 305 etc
    // so we need additional divide on 100 in formula
    uint32  constant public CREATURE_P_MULT = 230;
    uint16  public MAX_ALL_NORMIES    = getCreatureTypeCount() * getNormieCountInType(); //subj
    uint256 constant public NFT_ID_MULTIPLIER  = 10000;     //must be set more then all Normies count
    uint256 constant public FARM_DUNG_AMOUNT   = 250e32;      //per one harvest
    uint16  constant public BONUS_POINTS_AMULET_HOLD       = 10;
    uint16  constant public BONUS_POINTS_AMULET_BULL_TREND = 90;
    
    //Common Amulet addresses
    address[3] public COMMON_AMULETS = [
        0xa0246c9032bC3A600820415aE600c6388619A14D, 
        0x87d73E916D7057945c9BcD8cdd94e42A6F47f776,
        0x126c121f99e1E211dF2e5f8De2d96Fa36647c855
    ];

    bool    public REVEAL_ENABLED  = false;
    bool    public FARMING_ENABLED = false;
    address public priceProvider;
    IEggs    public eggs;
    
    address[][CREATURE_TYPE_COUNT_MAX] public amulets; //amulets for creatures
    AddressRegistry                    public farm;
    LandCount                          public landCount;

    //common token price snapshots
    mapping(uint256 => uint256[3]) public commonAmuletPrices; 

    mapping(address => uint256) public maxAmuletBalances;

    // mapping from user to his(her) staked tools
    // Index of uint256[6] represent tool NFT  itemID
    mapping(address => uint256[6]) public userStakedTools;


    uint16 public allNormiesesLeft;
    CreaturesCount[CREATURE_TYPE_COUNT_MAX] public creaturesBorn;
    FarmRecord[]       farming;

    event Reveal(uint256 indexed _tokenId, bool _isCreature, uint8 _animalType);
    event Harvest(
        uint256 indexed _eggId, 
        address farmer, 
        uint8   result ,
        uint16  baseChance, 
        uint16  amuletHold,
        uint16  amuletBullTrend,
        uint16  inventoryHold
    );
    
    constructor (
        address _land, 
        address _creatures,
        address _inventory,
        address _bagstoken,
        address _dungtoken,
        IEggs _eggs
    )
    {
        farm.land      = _land;
        farm.creatures = _creatures;
        farm.inventory = _inventory;
        farm.bagstoken = _bagstoken;
        farm.dungtoken = _dungtoken;
        
        // Index of creaturesBorn in this initial setting  
        // must NOT exceed CREATURE_TYPE_COUNT
        for (uint i = 0; i < getCreatureTypeCount(); i++) {
            creaturesBorn[i] = CreaturesCount(
                getNormieCountInType(), // totalNormie;
                getNormieCountInType(), // leftNormie;
                getChadCountInType(),   // totalChad;
                getChadCountInType(),   // leftChadToDiscover;
                1,                      // totalDegen;
                1,                      // leftDegenToDiscover;
                getNormieCountInType(), // leftChadFarmAttempts;
                getChadCountInType());  // leftDegenFarmAttempts;
        }

        landCount        = LandCount(getMaxLands(), getMaxLands());
        allNormiesesLeft = MAX_ALL_NORMIES;
        eggs = _eggs;
    }

    /**
     * @dev Changes inventory contract
    */
    function setInventory(address _inventory) external onlyOwner {
        farm.inventory = _inventory;
    }

    function reveal(uint count) external {
        require(_isRevelEnabled(), "Please wait for reveal enabled.");
        require(count > 0, "Count must be positive");
        require(count <= 8, "Count must less than 9"); // random limit
        require(
            IERC20(farm.bagstoken).allowance(msg.sender, address(this)) >= count*1,
            "Please approve your BAGS token to this contract."
        );
        require(
            IERC20(farm.bagstoken).transferFrom(msg.sender, address(this), count*1)
        );
        uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        // random seed for 8 reveals (8x32=256)
        for (uint i = 0; i < count; i++) {
            _reveal(randomSeed);
            randomSeed = randomSeed / 0x100000000; // shift right 32 bits
        }
    }

    event Log(string mess);
    /**
     * @dev Start farming process. New NFT - Egg will minted for user 
     * @param _creatureId - NFT tokenId, caller must be owner of this token
     * @param _landId -- NFT tokenId, caller must be owner of this token
     */
    function farmDeploy(uint256 _creatureId, uint256 _landId) external {
        require(FARMING_ENABLED == true, "Chief Farmer not enable yet");
        require(ICreatures(farm.creatures).ownerOf(_creatureId) == msg.sender, 
            "Need to be Creature Owner"
        );
        require(ILand(farm.land).ownerOf(_landId) == msg.sender,
            "Need to be Land Owner"
        );
        (uint8 crType, uint8 crRarity) = ICreatures(farm.creatures).getTypeAndRarity(_creatureId);
        require((DegenFarmBase.Rarity)(crRarity) == Rarity.Normie ||
            (DegenFarmBase.Rarity)(crRarity) == Rarity.Chad,
            "Can farm only Normie and Chad");
        //Check that farming available yet
        if (crRarity == 0) {
            require(creaturesBorn[crType].leftChadToDiscover > 0, "No more chads left");
        } else {
            require(creaturesBorn[crType].leftDegenToDiscover > 0, "No more Degen left");
        }
        //1. Lets make amulet price snapshot
        //1.1. First we need creat array with properly elements count
        uint256[] memory prices1  = new uint256[](amulets[crType].length);
        uint256[] memory prices2  = new uint256[](amulets[crType].length);
        prices1 = _getExistingAmuletsPrices(amulets[crType]);
        //2.Check and save Common Amulets price(if not exist yet)
        _saveCommonAmuletPrices(block.timestamp);
        //3. Save deploy record
        farming.push(
            FarmRecord({
                creatureId:    _creatureId,
                landId:        _landId,
                harvestTime:   block.timestamp + getFarmingDuration(),
                amuletsPrice1: prices1,
                amuletsPrice2: prices2,
                harvest:       Result.Fail,
                harvestId:     0, 
                commonAmuletInitialHold: _getCommonAmuletsHoldState(msg.sender) //save initial hold state
            })
        );

        // Let's  mint Egg.
        eggs.mint(
            msg.sender,         // farmer
            farming.length - 1  // tokenId
        );
        //STAKE LAND  and Creatures!!!!
        ILand(farm.land).transferFrom(msg.sender, address(this), _landId);
        ICreatures(farm.creatures).transferFrom(msg.sender, address(this), _creatureId);
    }

    /**
     * @dev Finish farming process. Egg NFT will be  burn 
     * @param _deployId - NFT tokenId, caller must be owner of this token
     */
    function harvest(uint256 _deployId) external {

        require(eggs.ownerOf(_deployId) == msg.sender, "This is NOT YOUR EGG");
        
        FarmRecord storage f = farming[_deployId];
        require(f.harvestTime <= block.timestamp, "To early for harvest");
        //Lets Calculate Dung/CHAD-DEGEN chance
        Result farmingResult;
        Bonus memory bonus;
        //1. BaseChance
        (uint8 crType, uint8 crRarity) = ICreatures(farm.creatures).getTypeAndRarity(
            f.creatureId
        );
        uint16 baseChance;
        if  (crRarity == 0) {
            //Try farm CHAD. So if there is no CHADs any more we must return assets
            if  (creaturesBorn[crType].leftChadToDiscover == 0) {
                _endFarming(_deployId, Result.Fail);
                return;
            }
            baseChance = creaturesBorn[crType].leftChadToDiscover * 100
                /(creaturesBorn[crType].leftChadFarmAttempts);
            //Decrease appropriate farm ATTEMPTS COUNT!!!
            creaturesBorn[crType].leftChadFarmAttempts -= 1;
        } else {

            //Try farm DEGEN. So if there is no DEGENSs any more we must return assets
            if  (creaturesBorn[crType].leftDegenToDiscover == 0) {
                _endFarming(_deployId, Result.Fail);
                return;
            }
            baseChance = creaturesBorn[crType].leftDegenToDiscover * 100
                /(creaturesBorn[crType].leftDegenFarmAttempts);
            //Decrease appropriate farm ATTEMPTS COUNT!!!
            creaturesBorn[crType].leftDegenFarmAttempts -= 1;
        }
        //////////////////////////////////////////////
        //   2. Bonus for amulet token ***HOLD***
        //   3. Bonus for amulets BULLs trend
        //////////////////////////////////////////////
        bonus.amuletHold      = 0;
        bonus.amuletBullTrend = 0;
        //Check common amulets
        _saveCommonAmuletPrices(block.timestamp);
        //Get current hold stae
        for (uint8 i = 0; i < COMMON_AMULETS.length; i ++){
            if (f.commonAmuletInitialHold[i] &&  _getCommonAmuletsHoldState(msg.sender)[i]) {
                //token was hold at deploy time and now - iT IS GOOD
                //Lets check max Balance, because 
                //bonus.amuletHold = userAmuletBalance/maxAmuletBalances*BONUS_POINTS_AMULET_HOLD
                _checkAndSaveMaxAmuletPrice(COMMON_AMULETS[i]);
                bonus.amuletHold = uint16(
                    IERC20(COMMON_AMULETS[i]).balanceOf(msg.sender) * 100 
                    / maxAmuletBalances[COMMON_AMULETS[i]] * BONUS_POINTS_AMULET_HOLD / 100 //100 used for scale
                );     
                //Lets check Bull TREND
                if  (_getCommonAmuletPrices(f.harvestTime - getFarmingDuration())[i]
                        <  _getCommonAmuletPrices(block.timestamp)[i]
                    ) 
                    {
                       bonus.amuletBullTrend = BONUS_POINTS_AMULET_BULL_TREND; 
                    }
                break;
            }
        }
        //Ok,  if there is NO common amulets lets check personal
        uint256[] memory prices2    = new uint256[](amulets[crType].length);
        prices2 = _getExistingAmuletsPrices(amulets[crType]);
        if  (bonus.amuletHold != BONUS_POINTS_AMULET_HOLD) {
            for (uint8 i=0; i < f.amuletsPrice1.length; i ++){
                if (f.amuletsPrice1[i] > 0 && prices2[i] > 0){
                    //Lets check max Balance, because 
                    //bonus.amuletHold = userAmuletBalance/maxAmuletBalances*BONUS_POINTS_AMULET_HOLD
                    _checkAndSaveMaxAmuletPrice(amulets[i][crType]);
                    bonus.amuletHold = uint16(
                        IERC20(amulets[i][crType]).balanceOf(msg.sender) * 100 //100 used for scale
                        / maxAmuletBalances[amulets[i][crType]] * BONUS_POINTS_AMULET_HOLD /100
                    );
                    //Lets check Bull TREND
                    if (f.amuletsPrice1[i] < prices2[i]) {
                       bonus.amuletBullTrend = BONUS_POINTS_AMULET_BULL_TREND; 
                    }
                    break;
                }
            }
        }
        //////////////////////////////////////////////


        ////////////////////////////////////////////// 
        //4. Bonus for inventory 
        //////////////////////////////////////////////
        bonus.inventoryHold = 0;
        if (userStakedTools[msg.sender].length > 0) { 
           for (uint8 i=0; i<userStakedTools[msg.sender].length; i++) {
               if  (userStakedTools[msg.sender][i] > 0){
                   bonus.inventoryHold = bonus.inventoryHold 
                   + IInventory(farm.inventory).getToolBoost(i);
               }
           }
        }  
        //////////////////////////////////////////////

        uint16 allBonus = bonus.amuletHold 
            + bonus.amuletBullTrend 
            + bonus.inventoryHold;
        uint8 chanceOfRarityUP = uint8(
            (baseChance + allBonus) * 100 / (100 + allBonus)
        );
        uint8[] memory choiceWeight = new uint8[](2); 
        choiceWeight[0] = chanceOfRarityUP; 
        choiceWeight[1] = 100 - chanceOfRarityUP;
        uint8 choice = uint8(_getWeightedChoice(choiceWeight));

        if (choice == 0) {
            f.harvestId = (crRarity + 1) * NFT_ID_MULTIPLIER + _deployId;
            // Mint new chad/degen

            uint32 index;
            //Decrease appropriate CREATRURE COUNT
            if (crRarity + 1 == uint8(Rarity.Chad)) {
                index = creaturesBorn[crType].totalChad - creaturesBorn[crType].leftChadToDiscover + 1;
                creaturesBorn[crType].leftChadToDiscover -= 1;
                farmingResult = Result.Chad;
            } else if (crRarity + 1 == uint8(Rarity.Degen)) {
                index = creaturesBorn[crType].totalDegen - creaturesBorn[crType].leftDegenToDiscover + 1;
                creaturesBorn[crType].leftDegenToDiscover -= 1;
                farmingResult = Result.Degen;
            }

            ICreatures(farm.creatures).mint(
                msg.sender, 
                (crRarity + 1) * NFT_ID_MULTIPLIER + _deployId, // new iD
                crType, //AnimalType
                crRarity + 1,
                index // index
            );
        } else {
        //Mint new dung
            IDung(farm.dungtoken).mint(msg.sender, FARM_DUNG_AMOUNT);
            farmingResult = Result.Dung;
        }
        
        //BURN Land
        ILand(farm.land).burn(f.landId);
        _endFarming(_deployId, farmingResult);
        emit Harvest(
            _deployId, 
            msg.sender, 
            uint8(farmingResult),
            baseChance,
            bonus.amuletHold,
            bonus.amuletBullTrend,
            bonus.inventoryHold 
        );
    }

    /**
     * @dev Stake one inventory item 
     * @param _itemId - NFT tokenId, caller must be owner of this token
     */
    function stakeOneTool(uint8 _itemId) external {
        _stakeOneTool(_itemId);
    }

    /**
     * @dev UnStake one inventory item 
     * @param _itemId - NFT tokenId
     */

    function unstakeOneTool(uint8 _itemId) external {
        _unstakeOneTool(_itemId);
    }

    /////////////////////////////////////////////////////
    ////    Admin functions                       ///////
    /////////////////////////////////////////////////////
    function setOneCommonAmulet(uint8 _index, address _token) external onlyOwner {
        COMMON_AMULETS[_index] = _token;
    }

    function setAmuletForOneCreature(uint8 _index, address[] memory _tokens) external onlyOwner {
        delete amulets[_index];
        amulets[_index] = _tokens;
    }

    function setPriceProvider(address _priceProvider) external onlyOwner {
        priceProvider = _priceProvider;
    }

    function enableReveal(bool _isEnabled) external onlyOwner {
        REVEAL_ENABLED = _isEnabled;
    }

    function enableFarming(bool _isEnabled) external onlyOwner {
        FARMING_ENABLED = _isEnabled;
    }

    ////////////////////////////////////////
    /// Proxy for NFT Operators mamnage   //
    ////////////////////////////////////////
    function  addOperator(address _contract, address newOperator) external onlyOwner {
        IOperatorManage(_contract).addOperator(newOperator);
    }

    function removeOperator(address _contract, address oldOperator) external onlyOwner {
        IOperatorManage(_contract).removeOperator(oldOperator);
    }
 
    function reclaimToken(address _contract, IERC20 anyTokens, address _admin) external onlyOwner {
        IOperatorManage(_contract).withdrawERC20(anyTokens, _admin);
    }
    ////////////////////////////////////////////////////////

    function getCreatureAmulets(uint8 _creatureType) external view returns (address[] memory) {
        return _getCreatureAmulets(_creatureType);
    }

    function _getCreatureAmulets(uint8 _creatureType) internal view returns (address[] memory) {
        return amulets[_creatureType];
    } 

    function getCreatureStat(uint8 _creatureType) 
        external 
        view 
        returns (
            uint16, 
            uint16, 
            uint16, 
            uint16, 
            uint16, 
            uint16,
            uint16,
            uint16 
        )
    {
        CreaturesCount storage stat = creaturesBorn[_creatureType];
        return (
            stat.totalNormie, 
            stat.leftNormie, 
            stat.totalChad, 
            stat.leftChadToDiscover, 
            stat.totalDegen, 
            stat.leftDegenToDiscover,
            stat.leftChadFarmAttempts,
            stat.leftDegenFarmAttempts
        );
    }

    function getWeightedChoice(uint8[] memory _weights) external view returns (uint8){
        return _getWeightedChoice(_weights);
    }

    function _getWeightedChoice(uint8[] memory _weights) internal view returns (uint8){
        uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        return _getWeightedChoice2(_weights, randomSeed);
    }

    function getFarmingById(uint256 _farmingId) external view returns (FarmRecord memory) {
        return farming[_farmingId];
    }

    function getCommonAmuletPrices(uint256 _timestamp) external view returns (uint256[3] memory) {
        return _getCommonAmuletPrices(_timestamp);
    }

    function getOneAmuletPrice(address _token) external view returns (uint256) {
        return _getOneAmuletPrice(_token);
    }

    
    ///////////////////////////////////////////////
    ///  Internals                          ///////                   
    ///////////////////////////////////////////////
    /**
     * @dev Save farming results in storage and mint
     * appropriate token (NFT, ERC20 or None)
    */
    function _endFarming(uint256 _deployId, Result  _res) internal {
        //TODO need refactor if EGGs will be
        FarmRecord storage f = farming[_deployId];
        f.harvest = _res;
        // unstake creature
        ICreatures(farm.creatures).transferFrom(address(this), msg.sender, f.creatureId);
        eggs.burn(_deployId); // Burn EGG

        if  (_res ==  Result.Fail) {
            //unstake land (if staked)
            if (ILand(farm.land).ownerOf(f.landId) == address(this)){
               ILand(farm.land).transferFrom(address(this), msg.sender, f.landId);
            }
            emit Harvest(
                _deployId, 
                msg.sender, 
                uint8(_res),
                0, //baseChance
                0, //bonus.amuletHold,
                0, //bonus.amuletBullTrend,
                0  //bonus.inventoryHold 
            );   
        }
    }

    function _stakeOneTool(uint8 _itemId) internal {
        require(IInventory(farm.inventory).balanceOf(msg.sender, _itemId) >= 1,
            "You must own this tool for stake!"
        );
        //Before stake  we need two checks.
        //1. Removed
        //2. Cant`t stake one tool more than one item
        require(userStakedTools[msg.sender][_itemId] == 0, "Tool is already staked");

        //stake
        IInventory(farm.inventory).safeTransferFrom(
            msg.sender, 
            address(this), 
            _itemId, 
            1, 
            bytes('0')
        );
        userStakedTools[msg.sender][_itemId] = block.timestamp;

    }

    function _unstakeOneTool(uint8 _itemId) internal {
        require(userStakedTools[msg.sender][_itemId] > 0, "This tool is not staked yet");
        require(block.timestamp - userStakedTools[msg.sender][_itemId] >= getToolUnstakeDelay(),
            "Cant unstake earlier than a week"
        );
        userStakedTools[msg.sender][_itemId] = 0;
        IInventory(farm.inventory).safeTransferFrom(
            address(this), 
            msg.sender, 
            _itemId, 
            1, 
            bytes('0')
        );

    }

    function _saveCommonAmuletPrices(uint256 _timestamp) internal {
        //Lets check if price NOT exist for this timestamp - lets save it
        if  (commonAmuletPrices[_timestamp][0] == 0) {
            for (uint8 i=0; i < COMMON_AMULETS.length; i++){
                commonAmuletPrices[_timestamp][i] = _getOneAmuletPrice(COMMON_AMULETS[i]);
            }
        }
    }

    function _checkAndSaveMaxAmuletPrice(address _amulet) internal {
        if  (IERC20(_amulet).balanceOf(msg.sender) 
                > maxAmuletBalances[_amulet]
            ) 
            {
              maxAmuletBalances[_amulet] 
              = IERC20(_amulet).balanceOf(msg.sender);
            }
    }

    function _getCommonAmuletPrices(uint256 _timestamp) internal view returns (uint256[3] memory) {
        //Lets check if price allready exist for this timestamp - just return it
        if  (commonAmuletPrices[_timestamp][0] != 0) {
            return commonAmuletPrices[_timestamp];
        }
        //If price is not exist lets get it from oracles
        uint256[3] memory res;
        for (uint8 i=0; i < COMMON_AMULETS.length; i++){
            res[i] = _getOneAmuletPrice(COMMON_AMULETS[i]);
        }
        return res;
    }

    function _getCommonAmuletsHoldState(address _farmer) internal view returns (bool[3] memory) {
        
        //If token balance =0 - set false
        bool[3] memory res;
        for (uint8 i=0; i < COMMON_AMULETS.length; i++){
            if  (IERC20(COMMON_AMULETS[i]).balanceOf(_farmer) > 0){
                res[i] = true;    
            } else {
            // Set to zero if token balance is 0   
                res[i] = false;
            }
        }
        return res;
    }

    function _getExistingAmuletsPrices(address[] memory _tokens) 
        internal 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory res = new uint256[](_tokens.length);
        for (uint8 i=0; i < _tokens.length; i++){
            if  (IERC20(_tokens[i]).balanceOf(msg.sender) > 0){
                res[i] = _getOneAmuletPrice(_tokens[i]);    
            } else {
            // Set to zero if token balance is 0   
                res[i] = 0;
            }    
        }
        return res;
    }

    function _getOneAmuletPrice(address _token) internal view returns (uint256) {
        return IAmuletPriceProvider(priceProvider).getLastPrice(_token);
    }

    function _isRevelEnabled() internal view returns (bool) {
        return REVEAL_ENABLED;
    }

    function _reveal(uint randomSeed) internal {
        require ((landCount.left + allNormiesesLeft) > 0, "Sorry, no more reveal!");
        //1. Lets choose Land OR Creature, %
        //So we have two possible results. 1 - Land, 0 - Creature.
        // sum of weights = 100, lets define weigth for Creature
        uint8[] memory choiceWeight = new uint8[](2); 
        choiceWeight[0] = uint8(
            uint32(allNormiesesLeft) * CREATURE_P_MULT         // * 100 removed due CREATURE_P_MULT 
            / (CREATURE_P_MULT * uint32(allNormiesesLeft) / 100 + uint32(landCount.left))
        ); 
        choiceWeight[1] = 100 - choiceWeight[0];
        uint8 choice = uint8(_getWeightedChoice2(choiceWeight, randomSeed));
        //Check that choice can be executed
        if (choice != 0 && landCount.left == 0) {
            //There are no more Lands. So we need change choice
            choice = 0;
        }

        if (choice == 0) { // create creature
            uint8[] memory choiceWeight0 = new uint8[](getCreatureTypeCount());
            //2. Ok, Creature will  be born. But what kind of?
            for (uint8 i = 0; i < getCreatureTypeCount(); i ++) {
                choiceWeight0[i] = uint8(creaturesBorn[i].leftNormie);
            }
            choice = uint8(_getWeightedChoice2(choiceWeight0, randomSeed / 0x10000)); // shift right 16 bits
            ICreatures(farm.creatures).mint(
                msg.sender, 
                MAX_ALL_NORMIES - allNormiesesLeft,
                choice, //AnimalType
                0,
                creaturesBorn[choice].totalNormie - creaturesBorn[choice].leftNormie + 1 // index
            );
            emit Reveal(MAX_ALL_NORMIES - allNormiesesLeft, true, choice);
            allNormiesesLeft -= 1;
            creaturesBorn[choice].leftNormie -= 1;
        } else { // create land
            ILand(farm.land).mint(
                msg.sender, 
                getMaxLands() - landCount.left
            );
            emit Reveal(getMaxLands() - landCount.left , false, 0);
            landCount.left -= 1; 
        }
    }

    function _getWeightedChoice2(uint8[] memory _weights, uint randomSeed) internal view returns (uint8){
        uint256 sum_of_weights;
        for (uint8 i = 0; i < _weights.length; i++) {
            sum_of_weights += _weights[i];
        }
        uint256 rnd = randomSeed % sum_of_weights;
        for (uint8 i = 0; i < _weights.length; i++) {
            if (rnd < _weights[i]) {
                return i;
            }
            rnd -= _weights[i];
        }
        return 0;
    }

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));  
    }    

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256,uint256,bytes)"));  
    }

    function getCreatureTypeCount() virtual internal view returns (uint16);

    function getFarmingDuration() virtual internal view returns (uint);

    function getToolUnstakeDelay() virtual internal view returns (uint);

    function getNormieCountInType() virtual internal view returns (uint16);

    function getChadCountInType() virtual internal view returns (uint16);

    function getMaxLands() virtual internal view returns (uint16);

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        return eggs.getUsersTokens(_owner);
    }
}
