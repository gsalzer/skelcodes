pragma solidity ^0.5.0;

import "./TimeSim.sol";
contract SmartLoan {
  /*
  TO DO:
  move the state variables into a struct
  check for overflows
  */

  /*
  The SmartLoan contract represents the loan which the originator grants to the
  borrowers. The originator sends the loan balance to the borrower and deploys the
  contract code on the blockchain. The code allows to track the loan, to make
  payments to the loan and to withdraw funds from it.
  */

  /*
  Variables
  -------------------------------------------------------------------------------
  */
  uint256 public OriginalBalance;
  uint256 public CurrentBalance;
  uint256 public IntPaidIn;
  uint256 public PrinPaidIn;
  uint256 public MonthlyInstallment;
  uint256 public InterestRateBasisPoints;
  uint256 public OriginalTermMonths;
  uint256 public RemainingTermMonths;
  uint256 public NextPaymentDate;
  uint256 public PaymentsMade;
  uint256 public OverdueDays;

  uint256 public Now;
  uint256[120] public PaymentDates;

  bool public ContractCurrent = true;

  address payable public LenderAddress;
  address public TimeAddress;

  TimeSim Time;

  /*
Modifiers
-------------------------------------------------------------------------------
*/
  modifier OnlyLender {
    require(msg.sender == LenderAddress, "Error lender address");
    _;
  }

  /*
    Constructor
    -------------------------------------------------------------------------------
    •	lenderAddress: This is the adress of an account on the blockchain. The account
    can be controlled by a human or another contract. Whoever controls this account
    is allowed to withdraw paidin funds from the Smartloan contract.
    •	balance: The principal balance of the loan which must be repaid by the
      borrower
    •	interestRateBasisPoints: The interstate charged on the loan. It is given in
      basispoints i.e. the input for 5% interest would be 500
    •	termMonths: The term of the loan in moths. In this implementation fixed to 12.
    */
  constructor(
    address payable lenderAddress,
    uint256 balance,
    uint256 interestRateBasisPoints,
    uint256 termMonths,
    address timeAddress
  ) public {
    LenderAddress = lenderAddress;
    TimeAddress = timeAddress;
    OriginalBalance = balance;
    CurrentBalance = balance;
    InterestRateBasisPoints = interestRateBasisPoints;
    OriginalTermMonths = termMonths;
    RemainingTermMonths = termMonths;
    Time = TimeSim(timeAddress);

    /*
    the calculation of the monhtly installment needs divions. Since floats are not
    availabe, we make the calc in a way to reduce rounding error:
    */
    uint256 MonthlyInstallment1 = (
        interestRateBasisPoints * (10000 * termMonths + interestRateBasisPoints) ** termMonths
      ) /
      1000000;
    uint256 MonthlyInstallment2 = (
        (10000 * termMonths + interestRateBasisPoints) **
          termMonths *
          10000 *
          termMonths -
          10000 **
          (termMonths + 1) *
          termMonths **
          (termMonths + 1)
      ) /
      1000000;

    // if (MonthlyInstallment2 != 0)
    //   MonthlyInstallment = balance * (MonthlyInstallment1) / (MonthlyInstallment2 + 1);

    if (MonthlyInstallment2 != 0)
      MonthlyInstallment = balance * MonthlyInstallment1 / (MonthlyInstallment2 + 1);

    for (uint256 k = 0; k < termMonths; k++) {
      PaymentDates[k] = now + (k + 1) * 30 days;
    }

    NextPaymentDate = PaymentDates[0];
  }

  /*
  Function to read the state
  */
  function Read() public view returns (uint256[11] memory) {
    return [
      OverdueDays,
      OriginalBalance,
      CurrentBalance,
      NextPaymentDate,
      IntPaidIn,
      PrinPaidIn,
      MonthlyInstallment,
      InterestRateBasisPoints,
      OriginalTermMonths,
      RemainingTermMonths,
      address(this).balance
    ];
  }

  /*
  self explanatory
  */
  function ReadTime() public view returns (address) {
    return TimeAddress;
  }

  /*
  Updates the state after installment is paid in
  */
  function ContractCurrentUpdate() private returns (uint256) {
    PaymentsMade = OriginalTermMonths - RemainingTermMonths;
    NextPaymentDate = PaymentDates[PaymentsMade];

    if (Time.Now() > NextPaymentDate && RemainingTermMonths != 0) {
      ContractCurrent = false;
      OverdueDays = (Time.Now() - NextPaymentDate) / (60 * 60 * 24);
      return OverdueDays;
    }

    OverdueDays = 0;
    ContractCurrent = true;
    return OverdueDays;
  }

  /*
  This function is essential for transfer of ownership. The lenderAddress owner
  has the option to grant its rights to withdraw funds from the loan to another
  party. In our case this will be another contract on the blockchain to which the
  originator "sells " the loan.
  */
  function Transfer(address payable NewLender) public OnlyLender() {
    LenderAddress = NewLender;
  }

  /*
  Allows the borrower to pay an installment. The installments are of equal size
  depending on the interest rate, original balance and loanterm. The installment
  has an interest and a principal portion, it is not possible to pay more or less
  than one installment by using this function. Upon payment of the installment,
  the contract updates its status information (see below).
  */
  function PayIn() public payable {
    uint256 Principal;
    uint256 Interest;

    require(msg.value == MonthlyInstallment, "Invalid MonthlyInstallment");
    require(RemainingTermMonths != 0, "RemainingTermMonths == 0");
    //if (msg.value != MonthlyInstallment) throw;
    //if (RemainingTermMonths == 0) throw;

    RemainingTermMonths--;
    Principal = CalculatePVOfInstallment(OriginalTermMonths - RemainingTermMonths);
    Interest = MonthlyInstallment - Principal;
    CurrentBalance -= Principal;
    IntPaidIn += Interest;
    PrinPaidIn += Principal;

    ContractCurrentUpdate();
  }

  /*
  Allows the lenderAddress owner to withdraw funds from the contract. This
  function also passes along the status of the loan.
  */
  function WithdrawIntPrin() public OnlyLender returns (uint256[10] memory) {
    uint256 intPaidIn = IntPaidIn;
    uint256 prinPaidIn = PrinPaidIn;

    OverdueDays = ContractCurrentUpdate();

    LenderAddress.transfer(IntPaidIn + PrinPaidIn);
    //if(LenderAddress.send(IntPaidIn + PrinPaidIn)==false) throw;

    IntPaidIn = 0;
    PrinPaidIn = 0;

    return [
      OverdueDays,
      OriginalBalance,
      CurrentBalance,
      NextPaymentDate,
      intPaidIn,
      prinPaidIn,
      MonthlyInstallment,
      InterestRateBasisPoints,
      OriginalTermMonths,
      RemainingTermMonths
    ];
  }

  /*
  Function used for Present Vaule calc in the Principal portion calculation
  */
  function CalculatePVOfInstallment(uint256 periods) public view returns (uint256) {
    uint256 PV = MonthlyInstallment *
      (10000 * OriginalTermMonths) **
      periods /
      (10000 * OriginalTermMonths + InterestRateBasisPoints) **
      periods;

    return PV;
  }

}

