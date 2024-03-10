pragma solidity ^0.5.10;

import "./Ownable.sol";
import "./DistributedStorage.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./GasPump.sol";
import "./IERC20.sol";
import "./Pigpen.sol";

contract Porkchop is Ownable, GasPump, IERC20 {
    using DistributedStorage for bytes32;
    using SafeMath for uint256;

    // Pork events
    event Winner(address indexed _addr, uint256 _value);

    // Managment events
    event SetName(string _prev, string _new);
    event SetExtraGas(uint256 _prev, uint256 _new);
    event SetPigpen(address _prev, address _new);
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);

    uint256 public totalSupply;

    bytes32 private constant BALANCE_KEY = keccak256("balance");

    // game
    uint256 public constant FEE = 100;

    // metadata
    string public name = "Porkchop";
    string public constant symbol = "CHOP";
    uint8 public constant decimals = 18;

    // fee whitelist
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;

    // pigpen
    Pigpen public pigpen;

    // internal
    uint256 public extraGas;
    bool inited;

    function init(
        address _to,
        uint256 _amount
    ) external {
        // Only init once
        assert(!inited);
        inited = true;

        // Sanity checks
        assert(totalSupply == 0);
        assert(address(pigpen) == address(0));

        // Create Pigpen
        pigpen = new Pigpen();
        emit SetPigpen(address(0), address(pigpen));

        // Init contract variables and mint
        // entire token balance
        extraGas = 15;
        emit SetExtraGas(0, extraGas);
        emit Transfer(address(0), _to, _amount);
        _setBalance(_to, _amount);
        totalSupply = _amount;
    }

    ///
    // Storage access functions
    ///

    // Getters

    function _toKey(address a) internal pure returns (bytes32) {
        return bytes32(uint256(a));
    }

    function _balanceOf(address _addr) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(BALANCE_KEY));
    }

    function _allowance(address _addr, address _spender) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("allowance", _spender))));
    }

    function _nonce(address _addr, uint256 _cat) internal view returns (uint256) {
        return uint256(_toKey(_addr).read(keccak256(abi.encodePacked("nonce", _cat))));
    }

    // Setters

    function _setAllowance(address _addr, address _spender, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("allowance", _spender)), bytes32(_value));
    }

    function _setNonce(address _addr, uint256 _cat, uint256 _value) internal {
        _toKey(_addr).write(keccak256(abi.encodePacked("nonce", _cat)), bytes32(_value));
    }

    function _setBalance(address _addr, uint256 _balance) internal {
        _toKey(_addr).write(BALANCE_KEY, bytes32(_balance));
        pigpen.update(_addr, _balance);
    }

    ///
    // Internal methods
    ///

    function _isWhitelisted(address _from, address _to) internal view returns (bool) {
        return whitelistFrom[_from]||whitelistTo[_to];
    }

    function _random(address _s1, uint256 _s2, uint256 _s3, uint256 _max) internal pure returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_s1, _s2, _s3)));
        return rand % (_max + 1);
    }

    function _pickWinner(address _from, uint256 _value) internal returns (address winner) {
        // Get order of magnitude of the tx
        uint256 magnitude = Math.orderOfMagnitude(_value);
        // Pull nonce for a given order of magnitude
        uint256 nonce = _nonce(_from, magnitude);
        _setNonce(_from, magnitude, nonce + 1);
        // pick entry from pigpen
        winner = pigpen.addressAt(_random(_from, nonce, magnitude, pigpen.size() - 1));
    }

    function _transferFrom(address _operator, address _from, address _to, uint256 _value, bool _payFee) internal {
        // If transfer amount is zero
        // emit event and stop execution
        if (_value == 0) {
            emit Transfer(_from, _to, 0);
            return;
        }

        // Load sender balance
        uint256 balanceFrom = _balanceOf(_from);
        require(balanceFrom >= _value, "balance not enough");

        // Check if operator is sender
        if (_from != _operator) {
            // If not, validate allowance
            uint256 allowanceFrom = _allowance(_from, _operator);
            // If allowance is not 2 ** 256 - 1, consume allowance
            if (allowanceFrom != uint(-1)) {
                // Check allowance and save new one
                require(allowanceFrom >= _value, "allowance not enough");
                _setAllowance(_from, _operator, allowanceFrom.sub(_value));
            }
        }

        // Calculate receiver balance
        // initial receive is full value
        uint256 receive = _value;
        uint256 burn = 0;
        uint256 chop = 0;

        // Change sender balance
        _setBalance(_from, balanceFrom.sub(_value));

        // If the transaction is not whitelisted
        // or if sender requested to pay the fee
        // calculate fees
        if (_payFee || !_isWhitelisted(_from, _to)) {
            // Fee is the same for BURN and CHOP
            // If we are sending value one
            // give priority to BURN
            burn = _value.divRound(FEE);
            chop = _value == 1 ? 0 : burn;

            // Subtract fees from receiver amount
            receive = receive.sub(burn.add(chop));

            // Burn tokens
            totalSupply = totalSupply.sub(burn);
            emit Transfer(_from, address(0), burn);

            // Porkchop tokens
            // Pick winner pseudo-randomly
            address winner = _pickWinner(_from, _value);
            // Transfer balance to winner
            _setBalance(winner, _balanceOf(winner).add(chop));
            emit Winner(winner, chop);
            emit Transfer(_from, winner, chop);
        }

        // Sanity checks
        // no tokens where created
        assert(burn.add(chop).add(receive) == _value);

        // Add tokens to receiver
        _setBalance(_to, _balanceOf(_to).add(receive));
        emit Transfer(_from, _to, receive);
    }


