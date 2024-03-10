pragma solidity 0.6.5;

interface IERC20 {
    function transferFrom(address holder, address dst, uint256 wad) 
        external 
        returns (bool);

    function permit(
        address holder, 
        address spender,
        uint256 nonce, 
        uint256 expiry, 
        bool allowed,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        external;
}
