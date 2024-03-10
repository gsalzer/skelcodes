pragma solidity ^0.4.24;

import "./token.sol";

contract CompanyToken is Token {
  using SafeMath for uint256;

  /**
   * Company name.
   */
  string internal companyName;

  /**
   * Company country.
   */
  string internal companyCountry;

  /**
   * Company legal form.
   */
  string internal companyLegalForm;
  
  /**
   * @dev Returns the Company Name.
   */
  function CompanyName() external view returns (string _name) { _name = companyName; }

  /**
   * @dev Returns the Company Country.
   */
  function CompanyCountry() external view returns (string _country) { _country = companyCountry; }

  /**
   * @dev Returns the Company legal form.
   */
  function LegalForm() external view returns (string _legal_form) { _legal_form = companyLegalForm; }

}

contract NeroHoldingSharesToken is CompanyToken {
  constructor() public {
    /* Token informations */
    tokenName = "Nero Holding GbR - Company Shares";
    tokenSymbol = "NHGCS";
    tokenDecimals = 0;
    /* Holder transactions */
    balances[address(0xB867B21547F3D7FC551AA49c4B3d5A0aa1163991)] = 1000;
    balances[address(0xD75ae9308DF8734A8EF8AaDDa9b9aD395c1Eb3f4)] = 1000;
    balances[address(0x56d5Cf926f59086921e2A818FEf5d62f4647220e)] = 1000;
    tokenTotalSupply = 3000;
    /* Company informations */
    companyName = "Nero Holding";
    companyCountry = "Germany";
    companyLegalForm = "GbR";
  }
}
