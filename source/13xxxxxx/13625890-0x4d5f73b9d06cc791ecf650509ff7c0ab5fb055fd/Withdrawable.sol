pragma solidity 0.8.3;

import "./Ownable.sol";

/**
 * @dev Contract that holds pending withdrawals. Responsible for withdrawals.
 */
contract Withdrawable is Ownable {

    mapping(address => uint) private pendingWithdrawals;

    event Withdrawal(address indexed receiver, uint amount);
    event BalanceChanged(address indexed _address, uint oldBalance, uint newBalance);

    /**
    * Returns amount of wei that given address is able to withdraw.
    */
    function getPendingWithdrawal(address _address) public view returns (uint) {
        return pendingWithdrawals[_address];
    }

    /**
    * Add pending withdrawal for an address.
    */
    function addPendingWithdrawal(address _address, uint _amount) internal {
        require(_address != address(0x0));

        uint oldBalance = pendingWithdrawals[_address];
        pendingWithdrawals[_address] += _amount;

        emit BalanceChanged(_address, oldBalance, oldBalance + _amount);
    }

    /**
    * Withdraws all pending withdrawals.
    */
    function withdraw() external {
        uint amount = getPendingWithdrawal(msg.sender);
        require(amount > 0);

        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount);
        emit BalanceChanged(msg.sender, amount, 0);
    }

}
