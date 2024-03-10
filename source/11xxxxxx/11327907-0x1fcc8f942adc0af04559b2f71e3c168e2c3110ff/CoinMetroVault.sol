pragma solidity ^0.5.0;

import "./CoinMetroToken.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CoinMetroVault is Ownable {
    using SafeMath for uint256;

    CoinMetroToken public token;

    address public masterWallet;
    uint256 public releaseTimestamp;

    event TokenReleased(address _masterWallet, uint256 _amount);

    constructor(CoinMetroToken _token, address _masterWallet, uint256 _releaseTimestamp) public {
        require(_masterWallet != address(0x0));
        require(_releaseTimestamp > now);
        token = _token;
        masterWallet = _masterWallet;
        releaseTimestamp = _releaseTimestamp;
    }

    function() external payable {
        // does not allow incoming ETH
        revert();
    }

    // function to release all tokens to master wallet
    // revert if timestamp is before {releaseTimestamp}
    function release() external {
        require(now > releaseTimestamp, "Transaction locked");
        uint balance = token.balanceOf(address(this));
        token.transfer(masterWallet, balance);

        emit TokenReleased(masterWallet, balance);
    }
}

