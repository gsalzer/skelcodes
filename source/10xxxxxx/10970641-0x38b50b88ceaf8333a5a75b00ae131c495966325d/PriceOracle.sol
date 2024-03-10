pragma solidity ^0.5.16;

import "./AToken.sol";

/**
 * @title Aegis Price Oracle
 * @author Aegis
 */
contract PriceOracle {
    address public owner;
    mapping(address => uint) prices;
    event PriceAccept(address _aToken, uint _oldPrice, uint _acceptPrice);

    constructor (address _admin) public {
        owner = _admin;
    }

    function getUnderlyingPrice(address _aToken) external view returns (uint) {
        // USDT/USDC 1:1
        if(keccak256(abi.encodePacked((AToken(_aToken).symbol()))) == keccak256(abi.encodePacked(("USDT-A"))) || keccak256(abi.encodePacked((AToken(_aToken).symbol()))) == keccak256(abi.encodePacked(("USDC-A")))) {
            return 1e18;
        }
        return prices[_aToken];
    }

    function postUnderlyingPrice(address _aToken, uint _price) external {
        require(msg.sender == owner, "PriceOracle::postUnderlyingPrice owner failure");
        uint old = prices[_aToken];
        prices[_aToken] = _price;
        emit PriceAccept(_aToken, old, _price);
    }
}