/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmy/-```:hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMmysydMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmy-`-:::::/ dMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMo`.::.-odMMMMMMMMMMMMMmmmmmmmmNMMMNo`.:/--::..o /MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMN:`::.-::-.:ymMMNdys+:.............+.`::.-/+/o..+ /MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMs ::.+/:.-::..+:----:::::::::::::::::/-.:+:::o..o /MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMM-`+.-o:/+-.-/::::--.....-----------.....////:+../.-MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMM `+.:+::++...-.-:://+ooooossoooosooooo+///:/+:..:: MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMM- +.-o//:--:/+ooossssoooooooooooooooooosssooo+/:/- mMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMs ::.:::+oosssoooooossssssssssssssssssooooooosssso..hMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMs .o/+ossooooosssoo++//:::------:::://+ooosssooooss-`hMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMo`-ssssooossoo+/:--....................-:---:/+oossos:`yMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMh`-ssooosso+:-......................-::/:-......--:+oss-`mMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMd.-soosoo/-..........................----:::-.........-/o..hMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMN-`ssso/-:::----......-:://////:-......./yhdhyo-.........-+-./ymMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMo +o/-....---::-....-///:::::/:://-....-hddddddy-.........:ys+:-/sdNMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMm -+-....:+so+-.....-o:+s:::::yy::/+....-hddddddy-..........ssssso/-:+symMMMMMMMMMMMM
MMMMMMMMMMMMMMMo +-....ohddddh/....+/:ys:::::/o/::o.....:oyhhyo:.........../ysssssyso+.`yMMMMMMMMMMM
MMMMMMMNMMMMMMM/`+....:dddddddy....:+:::::::::::/+-........--..............-yssssssssy.`NMMMMMMMMMMM
MMMMMMMMMMMMMMM../....-ydddddh/.....-////:::////-...........................ssssssssso +MMMMMMMMMMMM
MMMMMMMMMMMMMMM`-/.....-/ooo/-.........--:::-..............................-+`:sssssy- NMMMMMMMMMMMM
MMMMMMMMMMMMMMM/./........................................................./y- `/ssss +MMMMMMMMMMMMM
MMMMMMMMMMMMMMM/`+........................................................-ysy:  `/s: mMMMMMMMMMMMMM
MMMMMMMMMMMMMMMh /:......................................................:ssssy+``.``/MMMMMMMMMMMMMM
MMMMMMMMMMMMMMMM:`+-...................................................-oysssssyo..yMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMN-`/-................................................://yssssssssy: /mMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMN+ :/-...........................................:::.` +yssssssssy+`.dMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMN: `/+:....................................-:::-``/sM.`ssssssssssss- sMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMo`/::::////:--....................--::::-:o:.----`-+md.-ysssssyso+:`.yMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMh /:......:/`.-::::::+::/:::+::::/:/+/.`.:-`     `-:.`sy /yso+:..:/shNMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMN:`/-.....:-       ./-``::` -/-.-::-` .:-`  `....`  -:`:s/:-:+sdNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMm+`-::--:/      `::`    ./` `/+-` .--.  `:::---+.   ./ oMNNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMmo-`.-/---...:yho:.    `:-  -::-.`    /-.....-/    :..dMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNmhho:``-/-`./shhy+:.` .:. `::`     /-......+    /`.dMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMdo..-:::`    .:+yhhys+///` `:-`   `::--..:/`.-:.`yMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMmy-..--`  `-:.     `.-/oyhhdhysooy+::::/+osshyo..:odMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNh+..--`       `.:-`     `/ohdhdo+yysyyyhhyyyyyyys`:NMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMm:.-/+.            `--..` `+hs:sdy.`-:-``-/:-`````:.`MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMy +-.-/-              `.--..-` /++-   .--.``--.`  -- MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMh ::.../-             `--``.---...``    `.--.`.-:-:: MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMN/`/:..-+      ````..---:---.```....-------:/:---::: MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMm-`--::/------...---:/oyo+:--.----.              `/ MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMNho++//////+osyyddNMMMMMMMmhyo+:`:-             .: MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo -:            :- MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh /:            /`:MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN`-//-`         :- yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd -:.-/-``    .:.`yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM:`-/-.-:::/::.`/mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNy-`.:::::-`-sNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNs+/-/ohNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/
    ///
    // Managment
    ///

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }

    function setName(string calldata _name) external onlyOwner {
        emit SetName(name, _name);
        name = _name;
    }

    function setExtraGas(uint256 _gas) external onlyOwner {
        emit SetExtraGas(extraGas, _gas);
        extraGas = _gas;
    }

    function setPigpen(Pigpen _pigpen) external onlyOwner {
        emit SetPigpen(address(pigpen), address(_pigpen));
        pigpen = _pigpen;
    }

    /////
    // Pigpen methods
    /////

    function topSize() external view returns (uint256) {
        return pigpen.topSize();
    }

    function pigpenSize() external view returns (uint256) {
        return pigpen.size();
    }

    function pigpenEntry(uint256 _i) external view returns (address, uint256) {
        return pigpen.entry(_i);
    }

    function pigpenTop() external view returns (address, uint256) {
        return pigpen.top();
    }

    function pigpenIndex(address _addr) external view returns (uint256) {
        return pigpen.indexOf(_addr);
    }

    function getNonce(address _addr, uint256 _cat) external view returns (uint256) {
        return _nonce(_addr, _cat);
    }

    /////
    // ERC20
    /////

    function balanceOf(address _addr) external view returns (uint256) {
        return _balanceOf(_addr);
    }

    function allowance(address _addr, address _spender) external view returns (uint256) {
        return _allowance(_addr, _spender);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        emit Approval(msg.sender, _spender, _value);
        _setAllowance(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, false);
        return true;
    }

    function transferWithFee(address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, msg.sender, _to, _value, true);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, false);
        return true;
    }

    function transferFromWithFee(address _from, address _to, uint256 _value) external requestGas(extraGas) returns (bool) {
        _transferFrom(msg.sender, _from, _to, _value, true);
        return true;
    }
}

