// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.0;
import "./AggregatorInterface.sol";
import "./DataStorage.sol";
import "./ExternalAccessible.sol";
import "./SafeMath.sol";

contract wXEQ is ExternalAccessible {

    using SafeMath for *;

    struct mintXEQStruct {
        address addr;
        uint amount;
        string xeqAddress;
    }

    struct TxStorage {
        string hash;
        uint amountMinted;
    }

    string public _name;
    string public _symbol;
    address public contractCreator;
    uint8 public _decimals;
    DataStorage dataStorage;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (address d, address _masterContract) {
        dataStorage = DataStorage(d);
        _decimals = 18;
        _name = "Wrapped Equilibria";
        _symbol = "wXEQ";
        contractCreator = msg.sender;
        masterContract = _masterContract;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return dataStorage.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return dataStorage.balanceOf(_owner);
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return dataStorage.allowance(_owner, _spender);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= dataStorage.balanceOf(msg.sender));
        require(to != address(0));
        uint256 bal = dataStorage.balanceOf(msg.sender);
        dataStorage.updateBalance(msg.sender, bal.sub(value));
        assert(dataStorage.balanceOf(msg.sender).add(value) == bal);
        bal = dataStorage.balanceOf(to);
        dataStorage.updateBalance(to, bal.add(value));
        assert(dataStorage.balanceOf(to).sub(value) == bal);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        require(dataStorage.balanceOf(msg.sender) >= value);
        dataStorage.updateAllowed(msg.sender, spender, value);
        assert(allowance(msg.sender, spender) == value);
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function decreaseAllowance(address spender,uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        uint256 allow = allowance(msg.sender, spender);
        dataStorage.updateAllowed(msg.sender, spender, allow.sub(subtractedValue));
        assert(allow.sub(subtractedValue) == allowance(msg.sender, spender));
        emit Approval(msg.sender, spender, allowance(msg.sender, spender));
        return true;
    }

    function transferFrom(address _from,address to,uint256 value) public returns (bool){
        require(to != address(0));
        require(value <= dataStorage.balanceOf(_from));
        require(value <= allowance(_from, msg.sender));

        dataStorage.updateBalance(_from, dataStorage.balanceOf(_from).sub(value));
        dataStorage.updateBalance(to, dataStorage.balanceOf(to).add(value));
        dataStorage.updateAllowed(_from, msg.sender, allowance(_from, msg.sender).sub(value));
        emit Transfer(_from, to, value);
        return true;
    }

    function increaseAllowance(address spender,uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        uint256 allow = allowance(msg.sender, spender);
        require(allow.add(addedValue) <= dataStorage.balanceOf(msg.sender));
        dataStorage.updateAllowed(msg.sender, spender, allow.add(addedValue));
        assert(allow.add(addedValue) == allowance(msg.sender, spender));
        emit Approval(msg.sender, spender, allowance(msg.sender, spender));
        return true;
    }

    function _burn(address account, uint256 amount) public hasAccess {
        require(amount <= dataStorage.balanceOf(account));
        uint256 supply = dataStorage.totalSupply();
        dataStorage.updateSupply(supply.sub(amount));
        assert(supply == dataStorage.totalSupply().add(amount));
        uint256 bal = dataStorage.balanceOf(account);
        dataStorage.updateBalance(account, bal.sub(amount));
        assert(bal == dataStorage.balanceOf(account).add(amount));
        emit Transfer(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 amount) public {
        require(amount <= allowance(account, msg.sender));
        uint256 allow = allowance(account, msg.sender);
        dataStorage.updateAllowed(account, msg.sender, allow.sub(amount));
        assert(allow.sub(amount) == allowance(account, msg.sender));
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) public hasAccess {
        uint256 supp = dataStorage.totalSupply();
        dataStorage.updateSupply(supp.add(amount));
        assert(dataStorage.totalSupply().sub(amount) == supp);
        uint256 bal = dataStorage.balanceOf(account);
        dataStorage.updateBalance(account, bal.add(amount));
        assert(dataStorage.balanceOf(account).sub(amount) == bal);
        emit Transfer(msg.sender, account, amount);
    }
}
