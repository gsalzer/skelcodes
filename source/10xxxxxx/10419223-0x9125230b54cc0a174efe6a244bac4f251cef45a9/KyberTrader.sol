// 0x9125230b54Cc0A174eFe6A244baC4f251cEF45A9 mainnet

pragma solidity ^0.6.6;

// import "./kyber/IERC20.sol";
// import "./kyber/IKyberNetworkProxy.sol";
interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8 digits);
    function totalSupply() external view returns (uint256 supply);
}

// to support backward compatible contract name -- so function signature remains same
abstract contract ERC20 is IERC20 {
}

interface IKyberNetworkProxy {

    event ExecuteTrade(address indexed trader, IERC20 src, IERC20 dest, address destAddress, uint256 actualSrcAmount, uint256 actualDestAmount, address platformWallet, uint256 platformFeeBps);

    /// @notice backward compatible
    function tradeWithHint(ERC20 src, uint256 srcAmount, ERC20 dest, address payable destAddress, uint256 maxDestAmount, uint256 minConversionRate, address payable walletId, bytes calldata hint)
    external payable returns (uint256);
    function tradeWithHintAndFee(IERC20 src, uint256 srcAmount, IERC20 dest, address payable destAddress, uint256 maxDestAmount, uint256 minConversionRate, address payable platformWallet, uint256 platformFeeBps, bytes calldata hint) external payable returns (uint256 destAmount);
    function trade(IERC20 src, uint256 srcAmount, IERC20 dest, address payable destAddress, uint256 maxDestAmount, uint256 minConversionRate, address payable platformWallet) external payable returns (uint256);

    /// @notice backward compatible
    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18
    function getExpectedRate(ERC20 src, ERC20 dest, uint256 srcQty) external view returns (uint256 expectedRate, uint256 worstRate);
    function getExpectedRateAfterFee(IERC20 src, IERC20 dest, uint256 srcQty, uint256 platformFeeBps, bytes calldata hint) external view returns (uint256 expectedRate);
}

contract KyberTrader {
    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IKyberNetworkProxy kyberProxy;
    address payable public platformWallet;
    uint256 public platformFeeBps;

    // constructor
    // _platformWallet: To receive platform fees
    // _platformFeeBps: Platform fee amount in basis points
    constructor(
        IKyberNetworkProxy _kyberProxy,
        address payable _platformWallet,
        uint256 _platformFeeBps
        ) public
    {
        kyberProxy = _kyberProxy;
        platformWallet = _platformWallet;
        platformFeeBps = _platformFeeBps;
    }

    /// @dev Get the conversion rate for exchanging srcQty of srcToken to destToken
    function getConversionRates(
        IERC20 srcToken,
        IERC20 destToken,
        uint256 srcQty
    ) public
      view
      returns (uint256)
    {
      return kyberProxy.getExpectedRateAfterFee(srcToken, destToken, srcQty, platformFeeBps, '');
    }

    /// @dev Swap from srcToken to destToken (including ether)
    function executeSwap(
        IERC20 srcToken,
        uint256 srcQty,
        IERC20 destToken,
        address payable destAddress,
        uint256 maxDestAmount
    ) external payable {
        if (srcToken != ETH_TOKEN_ADDRESS) {
            // check that the token transferFrom has succeeded
            // we recommend using OpenZeppelin's SafeERC20 contract instead
            // NOTE: msg.sender must have called srcToken.approve(thisContractAddress, srcQty)
            require(srcToken.transferFrom(msg.sender, address(this), srcQty), "transferFrom failed");

            // mitigate ERC20 Approve front-running attack, by initially setting
            // allowance to 0
            require(srcToken.approve(address(kyberProxy), 0), "approval to 0 failed");

            // set the spender's token allowance to tokenQty
            require(srcToken.approve(address(kyberProxy), srcQty), "approval to srcQty failed");
        }

        // Get the minimum conversion rate
        uint256 minConversionRate = kyberProxy.getExpectedRateAfterFee(
            srcToken,
            destToken,
            srcQty,
            platformFeeBps,
            '' // empty hint
        );

        // Execute the trade and send to destAddress
        kyberProxy.tradeWithHintAndFee{value: msg.value}(
            srcToken,
            srcQty,
            destToken,
            destAddress,
            maxDestAmount,
            minConversionRate,
            platformWallet,
            platformFeeBps,
            '' // empty hint
        );
    }
}
