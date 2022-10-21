pragma solidity 0.4.24;
import "./StorageV0.sol";
import "./IColor.sol";
import "./IPixel.sol";

contract StorageV1 is StorageV0 {

    //pixel color(round=> pixel=> color)
    mapping (uint => mapping (uint => uint)) public pixelToColorForRound;

    //old pixel color(round=> pixel=> color)
    mapping (uint => mapping (uint => uint)) public pixelToOldColorForRound;

    // (round => color => pixel amount)
    mapping (uint => mapping (uint => uint)) public colorToPaintedPixelsAmountForRound;

    //color bank for round (round => color bank)
    mapping (uint => uint) public colorBankForRound;

    //color bank for  color for round (round => color => color bank)
    mapping (uint => mapping (uint => uint)) public colorBankToColorForRound;

    //time bank for round (round => time bank)
    mapping (uint => uint) public timeBankForRound;

    // (round => timestamp)
    mapping (uint => uint) public lastPaintTimeForRound;

    // (round => adress)
    mapping (uint => address) public lastPainterForRound;

    // (round => pixel)
    mapping (uint => uint) public lastPaintedPixelForRound;

    // (round => color)
    mapping (uint => uint) public winnerColorForRound;

    // (round => color => paints amount)
    mapping (uint => mapping (uint => uint)) public colorToTotalPaintsForCBIteration;

    // (round => adress)
    mapping (uint => address) public winnerOfRound;

    //bank drawn in round (round => drawn bank) (1 = time bank, 2 = color bank)
    mapping (uint => uint) public winnerBankForRound;

    // (round => pixel => timestamp)
    mapping (uint => mapping (uint => uint)) public pixelToPaintTimeForRound;


    // number of paints for paint price limit
    uint public priceLimitPaints;

    // is paint function call – for paint price limit logic
    bool public isPaintCall;


    // (round => paints number)
    mapping (uint => uint) public totalPaintsForRound;

    // (round => address => paints number)
    mapping (uint => mapping (address => uint)) public userPaintsForRound;


    // total cashback for round (round => total cashback)
    mapping (uint => uint) public totalCashBackForRound;

    // max cashback since the beginning of the round (round => cashback per paint)
    mapping (uint => uint) public maxCashBackPerPaintForRound;

    // cashback per painter for round in time of painter's last paint (round => painter's address => cashback per paint)
    mapping (uint => mapping (address => uint)) public cashBackPerPaintForRound;

    // unwithdrawn cashback + remaining money from paints (address => cashback per painter)
    mapping (address => uint) public cashBackCalculated;

    // last cashback calculation round in cashBackCalculated (address => round)
    mapping (address => uint) public cashBackCalculationRound;


    mapping (uint => mapping (uint => uint)) public paintGenToAmountForColor;
    mapping (uint => mapping (uint => uint)) public paintGenToStartTimeForColor;
    mapping (uint => mapping (uint => uint)) public paintGenToEndTimeForColor;
    mapping (uint => mapping (uint => bool)) public paintGenStartedForColor;
    mapping (uint => uint) public currentPaintGenForColor;
    mapping (uint => uint) public callPriceForColor;
    mapping (uint => uint) public nextCallPriceForColor;


    mapping (uint => mapping (address => uint)) public moneySpentByUserForColor;
    mapping (address => uint) public moneySpentByUser;


    mapping (uint => mapping (address => bool)) public hasPaintDiscountForColor;
    mapping (address => bool) public hasPaintDiscount;
    mapping (uint => mapping (address => uint)) public usersPaintDiscountForColor;  //in percent
    mapping (address => uint) public usersPaintDiscount;  //in percent



    mapping (address => uint) public registrationTimeForUser;
    mapping (address => bool) public isRegisteredUser;


    mapping (address => bool) public hasRefLink;
    mapping (address => address) public referralToReferrer;
    mapping (address => address[]) public referrerToReferrals;
    mapping (address => bool) public hasReferrer;
    mapping (address => string) public userToRefLink;
    mapping (bytes32 => address) public refLinkToUser;
    mapping (bytes32 => bool) public refLinkExists;
    mapping (address => uint) public newUserToCounter;


    mapping (address => string) public addressToUsername;
    mapping (string => bool) internal usernameExists;  // not public – string accessor


    mapping(address => bool)  public luckyPotBankWinner;
    uint public luckyPotBank;


    uint public uniqueUsersCount;

    uint public maxPaintsInPool;

    uint public currentRound;

    //time bank iteration
    uint public tbIteration;

   //color bank iteration
    uint public cbIteration;


    uint public paintsCounter;
    mapping (uint => uint) public paintsCounterForColor;


    // (counter => user)
    mapping (uint => address) public counterToPainter;

    // (color => counter => user)
    mapping (uint => mapping (uint => address)) public counterToPainterForColor;

    mapping (address => uint) public lastPlayedRound;


    // For dividends distribution
    mapping (address => uint) public pendingWithdrawals;

    // (adress => time)
    mapping (address => uint) public addressToLastWithdrawalTime;


    address public founders = 0xe04f921cf3d6c882C0FAa79d0810a50B1101e2D4;


    bool public isGamePaused;

    mapping(address => bool) public isAdmin;

    Color public colorInstance;
    Pixel public pixelInstance;

    uint public totalColorsNumber; // 8
    uint public totalPixelsNumber; //225 in V1


    mapping (address => uint) public lastPaintTimeOfUser;
    mapping (uint => mapping (address => uint)) public lastPaintTimeOfUserForColor;


    mapping (uint => uint) public usersCounterForRound;
    mapping (uint => mapping (address => bool)) public isUserCountedForRound;


    // ***** Events *****

    event ColorBankWithdrawn(uint indexed round, uint indexed cbIteration, address indexed winnerOfRound, uint prize);
    event TimeBankWithdrawn(uint indexed round, uint indexed tbIteration, address indexed winnerOfRound, uint prize);
    event Paint(uint indexed pixelId, uint colorId, address indexed painter, uint indexed round, uint timestamp);
    event CallPriceUpdated(uint indexed newCallPrice);
    event EtherWithdrawn(uint balance, uint colorBank, uint timeBank, uint timestamp);
    event LuckyPotDrawn(uint pixelId, address indexed winnerOfLuckyPot, uint prize);
    event CashBackWithdrawn(uint indexed round, address indexed withdrawer, uint cashback);
    event DividendsWithdrawn(address indexed withdrawer, uint withdrawalAmount);
    event UsernameCreated(address indexed user, string username);
}
