pragma solidity =0.5.16;
pragma experimental ABIEncoderV2;


/**
 *    ______                           ____                    __               ______
 *   / ____/____ _ ____ ___   ___     / __ \ ___   ____ _ ____/ /___   _____   / ____/____   _____
 *  / / __ / __ `// __ `__ \ / _ \   / /_/ // _ \ / __ `// __  // _ \ / ___/  / /_   / __ \ / ___/
 * / /_/ // /_/ // / / / / //  __/  / _, _//  __// /_/ // /_/ //  __// /     / __/  / /_/ // /
 * \____/ \__,_//_/ /_/ /_/ \___/  /_/ |_| \___/ \__,_/ \__,_/ \___//_/     /_/     \____//_/
 *    _____               _____                          __   __     _               ___                            __     __
 *   / ___/ ____ _ __  __/ ___/ ____   ____ ___   ___   / /_ / /_   (_)____   ____ _|__ \   _      __ ____   _____ / /____/ /
 *   \__ \ / __ `// / / /\__ \ / __ \ / __ `__ \ / _ \ / __// __ \ / // __ \ / __ `/__/ /  | | /| / // __ \ / ___// // __  /
 *  ___/ // /_/ // /_/ /___/ // /_/ // / / / / //  __// /_ / / / // // / / // /_/ // __/ _ | |/ |/ // /_/ // /   / // /_/ /
 * /____/ \__,_/ \__, //____/ \____//_/ /_/ /_/ \___/ \__//_/ /_//_//_/ /_/ \__, //____/(_)|__/|__/ \____//_/   /_/ \__,_/
 *              /____/                                                     /____/
 */


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0)
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @dev Interface of GAME
 */
interface IGame {
    function block2timestamp(uint256 blockNumber) external view returns (uint256);
    function serial2player(uint256 serial) external view returns (address payable);

    function getStatus() external view
        returns (
            uint256 timer,
            uint256 roundCounter,
            uint256 playerCounter,
            uint256 messageCounter,
            uint256 cookieCounter,

            uint256 cookieFund,
            uint256 winnerFund,

            uint256 surpriseIssued,
            uint256 bonusIssued,
            uint256 cookieIssued,
            uint256 shareholderIssued
        );

    function getRound(uint256 serial) external view
        returns (
            uint256 openedBlock,
            uint256 closingBlock,
            uint256 closedTimestamp,
            uint256 openingWinnerFund,
            uint256 closingWinnerFund,
            address payable opener,
            uint256 openerBonus
        );

    function getRoundWinners(uint256 serial) external view
        returns (
            uint8[10] memory serials,
            uint256[10] memory winnersMessageSerials,
            uint256[10] memory winnersWeis
        );

    function getPlayer(address account) external view
        returns (
            uint256 serial,
            bytes memory name,
            bytes memory adviserName,
            address payable adviser,
            uint256 messageCounter,
            uint256 cookieCounter,
            uint256 followerCounter,
            uint256 followerMessageCounter,
            uint256 followerCookieCounter,
            uint256 bonusWeis,
            uint256 surpriseWeis
        );

    function getPlayerPrime(address account) external view
        returns (
            bytes memory playerName,
            uint256 pinnedMessageSerial,
            uint8 topPlayerPosition,
            uint8 shareholderPosition,
            uint256 shareholderStakingWeis,
            uint256 shareholderProfitWeis,
            uint256 shareholderFirstBlockNumber
        );

    function getMessage(uint256 serial) external view
        returns (
            address payable account,
            bytes memory name,
            bytes memory text,
            uint256 blockNumber
        );

    function getCookie(uint256 serial) external view
        returns (
            address payable player,
            address payable adviser,
            bytes memory playerName,
            bytes memory adviserName,
            uint256 playerWeis,
            uint256 adviserWeis,

            uint256 messageSerial,
            bytes memory text,
            uint256 blockNumber
        );

    function getPlayerDisplay(address account) external view
        returns (
            uint256 messageCounter,
            uint256 pinnedMessageSerial,

            uint256 messageSerial,
            bytes memory text,
            uint256 blockNumber
        );

    function getShareholders() external view
        returns (
            uint256 shareholderBidCounter,
            address payable[6] memory accounts
        );

    function getTopPlayers() external view
        returns (address payable[20] memory accounts);

    function getShareholderBid(uint256 serial) external view
        returns (
            address payable account,
            bytes memory name,
            uint256 stakingBefore,
            uint256 stakingAfter,
            uint256 blockNumber
        );
}


/**
 * @dev Structs of game.
 */
