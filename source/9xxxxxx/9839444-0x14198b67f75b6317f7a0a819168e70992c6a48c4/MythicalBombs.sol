pragma solidity ^0.5.16;


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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ERC20 {
    function wagered(uint256 amount) external returns (bool);
    function mint(address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface GMWrapper {
    // function getGameMasterAddress() external returns (address);
    function mint(uint256 amount, uint8 game) external returns (bool success);
}

contract MythicalBombs is Ownable {
  uint nonce;

  struct Bomb {
    uint256 price;
    uint8 tickets;
    uint256 balance;
    uint8 chance;
    uint8 lucky_number;
  }

  uint256 stat_wagered;
  uint stat_tickles;
  uint stat_explosions;

  ERC20 Myth;
  GMWrapper GM;

  Bomb[] _bombs;

  event TickleBomb(address indexed sender, uint bomb, uint tickets);
  event BombExploded(address indexed sender, uint bomb, uint256 won, uint8 tries);

  constructor() public {
    Myth = ERC20(0x79Ef5b79dC1E6B99fA9d896779E94aE659B494F2);
    GM = GMWrapper(0xa3f110D318fC0C41ea62724631DEA460Aa627428);

    _bombs.push(Bomb(25 * (10 ** 9), 0, 0, 100, 11));
    _bombs.push(Bomb(100 * (10 ** 9), 0, 0, 42, 8));
    _bombs.push(Bomb(1000 * (10 ** 9), 0, 0, 100, 42));

    nonce = 42;
  }

  function () external payable {}

  function getStats() public view returns (uint256 wagered, uint tickles, uint explosions) {
    return (stat_wagered, stat_tickles, stat_explosions);
  }

  function getBomb(uint8 bomb) public view returns (uint bomb_id, uint balance, uint tickets, uint price, uint chance, uint lucky_number) {
    return (
      bomb,
      _bombs[bomb].balance,
      _bombs[bomb].tickets,
      _bombs[bomb].price,
      _bombs[bomb].chance,
      _bombs[bomb].lucky_number
    );
  }

  function tickleBomb(uint8 bomb, uint tokens) public returns (bool success){
    Myth.transferFrom(msg.sender, address(this), tokens);
    Myth.wagered(tokens);
    // Myth.burnFrom(msg.sender, tokens);

    uint256 perc1 = tokens / 100;
    _bombs[bomb].balance = SafeMath.add(_bombs[bomb].balance, perc1*99);

    GM.mint(perc1, 0);
    // Myth.mint(GM.getGameMasterAddress(), perc1);

    uint tickets = uint( tokens / _bombs[bomb].price );

    emit TickleBomb(msg.sender, bomb, tickets);

    stat_wagered += tokens;
    stat_tickles += tickets;

    for(uint i = 0; i < tickets; i++){
      incrementNonce();
      if(random(_bombs[bomb].chance, nonce, i) == _bombs[bomb].lucky_number){
        Myth.mint(msg.sender, _bombs[bomb].balance);
        emit BombExploded(msg.sender, bomb, _bombs[bomb].balance, _bombs[bomb].tickets + 1);
        _bombs[bomb].tickets = 0;
        _bombs[bomb].balance = 0;
        stat_explosions += 1;
        break;
      } else {
        _bombs[bomb].tickets += 1;
      }
    }
    return true;
  }

  function updateBomb(uint8 bomb, uint256 price, uint8 chance, uint8 lucky_number) public onlyOwner {
    _bombs[bomb].price = price;
    _bombs[bomb].chance = chance;
    _bombs[bomb].lucky_number = lucky_number;
  }

  function updateSettings(address _token, address _gm) public onlyOwner {
    Myth = ERC20(_token);
    GM = GMWrapper(_gm);
  }

  function incrementNonce() private {
    nonce += 1;
    if(nonce >= 9999999999999429999){ nonce = 0; }
  }

  function random(uint max, uint second, uint ticket) private view returns (uint256) {
    return uint256(keccak256(abi.encode(block.timestamp, block.difficulty, second, ticket, blockhash(block.number-1))))%(max+1);
  }
}
