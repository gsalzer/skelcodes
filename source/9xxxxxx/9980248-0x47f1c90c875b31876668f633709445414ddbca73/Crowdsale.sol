pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./Token.sol";
import "./SafeMath.sol";

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    // wallets
    address payable public constant OWNER_WALLET = 0x6982880B46aF48Cf97044a93E783Dcf8F4adDfC2;
    address payable public constant TOKEN_RECEIVE_WALLET = 0xDcAcafc64f8f56452321cdcEc73f1A330E013181;
    address payable public constant ETH_RECEIVE_WALLET = 0x79dFAdaCe453853618C6F05E41538BE53E9E3EED;
    address payable public constant DEV_WALLET = 0x2F2fEF2bf0bC0E2A0B4d4019eD21e3C534eD2E9B;
    address payable public constant PROMOTER_WALLET = 0x4c4D4254f10ED100C5f16b9d7894977035fB8CfE;

    // global arguments
    Token public token;
    bool private _reentrancyLock = false;
    uint256 public rate = 385;
    uint256 private _cap = 70000000e10; // 70M
    uint256 public weiRaised = 0;
    uint256 private devWei = 65e17;
    uint256 private weiReceived = 0;
    uint256 private promoterTokens = 5999000e10;
    uint256 private ownerTokens = 3997000e10;

    constructor(address _token) public {
        token = Token(_token);
        token._mint(TOKEN_RECEIVE_WALLET, ownerTokens);
        token._mint(PROMOTER_WALLET, promoterTokens);
    }

    /*
    * @dev Reentracy security modifier
    */
    modifier nonReentrant() {
        require(!_reentrancyLock, "Reentrancy lock");
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function buyTokens(address _beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        require(weiAmount > 1e16, "Minimum transaction"); // > 0.01 ETH
        require(_beneficiary != address(0), "Zero address");

        uint256 tokens = _calculateTokens(weiAmount);
        uint256 afterSend = token.totalSupply().add(tokens);
        require(afterSend < cap(), "Cap reached");

        _appendContribution(_beneficiary, tokens);
        _payToOwners(weiAmount);
    }

    fallback() payable external {
        buyTokens(msg.sender);
    }

    receive() payable external {
        buyTokens(msg.sender);
    }

    /*
    * @dev Distribution to developers and owners
    */
    function _payToOwners(uint256 weiSent) internal {
        uint256 remain = 0;
        weiRaised = weiRaised.add(weiSent);
        if (weiRaised < devWei) {
            DEV_WALLET.transfer(weiSent);
            weiReceived = weiReceived.add(weiSent);
        } else {
            // raised for dev is more than required
            // if received is less than needed
            if (weiReceived < devWei) {
                remain = devWei.sub(weiReceived);
                DEV_WALLET.transfer(remain);
                weiReceived = weiReceived.add(weiSent);
                uint256 toOwner = weiSent.sub(remain);
                ETH_RECEIVE_WALLET.transfer(toOwner);
            } else {
                ETH_RECEIVE_WALLET.transfer(weiSent);
            }
        }
    }

    /*
    * @dev Internal token calculation function
    * @param {_weiAmount} Amount in wei
    */
    function _calculateTokens(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokens = _weiAmount.mul(rate).div(1e8);
        return tokens;
    }

    /*
    * @dev Internal bonus calculation and minting function
    * @param {_beneficiary} Who will get tokens
    * @param {_tokens} Amount of tokens
    * @return Success
    */
    function _appendContribution(address _beneficiary, uint256 _tokensToMint) internal returns (bool) {
        token._mint(_beneficiary, _tokensToMint);
        return true;
    }

    function withdraw() public onlyOwner returns (bool) {
        ETH_RECEIVE_WALLET.transfer(address(this).balance);
        return true;
    }
}

