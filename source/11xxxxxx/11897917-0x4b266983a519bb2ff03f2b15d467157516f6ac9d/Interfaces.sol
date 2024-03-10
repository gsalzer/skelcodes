// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

interface ITokenManager {
    function payout(string calldata quarter, address recipient, uint amount) external returns (bool success);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISafeMath {
    function add(uint256 a, uint256 b) external pure returns (uint256);
    function sub(uint256 a, uint256 b) external pure returns (uint256);
    function mul(uint256 a, uint256 b) external pure returns (uint256);
    function div(uint256 a, uint256 b) external pure returns (uint256);
    function min(uint256 a, uint256 b) external pure returns (uint256);
    function mod(uint256 a, uint256 b) external pure returns (uint256);
}

interface IKladeDiffToken {
    function set_payout(uint payout) external;
    function mint_tokens(address token_recipient, uint256 numToMint) external returns (bool success);
}

interface IChainlinkOracle {
    function latestRoundData() external view returns (
          uint80,
          int256,
          uint256,
          uint256,
          uint80
    );
}
