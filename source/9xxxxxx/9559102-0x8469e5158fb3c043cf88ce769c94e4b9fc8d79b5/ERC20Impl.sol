pragma solidity ^0.4.24;

import "ERC20Proxy.sol";
import "ERC20Store.sol";
import "ERC20Authorization.sol";
import "LockRequestable.sol";

contract ERC20Impl is ERC20Authorization, LockRequestable {

    struct PendingTransfer{
        address sender;
        address from;
        address to;
        uint value;
    }

    mapping (bytes32=>PendingTransfer) pendingTransferMap;

    ERC20Proxy public erc20Proxy;
    ERC20Store public erc20Store;

    event TransferRequest(bytes32 lockId, address _sender, address _from, address _to, uint _amount);

    constructor(
        address _erc20Proxy, 
        address _erc20Store, 
        address _proxy
    ) 
        public 
        ERC20Authorization(_proxy) 
        LockRequestable()
    {
        erc20Proxy = ERC20Proxy(_erc20Proxy);
        erc20Store = ERC20Store(_erc20Store);
    }

    modifier onlyProxy {
        require(msg.sender == address(erc20Proxy), "Only ERC20Proxy can call");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return erc20Store.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return erc20Store.getBalance(_owner);
    }

    function balanceOfLock(address _owner) public view returns (uint256[] lockBalanceTimestamps, uint256[] lockBalanceValues) {
        return erc20Store.getAllLockBalances(_owner);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return erc20Store.allowed(_owner, _spender);
    }

    function approveWithSender(
        address _sender, 
        address _spender, 
        uint256 _value
    ) 
        public 
        whenNotPaused
        onlyProxy 
        returns (bool)
    {
        require(_spender != address(0), "_spender can not be 0");
        erc20Store.setAllowance(_sender, _spender, _value);
        erc20Proxy.emitApproval(_sender, _spender, _value);
        return true;
    }

    function increaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _addedValue
    )
        public 
        whenNotPaused
        onlyProxy 
        returns (bool success)
    {
        require(_spender != address(0), "_spender can not be 0");
        uint256 currentAllowance = erc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance + _addedValue;

        require(newAllowance >= currentAllowance, "newAllowance should greater equal then currentAllowance");

        erc20Store.setAllowance(_sender, _spender, newAllowance);
        erc20Proxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

    function decreaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _subtractedValue
    )
        public
        whenNotPaused 
        onlyProxy 
        returns (bool success)
    {
        require(_spender != address(0), "_spender can not be 0");
        uint256 currentAllowance = erc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance - _subtractedValue;

        require(newAllowance <= currentAllowance, "newAllowance should greater equal then currentAllowance");

        erc20Store.setAllowance(_sender, _spender, newAllowance);
        erc20Proxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

    function transferFromWithSender(
        address _sender,
        address _from,
        address _to,
        uint256 _value
    )
        public 
        whenNotPaused
        onlyProxy 
        onlyTxCheck(_from, _to, _value) 
        returns (bool)
    {
        require(_to != address(0), "_to can not be 0");

        erc20Store.adjustLockBalance(_from);
        uint256 balanceOfFrom = erc20Store.balances(_from);
        require(_value <= balanceOfFrom, "_value should less equal balanceOfFrom");

        uint256 senderAllowance = erc20Store.allowed(_from, _sender);
        require(_value <= senderAllowance, "_value should less equal senderAllowance");

        bytes32 lockId = generateLockId();
        pendingTransferMap[lockId] = PendingTransfer({
            sender : _sender,
            from: _from,
            to: _to,
            value: _value
        });

        emit TransferRequest(lockId, _sender, _from, _to, _value);

        //自动审批
        _transferConfirm(lockId);
        return true;
    }
    
    function transferWithSender(
        address _sender,
        address _to,
        uint256 _value
    )
        public
        onlyProxy 
        whenNotPaused
        onlyTxCheck(_sender, _to, _value) 
        returns (bool success)
    {
        require(_to != address(0), "_to can not be 0");

        erc20Store.adjustLockBalance(_sender);
        uint256 balanceOfSender = erc20Store.balances(_sender);
        require(_value <= balanceOfSender, "balance not enouth");

        bytes32 lockId = generateLockId();
        pendingTransferMap[lockId] = PendingTransfer({
            sender : _sender,
            from: _sender,
            to: _to,
            value: _value
        });

        emit TransferRequest(lockId, _sender, _sender, _to, _value);

        //自动审批
        _transferConfirm(lockId);
        return true;
    }

    function transferConfirm(bytes32 _lockId) 
        public 
        whenNotPaused
        onlyIssuer(msg.sender) 
    {
        _transferConfirm(_lockId);
    }

    // 自动审批单独提出来，去掉 onlyIssuer modifier
    function _transferConfirm(bytes32 _lockId) 
        private 
        whenNotPaused
    {
        PendingTransfer storage pending = pendingTransferMap[_lockId];
        require(pending.sender != address(0), "lockId not found");
        erc20Store.adjustLockBalance(pending.from);
        uint256 balanceOfFrom = erc20Store.balances(pending.from);
        require(pending.value <= balanceOfFrom, "pending value should less equal balanceOfFrom");

        if(pending.from != pending.sender){
            uint256 senderAllowance = erc20Store.allowed(pending.from, pending.sender);
            require(pending.value <= senderAllowance, "pending value should less equal senderAllowance");
        }

        PendingTransfer memory _pending = pending;

        delete pendingTransferMap[_lockId];

        erc20Store.setBalance(_pending.from, balanceOfFrom - _pending.value);
        erc20Store.addBalance(_pending.to, _pending.value);

        if(_pending.from != _pending.sender) {
            erc20Store.setAllowance(_pending.from, _pending.sender, senderAllowance - _pending.value);
        }

        updateShareholders(_pending.from, _pending.to);

        erc20Proxy.emitTransfer(_pending.from, _pending.to, _pending.value);
    }

    function revertTransfer
    (
        uint _tx,
        address _from,
        address _to,
        uint _value
    ) 
        public 
        whenNotPaused
        onlyProxy
    {
        if(_from != address(0)) {
            erc20Store.adjustLockBalance(_from);
            uint256 balanceOfFrom = erc20Store.balances(_from);
            require(_value <= balanceOfFrom, "value should less equal balanceOfFrom");
            erc20Store.setBalance(_from, balanceOfFrom - _value);
        }
        
        if(_to != address(0)) {
            erc20Store.addBalance(_to, _value);
        }

        updateShareholders(_from, _to);
        erc20Proxy.emitTransfer(_from, _to, _value);
        erc20Proxy.emitRevertTransfer(_tx);
    }

}

