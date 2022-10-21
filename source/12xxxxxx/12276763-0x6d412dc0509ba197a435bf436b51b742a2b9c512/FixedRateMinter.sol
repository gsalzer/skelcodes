// SPDX-License-Identifier: F-F-F-FIAT!!!
pragma solidity ^0.7.4;

import "./Address.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Fiat.sol";
import "./TokensRecoverable.sol";

abstract contract FixedRateMinter is TokensRecoverable {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    Fiat public immutable fiat;
    IERC20 public immutable token;

    mapping(address => uint256) public collaterals; // Token
    mapping(address => uint256) public debts; // Fiat   

    uint256 public totalDebt;
    uint256 public totalCollaterals;
    uint256 public fiatPerToken;
    uint256 public mintFeeRate; //100.00 = 10000
    uint256 public redeemFeeRate;
    address public feeSplitter;
    uint256 public constant precision = 10000; //1.0000

    constructor(Fiat _fiat, IERC20 _token) {
        fiat = _fiat;
        token = _token;
    }

    function setMintFeeRate(uint256 _mintFeeRate) public ownerOnly() {
        mintFeeRate = _mintFeeRate;
    }

    function setRedeemFeeRate(uint256 _redeemFeeRate) public ownerOnly() {
        redeemFeeRate = _redeemFeeRate;
    }

    function setFeeSplitter(address _feeSplitter) public ownerOnly() {
        feeSplitter = _feeSplitter;
    }

    function updateFiatPerToken(uint256 _fiatPerToken) public ownerOnly() {
        fiatPerToken = _fiatPerToken;
    }

    function depositCollateral(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), amount);
        collaterals[msg.sender] += amount;
        totalCollaterals += amount;
    }

    function mintFiat(uint256 amount) public {
        require(amount <= getAvailableToMint(msg.sender), "Not enough collateral to mint fiat");
        
        uint256 mintFee = amount * mintFeeRate / precision;              
        fiat.mint(feeSplitter, mintFee);
        fiat.mint(msg.sender, amount - mintFee);
        debts[msg.sender] += amount;
        totalDebt += amount;
    }

    function repayDebt(address account, uint256 amount) public {
        uint256 redeemFee = amount * redeemFeeRate / precision; 
        fiat.transferFrom(msg.sender, feeSplitter, redeemFee);
        fiat.burn(msg.sender, amount - redeemFee);
        debts[account] -= amount;
        totalDebt -= amount;
    }

    function withdrawCollateral(uint256 amount) public {
        require(getAvailableCollateralToWithdraw(msg.sender) >= amount, "Not enough collateral to withdraw");

        token.transfer(msg.sender, amount);
        collaterals[msg.sender] -= amount;
        totalCollaterals -= amount;
    }

    function getAvailableToMint(address account) public view returns (uint256) {
        return collaterals[account].mul(fiatPerToken).div(precision) - debts[account];
    }

    function getAvailableCollateralToWithdraw(address account) public view returns (uint256) {
        return collaterals[account] - debts[account].mul(1e18).div(fiatPerToken).div(precision).div(1e18);
    }

    function canRecoverTokens(IERC20 tokenToRecover) internal virtual override view returns (bool) { 
        return address(tokenToRecover) != address(token); 
    }
}

