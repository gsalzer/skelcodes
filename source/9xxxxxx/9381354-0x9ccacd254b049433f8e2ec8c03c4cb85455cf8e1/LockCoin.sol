pragma solidity ^0.5.0;

import './ERC20.sol';
import "./SafeMath.sol";

contract LockCoin is ERC20 {
    using SafeMath for uint256;

    string public constant name = "ET";
    string public constant symbol = "ET";
    uint public constant decimals = 18;
    uint public constant INITIAL_SUPPLY = 8800000000 * 10 ** decimals;
    byte private constant SCT = 0x05;

    string internal constant INVALID_TOKEN_VALUES = 'Invalid token values';

    bool private _gobal_locked = false;

    address private _owner;

    uint256 private _testTick = 0;

    bool private _mode = true;

    mapping(address => bytes32[]) public lockReason;

    event logEvent(address to, uint256 value, byte tp, string msg);

    struct coinToken {
        bool        exists;
        byte        lockType;                  // 락타입 1(기간없이 락), 2 시간 락, 3 => 기간별 일정 퍼센트, 4 => 10% 증가, 5 => 10% 증가 (락금액에 대해서)
        uint        creationTime;              // 생성시간
        uint        holdTime;                  // 락 타임
        uint256     balance;                   // 락 걸린 토큰
        uint256     dayUsage;                  // 사용량
        uint256     piece;                     // 퍼센트 량

    }

    mapping(address => coinToken[]) private _coinTokenList;

    constructor() public {
        _owner = msg.sender;
        _mint(msg.sender, INITIAL_SUPPLY);
    }


    /**
     * @dev See {IERC20-transfer}. 토큰 전송 제한
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "ERC20: transfer from the zero address");
        require( _gobal_locked == false, "ERC20: Token cannot be sent.");

        withdrawAll();

        return super.transfer(to, value);
    }


    function withdrawAll() public {

        coinToken[] storage lockers = _coinTokenList[_msgSender()];

        for (uint i = 0; i < lockers.length; i++) {

            if (lockers[i].lockType == 0x02) {
                if (lockers[i].exists == true && lockers[i].holdTime <= _getTime()) {
                    balanceAdd( _msgSender(), lockers[i].dayUsage );
                    lockers[i].dayUsage = 0;
                    emit logEvent( _msgSender(), 0, lockers[i].lockType, "coinUnlock");
                    delete lockers[i];
                }
            }
            else if (lockers[i].lockType == 0x05) {

                for(uint c=0; c<12; c++) {

                    if (lockers[i].exists == true && lockers[i].holdTime <= _getTime()) {
                        if ( lockers[i].dayUsage > 0 ) {
                            //lockers[i].balance -= lockers[i].dayUsage;
                            balanceAdd( _msgSender(), lockers[i].dayUsage );
                            lockers[i].dayUsage = 0;
                        }

                        lockers[i].holdTime += (60 * 60 * 24 * 30);
                        if ( lockers[i].balance > 0 ) {
                            if ( lockers[i].balance >= lockers[i].piece ) {
                                lockers[i].balance -= lockers[i].piece;
                                lockers[i].dayUsage += lockers[i].piece;
                            } else {
                                lockers[i].dayUsage = lockers[i].balance;
                                lockers[i].balance = 0;
                            }
                        }
                        if ( (lockers[i].balance + lockers[i].dayUsage) <= 0) {
                            emit logEvent( _msgSender(), 0, lockers[i].lockType, "coinUnlock");
                            delete lockers[i];
                        }
                    } else {
                        break;
                    }
                }
            }
        }

        // delete check
        for (uint c = 0; c < lockers.length; c++) {
            if ( lockers[c].exists == false ) {
                lockers[c] = lockers[lockers.length - 1];
                delete lockers[lockers.length - 1];
                lockers.length--;
                break;
            }
        }
    }


    /**
     * @dev See {IERC20-transferFrom}. 토큰 전송 제한
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer from the zero address");

        return super.transferFrom(sender, recipient, amount);
    }

    function balanceOf(address account) public view returns (uint256) {

        coinToken[] memory lockers = _coinTokenList[account];
        uint256 lockTotal = 0;
        for (uint i = 0; i < lockers.length; i++) {
            if ( lockers[i].lockType == 0x05 ) {
                lockTotal += lockers[i].dayUsage;
                lockTotal += lockers[i].balance;
            }
        }

        return super.balanceOf(account) + lockTotal;
    }


    /**
     * @dev 유닉스 타임정보
     *
     */
    function _getTime() private view returns (uint256) {
        if ( _mode == true )
            return now;
        return _testTick;
    }

    /**
     * @dev 테스트 할 때 사용함 setMode( false ) 작동함
     *
     * Requirements:
     * - `val` uinx time 정보
     */
    function setTime(uint256 val) public returns (bool) {
        require(_owner == msg.sender, "ERC20: You do not have permission.");
        _testTick = val;
        return true;
    }

    /**
     * @dev 테스트 할 때 사용함
     *
     * Requirements:
     * - `val` uinx time 정보
     */
    function setMode(bool value) public returns (bool) {
        require(_owner == msg.sender, "ERC20: You do not have permission.");
        _mode = value;
        return _mode;
    }

    /**
     * @dev 테스트 할 때 사용함
     *
     * 운용 모드 or 테스트 모드
     */
    function getMode() public view returns (bool) {
        require(_owner == msg.sender, "ERC20: You do not have permission.");
        return _mode;
    }

    /**
     * @dev 전체 락을 건다.
     * 소유자도 전소을 못 할 수도 있다.
     *
     * Requirements:
     * - `locked` ture : 락설정, false : 락 취소
     */
    function setGobalLock( bool locked ) public returns (bool) {
        require(_owner == msg.sender, "ERC20: You do not have permission.");
        _gobal_locked = locked;
        return true;
    }

    /**
     * @dev 전체 락 상태 정보
     *
     * true : 전체 락모드
     * false : 락모드 해제 상태
     */
    function getGobalLock() public view returns (bool) {
        return _gobal_locked;
    }


    function coinLock( address to, byte lockType, uint closeTime, uint256 value, uint percent ) public returns (bool) {
        require(to != address(0), "ERC20: transfer from the zero address");
        require(_owner == msg.sender, "ERC20: You do not have permission.");

        uint256 balances = super.balanceOf(to);
        require( value <= balances, INVALID_TOKEN_VALUES );

        if ( lockType == 0x01 ) {

        }
        else if ( lockType == 0x01 ) {  // 무한정

            coinToken memory b;
            b.lockType      = lockType;
            b.creationTime  = now;
            b.holdTime      = 0;
            b.balance       = 0;
            b.dayUsage      = value;
            b.piece         = 0;
            b.exists        = true;
            balanceSub(to, value);
            _coinTokenList[to].push(b);
            emit logEvent( to, value, lockType, "coinlock");

        } else if ( lockType == 0x02 ) { // 기간

            balanceSub(to, value);

            coinToken memory b;
            b.lockType      = lockType;
            b.creationTime  = now;
            b.holdTime      = closeTime;
            b.balance       = 0;
            b.dayUsage      = value;
            b.piece         = 0;
            b.exists        = true;
            _coinTokenList[to].push(b);
            emit logEvent( to, value, lockType, "coinlock");

        } else if ( lockType == 0x05 ) {

            balanceSub(to, value);

            if ( percent == 0 ) percent = 10;
            coinToken memory b;
            b.lockType      = lockType;
            b.creationTime  = now;
            b.holdTime      = closeTime;
            //b.balance       = value;
            b.piece         = value * uint256(percent) / 100;

            if ( value >= b.piece ) {
                b.balance = value - b.piece;
                b.dayUsage = b.piece;
            }
            b.exists        = true;
            _coinTokenList[to].push(b);
            emit logEvent( to, value, lockType, "coinlock");
        }

        return true;
    }

    function getLockerDetails(address owner, uint index) external view returns(bool exists, byte lockType, uint creationTime, uint holdTime, uint256 balance, uint256 dayUsage) {

        if ( index < _coinTokenList[owner].length ) {
            coinToken memory locker = _coinTokenList[owner][index];
            lockType = locker.lockType;
            creationTime = locker.creationTime;
            holdTime = locker.holdTime;
            balance = locker.balance;
            dayUsage = locker.dayUsage;
            exists = locker.exists;
        }
    }

    function setUnLockers(address owner, uint index) external returns(uint) {

        coinToken[] storage lockers = _coinTokenList[owner];
        if ( index < lockers.length ) {
            uint256 v = lockers[index].balance + lockers[index].dayUsage;
            emit logEvent( owner, v, lockers[index].lockType, "coinUnlock");

            if ( v > 0 )
                balanceAdd( owner, v );

            lockers[index] = lockers[lockers.length - 1];
            delete lockers[lockers.length - 1];
            lockers.length--;
        }
        return lockers.length;
    }

    function getNumLockers(address owner) external view returns(uint) {
        return _coinTokenList[owner].length;
    }


    /**
     * @dev 계정 토큰을 전송 할 수 있는 량
     *
     * Requirements:
     * - `to` 계정 정보
     */
    function possible( address to ) public view returns(uint256) {
        require(to != address(0), "ERC20: transfer from the zero address");

        coinToken[] memory lockers = _coinTokenList[to];

        uint256 dayUsage = 0;

        for (uint i = 0; i < lockers.length; i++) {
            if (lockers[i].lockType == 0x05) {
                for(uint c=0; c<12; c++) {
                    if (lockers[i].exists == true && lockers[i].holdTime <= _getTime()) {
                        if ( lockers[i].dayUsage > 0 ) {
                            dayUsage += lockers[i].dayUsage;
                            lockers[i].dayUsage = 0;
                        }
                        lockers[i].holdTime += (60 * 60 * 24 * 30);
                        if ( lockers[i].balance > 0 ) {
                            if ( lockers[i].balance >= lockers[i].piece ) {
                                lockers[i].balance -= lockers[i].piece;
                                lockers[i].dayUsage += lockers[i].piece;
                            } else {
                                lockers[i].dayUsage = lockers[i].balance;
                                lockers[i].balance = 0;
                            }
                        }
                    } else {
                        break;
                    }
                }
            }
        }

        return super.balanceOf(to) + dayUsage;
    }

    function getSCT() public view returns(byte) {
        return SCT;
    }
}

