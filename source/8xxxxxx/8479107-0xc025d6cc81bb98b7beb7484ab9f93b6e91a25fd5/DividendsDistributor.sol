pragma solidity 0.4.24;
import "./Modifiers.sol";

contract DividendsDistributor is Modifiers {

    function withdrawFoundersComission() external onlyAdmin() returns (bool) {
        _withdrawDividensHelper(founders);
        return true;
    }

    function withdrawDividends() external returns (bool) {
        _withdrawDividensHelper(msg.sender);
        return true;
    }

    function _withdrawDividensHelper(address _beneficiary) private {
        uint balance = pendingWithdrawals[_beneficiary];
        require(balance > 0, "Dividends withdrawal balance is zero.");

        // set state
        pendingWithdrawals[_beneficiary] = 0;

        // withdrawal dividends
        _beneficiary.transfer(balance);
        emit DividendsWithdrawn(_beneficiary, balance);
    }
}