library GameLib {
    struct Message {
        uint256 serial;
        address account;
        bytes name;
        bytes text;
        uint256 blockNumber;
    }

    struct Cookie {
        uint256 serial;

        address payable player;
        address payable adviser;
        bytes playerName;
        bytes adviserName;
        uint256 playerWeis;
        uint256 adviserWeis;

        uint256 messageSerial;
        bytes text;
        uint256 blockNumber;
    }

    struct Round {
        uint256 openedBlock;
        uint256 closingBlock;
        uint256 closedTimestamp;
        uint256 openingWinnerFund;
        uint256 closingWinnerFund;
        address payable opener;
        uint256 openerBonus;
    }
}


/**
 * @dev Structs of player.
 */
library PlayerLib {
    struct Player {
        uint256 serial;

        bytes name;
        bytes adviserName;
        address payable adviser;
        uint256 messageCounter;
        uint256 cookieCounter;
        uint256 followerCounter;
        uint256 followerMessageCounter;
        uint256 followerCookieCounter;
        uint256 bonusWeis;
        uint256 surpriseWeis;
    }
}

/**
 * @title GameReaderA contract.
 */
contract ReaderA {
    using SafeMath for uint256;
    using PlayerLib for PlayerLib.Player;

    IGame private _game;

    uint8 constant SM_PAGE = 10;
    uint8 constant LG_PAGE = 20;
    uint8 constant SHAREHOLDER_MAX_POSITION = 6;
    uint8 constant TOP_PLAYER_MAX_POSITION = 20;
    uint8 constant WINNERS_PER_ROUND = 10;


    /**
     * @dev Constructor
     */
    constructor ()
        public
    {
        _game = IGame(0x1234567B172f040f45D7e924C0a7d088016191A6);
    }

    function () external payable {
        revert("Cannot deposit");
    }

    function game()
        public
        view
        returns (address)
    {
        return address(_game);
    }

    /**
     * @dev Returns status.
     */
    function status()
        public
        view
        returns (
            uint256 timer,
            uint256 roundCounter,
            uint256 playerCounter,
            uint256 messageCounter,
            uint256 cookieCounter
        )
    {
        (
            timer,
            roundCounter,
            playerCounter,
            messageCounter,
            cookieCounter,

            , // uint256 cookieFund,
            , // uint256 winnerFund,

            , // uint256 surpriseIssued,
            , // uint256 bonusIssued,
            , // uint256 cookieIssued,
            // uint256 shareholderIssued
        )
        = _game.getStatus();
    }

    /**
     * @dev Returns funds and bonus data.
     */
    function prizes()
        public
        view
        returns (
            uint256 cookieFund,
            uint256 winnerFund,

            uint256 surpriseIssued,
            uint256 bonusIssued,
            uint256 cookieIssued,
            uint256 shareholderIssued
        )
    {
        (
            , // uint256 timer,
            , // uint256 roundCounter,
            , // uint256 playerCounter,
            , // uint256 messageCounter,
            , // uint256 cookieCounter,

            cookieFund,
            winnerFund,

            surpriseIssued,
            bonusIssued,
            cookieIssued,
            shareholderIssued
        )
        = _game.getStatus();
    }

    /**
     * @dev Returns round info of `roundSerial`.
     *
     * roundSerial > 0: history
     * roundSerial == 0: latest
     */
    function round(uint256 roundSerial)
        public
        view
        returns (
            uint256 serial,

            uint256 openedBlock,
            uint256 openedTimestamp,
            uint256 closingBlock,
            uint256 closingTimestamp,
            uint256 closedTimestamp,
            uint256 openingWinnerFund,
            uint256 closingWinnerFund,
            address opener,
            bytes memory openerName,
            uint256 openerBonusWeis
        )
    {
        (
            , // uint256 timer,
            uint256 roundCounter,
            , // uint256 playerCounter,
            , // uint256 messageCounter,
            , // uint256 cookieCounter,

            , // uint256 cookieFund,
            , // uint256 winnerFund,

            , // uint256 surpriseIssued,
            , // uint256 bonusIssued,
            , // uint256 cookieIssued,
            // uint256 shareholderIssued
        )
        = _game.getStatus();

        if (roundSerial == 0)
        {
            roundSerial = roundCounter;
        }

        if (roundSerial <= roundCounter)
        {
            GameLib.Round memory theRound = _round(roundSerial);
            PlayerLib.Player memory thePlayer = _player(theRound.opener);

            serial = roundSerial;
            openedBlock = theRound.openedBlock;
            closingBlock = theRound.closingBlock;
            closedTimestamp = theRound.closedTimestamp;
            openingWinnerFund = theRound.openingWinnerFund;
            closingWinnerFund = theRound.closingWinnerFund;

            opener = theRound.opener;
            openerName = thePlayer.name;
            openerBonusWeis = theRound.openerBonus;

            openedTimestamp = _game.block2timestamp(theRound.openedBlock);
            closingTimestamp = _game.block2timestamp(theRound.closingBlock);
        }
    }

    /**
     * @dev Returns round winners @ `roundSerial`.
     */
    function roundWinners(uint256 roundSerial)
        public
        view
        returns (
            uint8[WINNERS_PER_ROUND] memory winnerSerials,
            uint256[WINNERS_PER_ROUND] memory messageSerials,
            address[WINNERS_PER_ROUND] memory players,
            bytes[WINNERS_PER_ROUND] memory playerNames,
            uint256[WINNERS_PER_ROUND] memory bonusWeis,
            bytes[WINNERS_PER_ROUND] memory texts,
            uint256[WINNERS_PER_ROUND] memory blockNumbers,
            uint256[WINNERS_PER_ROUND] memory timestamps
        )
    {
        GameLib.Round memory theRound = _round(roundSerial);

        if (theRound.closingBlock > 0)
        {
            (
                winnerSerials,
                messageSerials,
                bonusWeis
            )
            = _game.getRoundWinners(roundSerial);

            for (uint8 i = 0; i < WINNERS_PER_ROUND; i++)
            {
                GameLib.Message memory message = _message(messageSerials[i]);
                PlayerLib.Player memory thePlayer = _player(message.account);

                players[i] = message.account;
                playerNames[i] = thePlayer.name;
                texts[i] = message.text;
                blockNumbers[i] = message.blockNumber;
                timestamps[i] = _game.block2timestamp(message.blockNumber);
            }
        }
    }

    /**
     * @dev Returns a message info @ global `serial`.
     */
    function message(uint256 serial)
        public
        view
        returns (
            address account,
            bytes memory name,
            bytes memory text,
            uint256 blockNumber,
            uint256 timestamp
        )
    {
        GameLib.Message memory theMessage = _message(serial);

        account = theMessage.account;
        name = theMessage.name;
        text = theMessage.text;
        blockNumber = theMessage.blockNumber;
        timestamp = _game.block2timestamp(blockNumber);
    }

    /**
     * @dev Returns game messages, `till` a serial.
     *
     * till > 0: history
     * till == 0: latest
     */
    function messages(uint256 till)
        public
        view
        returns (
            uint256[LG_PAGE] memory serials,
            address[LG_PAGE] memory accounts,
            bytes[LG_PAGE] memory names,
            bytes[LG_PAGE] memory texts,
            uint256[LG_PAGE] memory blockNumbers,
            uint256[LG_PAGE] memory timestamps
        )
    {
        (
            , // uint256 timer,
            , // uint256 roundCounter,
            , // uint256 playerCounter,
            uint256 messageCounter,
            , // uint256 cookieCounter,

            , // uint256 cookieFund,
            , // uint256 winnerFund,

            , // uint256 surpriseIssued,
            , // uint256 bonusIssued,
            , // uint256 cookieIssued,
            // uint256 shareholderIssued
        )
        = _game.getStatus();

        if (till == 0)
        {
            till = messageCounter;
        }

        if (till <= messageCounter)
        {
            for (uint256 i = 0; i < LG_PAGE; i++)
            {
                uint256 serial = till.sub(i);
                if (serial < 1)
                {
                    break;
                }

                serials[i] = serial;

                GameLib.Message memory theMessage = _message(serial);
                accounts[i] = theMessage.account;

                PlayerLib.Player memory thePlayer = _player(theMessage.account);
                names[i] = thePlayer.name;

                texts[i] = theMessage.text;
                blockNumbers[i] = theMessage.blockNumber;
                timestamps[i] = _game.block2timestamp(theMessage.blockNumber);
            }
        }
    }

    /**
     * @dev Returns game cookies, `till` a serial.
     *
     * till > 0: history
     * till == 0: latest
     */
    function cookies(uint256 till)
        public
        view
        returns (
            uint256[LG_PAGE] memory serials,

            address[LG_PAGE] memory players,
            address[LG_PAGE] memory advisers,
            bytes[LG_PAGE] memory playerNames,
            bytes[LG_PAGE] memory adviserNames,
            uint256[LG_PAGE] memory playerWeis,
            uint256[LG_PAGE] memory adviserWeis,

            uint256[LG_PAGE] memory messageSerials,
            bytes[LG_PAGE] memory texts,
            uint256[LG_PAGE] memory blockNumbers,
            uint256[LG_PAGE] memory timestamps
        )
    {
        if (till == 0)
        {

            (
                , // uint256 timer,
                , // uint256 roundCounter,
                , // uint256 playerCounter,
                , // uint256 messageCounter,
                till, // uint256 cookieCounter,

                , // uint256 cookieFund,
                , // uint256 winnerFund,

                , // uint256 surpriseIssued,
                , // uint256 bonusIssued,
                , // uint256 cookieIssued,
                // uint256 shareholderIssued
            )
            = _game.getStatus();
        }

        for (uint256 i = 0; i < LG_PAGE; i++)
        {
            uint256 serial = till.sub(i);
            if (serial < 1)
            {
                break;
            }

            serials[i] = serial;

            GameLib.Cookie memory cookie = _cookie(serial);

            players[i] = cookie.player;
            advisers[i] = cookie.adviser;
            playerNames[i] = cookie.playerName;
            adviserNames[i] = cookie.adviserName;
            playerWeis[i] = cookie.playerWeis;
            adviserWeis[i] = cookie.adviserWeis;

            messageSerials[i] = cookie.messageSerial;
            texts[i] = cookie.text;
            blockNumbers[i] = cookie.blockNumber;
            timestamps[i] = _game.block2timestamp(cookie.blockNumber);
        }
    }


    /**
     * @dev Returns top-players.
     */
    function topPlayers()
        public
        view
        returns (
            address payable[TOP_PLAYER_MAX_POSITION] memory accounts,
            bytes[TOP_PLAYER_MAX_POSITION] memory names,
            uint256[TOP_PLAYER_MAX_POSITION] memory messageSerials,
            uint256[TOP_PLAYER_MAX_POSITION] memory messageCounters,
            bytes[TOP_PLAYER_MAX_POSITION] memory texts,
            uint256[TOP_PLAYER_MAX_POSITION] memory blockNumbers,
            uint256[TOP_PLAYER_MAX_POSITION] memory timestamps
        )
    {
        accounts = _game.getTopPlayers();

        for (uint8 i = 0; i < TOP_PLAYER_MAX_POSITION; i++)
        {
            if (accounts[i] != address(0))
            {
                names[i] = _player(accounts[i]).name;

                (
                    messageCounters[i],
                    , // uint256 pinnedMessageSerial,
                    messageSerials[i],
                    texts[i],
                    blockNumbers[i]
                )
                = _game.getPlayerDisplay(accounts[i]);

                timestamps[i] = _game.block2timestamp(blockNumbers[i]);

            }
        }
    }

    /**
     * @dev Returns shareholders.
     */
    function shareholders()
        public
        view
        returns (
            uint256 bidCounter,

            address payable[SHAREHOLDER_MAX_POSITION] memory accounts,
            bytes[SHAREHOLDER_MAX_POSITION] memory names,
            uint256[SHAREHOLDER_MAX_POSITION] memory stakingWeis,
            uint256[SHAREHOLDER_MAX_POSITION] memory profitWeis,
            uint256[SHAREHOLDER_MAX_POSITION] memory firstBlockNumbers,
            uint256[SHAREHOLDER_MAX_POSITION] memory firstTimestamps,

            uint256[SHAREHOLDER_MAX_POSITION] memory messageCounters,
            uint256[SHAREHOLDER_MAX_POSITION] memory messageSerials,
            bytes[SHAREHOLDER_MAX_POSITION] memory texts,
            uint256[SHAREHOLDER_MAX_POSITION] memory blockNumbers,
            uint256[SHAREHOLDER_MAX_POSITION] memory timestamps
        )
    {
        (bidCounter, accounts) = _game.getShareholders();

        for (uint8 i = 0; i < SHAREHOLDER_MAX_POSITION; i++)
        {
            (
                names[i], // bytes memory playerName,
                , // uint256 pinnedMessageSerial,
                , // uint8 topPlayerPosition,
                , // uint8 shareholderPosition,
                stakingWeis[i], // uint256 shareholderStakingWeis,
                profitWeis[i], // uint256 shareholderProfitWeis,
                firstBlockNumbers[i] // uint256 shareholderFirstBlockNumber
            )
            = _game.getPlayerPrime(accounts[i]);

            firstTimestamps[i] = _game.block2timestamp(firstBlockNumbers[i]);

            (
                messageCounters[i],
                , // uint256 pinnedMessageSerial,
                messageSerials[i],
                texts[i],
                blockNumbers[i]
            )
            = _game.getPlayerDisplay(accounts[i]);

            timestamps[i] = _game.block2timestamp(blockNumbers[i]);
        }
    }

    /**
     * @dev Returns shareholder bid logs, `till` a serial.
     *
     * till > 0: history
     * till == 0: latest
     */
    function shareholderBids(uint256 till)
        public
        view
        returns (
            uint256[SM_PAGE] memory serials,

            address[SM_PAGE] memory accounts,
            bytes[SM_PAGE] memory names,
            uint256[SM_PAGE] memory beforeWeis,
            uint256[SM_PAGE] memory afterWeis,
            uint256[SM_PAGE] memory blockNumbers,
            uint256[SM_PAGE] memory timestamps
        )
    {
        (uint256 bidCounter,) = _game.getShareholders();

        if (till == 0)
        {
            till = bidCounter;
        }

        if (till <= bidCounter)
        {
            for (uint256 i = 0; i < SM_PAGE; i++)
            {
                uint256 serial = till.sub(i);
                if (serial < 1)
                {
                    break;
                }

                uint256 blockNumber;
                serials[i] = serial;

                (
                    accounts[i],
                    names[i],
                    beforeWeis[i],
                    afterWeis[i],
                    blockNumber
                )
                = _game.getShareholderBid(serial);

                blockNumbers[i] = blockNumber;
                timestamps[i] = _game.block2timestamp(blockNumber);
            }
        }
    }


    /**
     * --------- --------- --------- --------- --------- --------- --------- --------- --------- --------- ---------
     *     ____         _                __           ______                     __   _
     *    / __ \ _____ (_)_   __ ____ _ / /_ ___     / ____/__  __ ____   _____ / /_ (_)____   ____   _____
     *   / /_/ // ___// /| | / // __ `// __// _ \   / /_   / / / // __ \ / ___// __// // __ \ / __ \ / ___/
     *  / ____// /   / / | |/ // /_/ // /_ /  __/  / __/  / /_/ // / / // /__ / /_ / // /_/ // / / /(__  )
     * /_/    /_/   /_/  |___/ \__,_/ \__/ \___/  /_/     \__,_//_/ /_/ \___/ \__//_/ \____//_/ /_//____/
     *
     * --------- --------- --------- --------- --------- --------- --------- --------- --------- --------- ---------
     */

    /**
     * @dev Returns round {GameLib.Round} @ `serial`.
     */
    function _round(uint256 serial)
        private
        view
        returns (GameLib.Round memory)
    {
        (
            uint256 openedBlock,
            uint256 closingBlock,
            uint256 closedTimestamp,
            uint256 openingWinnerFund,
            uint256 closingWinnerFund,
            address payable opener,
            uint256 openerBonus
        )
        = _game.getRound(serial);

        return GameLib.Round(
            openedBlock,
            closingBlock,
            closedTimestamp,
            openingWinnerFund,
            closingWinnerFund,
            opener,
            openerBonus
        );
    }

    /**
     * @dev Returns player {PlayerLib.Player} of `account`.
     */
    function _player(address account)
        private
        view
        returns (PlayerLib.Player memory)
    {
        (
            uint256 serial,
            bytes memory name,
            bytes memory adviserName,
            address payable adviser,
            uint256 messageCounter,
            uint256 cookieCounter,
            uint256 followerCounter,
            uint256 followerMessageCounter,
            uint256 followerCookieCounter,
            uint256 bonusWeis,
            uint256 surpriseWeis
        )
        = _game.getPlayer(account);

        return PlayerLib.Player(
            serial,
            name,
            adviserName,
            adviser,
            messageCounter,
            cookieCounter,
            followerCounter,
            followerMessageCounter,
            followerCookieCounter,
            bonusWeis,
            surpriseWeis
        );
    }

    /**
     * @dev Returns message {GameLib.Message} @ `serial`.
     */
    function _message(uint256 serial)
        private
        view
        returns (GameLib.Message memory)
    {
        (
            address payable account,
            bytes memory name,
            bytes memory text,
            uint256 blockNumber
        )
        = _game.getMessage(serial);

        return GameLib.Message(serial, account, name, text, blockNumber);
    }


    /**
     * @dev Returns cookie {GameLib.Cookie} @ `serial`.
     */
    function _cookie(uint256 serial)
        private
        view
        returns (GameLib.Cookie memory)
    {
        (
            address payable playerAccount,
            address payable adviserAccount,
            bytes memory playerName,
            bytes memory adviserName,
            uint256 playerWeis,
            uint256 adviserWeis,

            uint256 messageSerial,
            bytes memory text,
            uint256 blockNumber
        )
        = _game.getCookie(serial);

        return GameLib.Cookie(serial, playerAccount, adviserAccount, playerName, adviserName, playerWeis, adviserWeis, messageSerial, text, blockNumber);
    }
}
