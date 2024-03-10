pragma solidity ^0.8.0;

/*
       .-"-.            .-"-.            .-"-.           .-"-.
     _/_-.-_\_        _/.-.-.\_        _/.-.-.\_       _/.-.-.\_
    / __} {__ \      /|( o o )|\      ( ( o o ) )     ( ( o o ) )
   / //  "  \\ \    | //  "  \\ |      |/  "  \|       |/  "  \|
  / / \'---'/ \ \  / / \'---'/ \ \      \'/^\'/         \ .-. /
  \ \_/`"""`\_/ /  \ \_/`"""`\_/ /      /`\ /`\         /`"""`\
   \           /    \           /      /  /|\  \       /       \

-={ see no evil }={ hear no evil }={ speak no evil }={ have no fun }=-

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// Interface for our erc20 token
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract Game is Ownable, IERC721Receiver, IERC1155Receiver, ReentrancyGuard {
    address payable public daves =
        payable(address(0x4B5922ABf25858d012d12bb1184e5d3d0B6D6BE4));
    address payable public dao =
        payable(address(0x6fBa46974b2b1bEfefA034e236A32e1f10C5A148));

    using EnumerableSet for EnumerableSet.UintSet;
    mapping(address => EnumerableSet.UintSet) private _player;

    uint256 public playerId = 1;
    uint256 public playersAlive = 0;

    bool public gameEnded;

    mapping(uint256 => uint256) public timeWenDed; //time player is going to die
    mapping(uint256 => uint256) public timeWenBorn; //time player is going to die

    mapping(uint256 => uint256) public attackTodDecrease; //time to decrease from current tod
    mapping(uint256 => uint256) public attackPrice;
    mapping(uint256 => uint256) public attackGives;

    mapping(address => uint256) public tokensToClaim; //keep track of how many tokens a user can claim to save gas
    mapping(address => uint256) public lastTimeClaimed; //when was last claimed

    uint256 public longestLiving;
    uint256 public longestLivingId;
    address public longestLivingOwner;

    uint256 public tokenBurnt;
    uint256 public timeStarted;

    IERC20 public TOKEN;
    IERC20 public MUSE;

    struct Player {
        address nft;
        uint256 nftId;
        address owner;
        bool isErc1155;
    }

    mapping(uint256 => Player) players;

    event ClaimedRewards(address who, uint256 amount);
    event NewPlayer(address who, uint256 id);
    event Kill(address killer, uint256 opponentId);
    event Attak(address who, uint256 opponentId, uint256 attackId);
    event BuyPowerUp(uint256 to, uint256 amount);

    constructor(address _token, address _muse) {
        TOKEN = IERC20(_token);
        MUSE = IERC20(_muse);
        gameEnded = false;
        timeStarted = block.timestamp;
    }

    modifier isOwner(uint256 _playerId) {
        Player memory player = players[_playerId];
        require(player.owner == msg.sender, "!forbidden");
        _;
    }

    // Helpers to get pets by users
    function balanceOf(address _owner) public view returns (uint256) {
        return _player[_owner].length();
    }

    function playersOfAddressByIndex(address _owner, uint256 index)
        public
        view
        returns (uint256)
    {
        return _player[_owner].at(index);
    }

    // time remaining for death
    function timeUntilDeath(uint256 _playerId) public view returns (uint256) {
        if (block.timestamp >= timeWenDed[_playerId]) {
            return 0;
        } else {
            return timeWenDed[_playerId] - block.timestamp;
        }
    }

    // score goes up every second basically
    function getScore(uint256 _id) public view returns (uint256) {
        return block.timestamp - timeWenBorn[_id];
    }

    function getEarnings(address _user) public view returns (uint256) {
        uint256 amount = tokensToClaim[_user];

        uint256 amtOfPets = balanceOf(_user);

        uint256 sinceLastTimeClaimed =
            ((block.timestamp - lastTimeClaimed[_user]) / 1 minutes) *
                4791666666666667 * // 0,2875 tokens per hour. 6.9 tokens per day.
                amtOfPets;

        return amount + sinceLastTimeClaimed;
    }

    // check if pet alive
    function isAlive(uint256 _playerId) public view returns (bool) {
        return timeUntilDeath(_playerId) > 0;
    }

    function getInfo(uint256 _id)
        public
        view
        returns (
            uint256 _playerId,
            bool _isAlive,
            uint256 _score,
            uint256 _expectedReward,
            uint256 _timeUntilDeath,
            uint256 _timeBorn,
            address _owner,
            address _nftOrigin,
            uint256 _nftId,
            uint256 _timeOfDeath
        )
    {
        Player memory player = players[_id];

        _playerId = _id;
        _isAlive = isAlive(_id);
        _score = getScore(_id);
        _expectedReward = getEarnings(player.owner);
        _timeUntilDeath = timeUntilDeath(_id);
        _timeBorn = timeWenBorn[_id];
        _owner = player.owner;
        _nftOrigin = player.nft;
        _nftId = player.nftId;
        _timeOfDeath = timeWenDed[_id];
    }

    /*
        This functions returns the amount of TOD in minutes added for x token burned depending on the curve
        https://www.desmos.com/calculator/g6wvwk85id
    */
    function getAmountOfTOD(uint256 _tokenAmount)
        public
        view
        returns (uint256)
    {
        uint256 price_per_token =
            (10000000000) / sqrt(((tokenBurnt / (10**12)) + 800000000) / 200);
        uint256 result = (_tokenAmount * price_per_token);
        result = ((result * 1 hours) / 10**24);
        return result;
    }

    function register(
        address _nft,
        uint256 _nftId,
        bool _is1155
    ) external nonReentrant {
        require(!gameEnded, "ended");
        claimTokens(); //we claim any owned tokens before
        // Maybe block registration after a few days? or make price increase for later regstration?
        if (!_is1155) {
            IERC721(_nft).safeTransferFrom(msg.sender, address(this), _nftId);
        } else {
            IERC1155(_nft).safeTransferFrom(
                msg.sender,
                address(this),
                _nftId,
                1,
                "0x0"
            );
        }
        Player storage player = players[playerId];
        player.nft = _nft;
        player.owner = msg.sender;
        player.nftId = _nftId;
        player.isErc1155 = _is1155;
        _player[msg.sender].add(playerId);
        timeWenDed[playerId] = block.timestamp + 3 days;
        timeWenBorn[playerId] = block.timestamp;
        TOKEN.burnFrom(msg.sender, 90 * 1 ether); //burn 40 royal to join and get 3 days.

        emit NewPlayer(msg.sender, playerId);

        playersAlive++;
        playerId++;
    }

    function buyPowerUp(uint256 _id, uint256 _amount) public {
        require(isAlive(_id), "!alive");
        require(_amount >= 1 * 10**17); //min 0.1 token

        TOKEN.burnFrom(msg.sender, _amount);
        timeWenDed[_id] += getAmountOfTOD(_amount);
        tokenBurnt += _amount;

        emit BuyPowerUp(_id, _amount);
    }

    function attackPlayer(uint256 _opponent, uint256 _attackId)
        external
        payable
    {
        require(isAlive(_opponent), "!alive");
        require(msg.value >= attackPrice[_attackId], "!money");

        require(balanceOf(msg.sender) >= 1 || playersAlive == 1, "!pets");

        uint256 timeToDecrease = attackTodDecrease[_attackId];

        //can't kil someone with attacks + leave 8 hours to sleep, etc
        require(timeUntilDeath(_opponent) > timeToDecrease + 6 hours, "!kill");

        tokensToClaim[msg.sender] += attackGives[_attackId];

        timeWenDed[_opponent] -= timeToDecrease;

        emit Attak(msg.sender, _opponent, _attackId);
    }

    // user can claim tokens earned at any time and reset his tokens to 0
    function claimTokens() public {
        if (lastTimeClaimed[msg.sender] == 0) {
            lastTimeClaimed[msg.sender] = block.timestamp;
        }

        uint256 amount = getEarnings(msg.sender);
        tokensToClaim[msg.sender] = 0;
        lastTimeClaimed[msg.sender] = block.timestamp;

        if (amount > 0) TOKEN.mint(msg.sender, amount);

        emit ClaimedRewards(msg.sender, amount);
    }

    function kill(uint256 _opponentId) public nonReentrant {
        require(balanceOf(msg.sender) >= 1 || playersAlive <= 5, "!pets");

        require(!isAlive(_opponentId), "alive");
        Player memory oppoonent = players[_opponentId];
        emit Kill(msg.sender, _opponentId);

        if (!oppoonent.isErc1155) {
            IERC721(oppoonent.nft).safeTransferFrom(
                address(this),
                oppoonent.owner,
                oppoonent.nftId
            );
        } else {
            IERC1155(oppoonent.nft).safeTransferFrom(
                address(this),
                oppoonent.owner,
                oppoonent.nftId,
                1,
                "0x0"
            );
        }

        //  total time lived
        uint256 timeLived = block.timestamp - timeWenBorn[_opponentId];

        // we record longest living user to know who wins at the end.
        if (timeLived > longestLiving) {
            longestLiving = timeLived;
            longestLivingId = _opponentId;
            longestLivingOwner = oppoonent.owner;
        }
        // we remove this player
        _player[oppoonent.owner].remove(_opponentId);
        delete players[_opponentId]; //we remove the player struct

        // give 10 token for killing.
        TOKEN.mint(msg.sender, 50 * 10**18);
        playersAlive--;
    }

    // attack and rug pulls all eth if you hold over 69% of the supply.
    function rugPull() public {
        require(
            TOKEN.balanceOf(msg.sender) >= (TOKEN.totalSupply() * 69) / 100 &&
                TOKEN.totalSupply() > 100000 * 10**18 &&
                playersAlive >= 15,
            "Can't rugpull"
        );
        address payable playerAddress = payable(msg.sender);

        uint256 ethbal = address(this).balance;
        uint256 distribution = (ethbal * 10) / 100;

        if (MUSE.balanceOf(address(this)) > 0) {
            MUSE.transferFrom(
                address(this),
                msg.sender,
                MUSE.balanceOf(address(this))
            );
        }

        daves.transfer(distribution); //10% for daves
        dao.transfer(distribution); //10% for dao
        playerAddress.transfer(address(this).balance); //don't kill ocntract because players still need to withdraw nfts
    }

    function claimPrize() public {
        require(playersAlive == 0, "game is not finished"); //when no pets the game can end.

        gameEnded = true;

        // send wins//
        address payable playerAddress = payable(longestLivingOwner);

        uint256 ethbal = address(this).balance;
        uint256 distribution = (ethbal * 10) / 100;

        if (MUSE.balanceOf(address(this)) > 0) {
            MUSE.transferFrom(
                address(this),
                longestLivingOwner,
                MUSE.balanceOf(address(this))
            );
        }

        daves.transfer(distribution); //10% for daves
        dao.transfer(distribution); //10% for dao
        selfdestruct(playerAddress); // kill contract and send all remaining balance to winner
    }

    function startGame(bool start) external onlyOwner {
        gameEnded = start;
        timeStarted = block.timestamp;
    }

    function addAttack(
        uint256 _id,
        uint256 _attack,
        uint256 _price,
        uint256 _tokensToGive
    ) external onlyOwner {
        attackTodDecrease[_id] = _attack;
        attackPrice[_id] = _price;
        attackGives[_id] = _tokensToGive;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    // From UniswapV2 Math library:
    // https://github.com/Uniswap/uniswap-v2-core/blob/v1.0.1/contracts/libraries/Math.sol
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {
        return (true);
    }
}

