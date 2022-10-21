pragma solidity ^0.5.16;

import "./AToken.sol";

/**
 * @notice AEther contract
 * @author Aegis
 */
contract AEther is AToken {

    /**
     * @notice init AEther contract
     * @param _comptroller comptroller
     * @param _interestRateModel interestRate
     * @param _initialExchangeRateMantissa exchangeRate
     * @param _name name
     * @param _symbol symbol
     * @param _decimals decimals
     * @param _admin owner address
     * @param _liquidateAdmin liquidate admin address
     * @param _reserveFactorMantissa reserveFactorMantissa
     */
    constructor (AegisComptrollerInterface _comptroller, InterestRateModel _interestRateModel, uint _initialExchangeRateMantissa, string memory _name,
            string memory _symbol, uint8 _decimals, address payable _admin, address payable _liquidateAdmin, uint _reserveFactorMantissa) public {
        admin = msg.sender;
        initialize(_name, _symbol, _decimals, _comptroller, _interestRateModel, _initialExchangeRateMantissa, _liquidateAdmin, _reserveFactorMantissa);
        admin = _admin;
    }

    function () external payable {
        (uint err,) = mintInternal(msg.value);
        require(err == uint(Error.SUCCESS), "AEther::mint failure");
    }

    function mint() external payable {
        (uint err,) = mintInternal(msg.value);
        require(err == uint(Error.SUCCESS), "AEther::mint failure");
    }
    function redeem(uint _redeemTokens) external returns (uint) {
        return redeemInternal(_redeemTokens);
    }
    function redeemUnderlying(uint _redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(_redeemAmount);
    }
    function borrow(uint _borrowAmount) external returns (uint) {
        return borrowInternal(_borrowAmount);
    }
    function repayBorrow() external payable {
        (uint err,) = repayBorrowInternal(msg.value);
        require(err == uint(Error.SUCCESS), "AEther::repayBorrow failure");
    }
    function repayBorrowBehalf(address _borrower) external payable {
        (uint err,) = repayBorrowBehalfInternal(_borrower, msg.value);
        require(err == uint(Error.SUCCESS), "AEther::repayBorrowBehalf failure");
    }
    function ownerRepayBorrowBehalf (address _borrower) external payable {
        require(msg.sender == liquidateAdmin, "AEther::ownerRepayBorrowBehalf spender failure");
        uint err = ownerRepayBorrowBehalfInternal(_borrower, msg.sender, msg.value);
        require(err == uint(Error.SUCCESS), "AEther::ownerRepayBorrowBehalf failure");
    }

    function getCashPrior() internal view returns (uint) {
        (MathError err, uint startingBalance) = subUInt(address(this).balance, msg.value);
        require(err == MathError.NO_ERROR);
        return startingBalance;
    }

    function doTransferIn(address _from, uint _amount) internal returns (uint) {
        require(msg.sender == _from, "AEther::doTransferIn sender failure");
        require(msg.value == _amount, "AEther::doTransferIn value failure");
        return _amount;
    }

    function doTransferOut(address payable _to, uint _amount) internal {
        _to.transfer(_amount);
    }
}
