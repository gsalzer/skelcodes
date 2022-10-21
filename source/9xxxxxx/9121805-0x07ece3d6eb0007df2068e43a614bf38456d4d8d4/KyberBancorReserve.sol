pragma solidity 0.5.11;

import "./ERC20InterfaceV5.sol";
import "./KyberReserveInterfaceV5.sol";
import "./WithdrawableV5.sol";
import "./UtilsV5.sol";
import "./IBancorContracts.sol";

contract KyberBancorReserve is KyberReserveInterface, Withdrawable, Utils {

    uint  constant internal BPS = 10000; // 10^4

    address public kyberNetwork;
    bool public tradeEnabled;
    uint public feeBps;

    IBancorNetwork public bancorNetwork; // 0x0e936B11c2e7b601055e58c7E32417187aF4de4a

    ERC20 public bancorEth = ERC20(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
    ERC20 public bancorToken = ERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);

    constructor(
        address _bancorNetwork,
        address _kyberNetwork,
        uint _feeBps,
        address _bancorEth,
        address _bancorToken,
        address _admin
    )
        public
    {
        require(_bancorNetwork != address(0), "bancorNetwork address is missing");
        require(_kyberNetwork != address(0), "kyberNetwork address is missing");
        require(_bancorEth != address(0), "bancorEth address is missing");
        require(_bancorToken != address(0), "bancorToken address is missing");
        require(_admin != address(0), "admin address is missing");
        require(_feeBps < BPS, "fee is too big");

        bancorNetwork = IBancorNetwork(_bancorNetwork);
        bancorToken = ERC20(_bancorToken);
        bancorEth = ERC20(_bancorEth);

        kyberNetwork = _kyberNetwork;
        feeBps = _feeBps;
        admin = _admin;
        tradeEnabled = true;

        require(bancorToken.approve(address(bancorNetwork), 2 ** 255));
    }

    function() external payable { }

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint) public view returns(uint) {
        if (!tradeEnabled) return 0;

        if (src != ETH_TOKEN_ADDRESS && dest != ETH_TOKEN_ADDRESS) {
            return 0; // either src or dest must be ETH
        }
        ERC20 token = src == ETH_TOKEN_ADDRESS ? dest : src;
        if (token != bancorToken) { return 0; } // not BNT token

        ERC20[] memory path = getConversionPath(src, dest);

        uint destQty;
        (destQty, ) = bancorNetwork.getReturnByPath(path, srcQty);

        uint rate = calcRateFromQty(srcQty, destQty, getDecimals(src), getDecimals(dest));

        rate = valueAfterReducingFee(rate);

        return rate;
    }

    event TradeExecute(
        address indexed sender,
        address src,
        uint srcAmount,
        address destToken,
        uint destAmount,
        address payable destAddress
    );

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address payable destAddress,
        uint conversionRate,
        bool validate
    )
        public
        payable
        returns(bool)
    {

        require(tradeEnabled);
        require(msg.sender == kyberNetwork);
        require(srcToken == ETH_TOKEN_ADDRESS || destToken == ETH_TOKEN_ADDRESS);
        require(srcToken == bancorToken || destToken == bancorToken);

        require(doTrade(srcToken, srcAmount, destToken, destAddress, conversionRate, validate));

        return true;
    }

    // test func
    function testGetReturns(ERC20 token, bool isEthToToken, uint srcAmount) public returns(uint) {
        uint destAmount;
        ERC20[] memory path = getConversionPath(
            isEthToToken ? ETH_TOKEN_ADDRESS : token,
            isEthToToken ? token : ETH_TOKEN_ADDRESS
        );
        if (isEthToToken) {
            (destAmount, ) = bancorNetwork.getReturnByPath(path, srcAmount);
        } else {
            (destAmount, ) = bancorNetwork.getReturnByPath(path, srcAmount);
        }
        return destAmount;
    }

    event KyberNetworkSet(address kyberNetwork);

    function setKyberNetwork(address _kyberNetwork) public onlyAdmin {
        require(_kyberNetwork != address(0), "kyberNetwork address is missing");

        kyberNetwork = _kyberNetwork;
        emit KyberNetworkSet(_kyberNetwork);
    }

    event BancorNetworkSet(address _bancorNetwork);
    function setContractRegistry(address _bancorNetwork) public onlyAdmin {
        require(_bancorNetwork != address(0), "bancorNetwork address is missing");

        if (address(bancorNetwork) != address(0)) {
            require(bancorToken.approve(address(bancorNetwork), 0));
        }
        bancorNetwork = IBancorNetwork(_bancorNetwork);
        require(bancorToken.approve(address(bancorNetwork), 2 ** 255));

        emit BancorNetworkSet(_bancorNetwork);
    }

    event FeeBpsSet(uint feeBps);

    function setFeeBps(uint _feeBps) public onlyAdmin {
        require(_feeBps < BPS, "setFeeBps: feeBps >= bps");

        feeBps = _feeBps;
        emit FeeBpsSet(feeBps);
    }

    event TradeEnabled(bool enable);

    function enableTrade() public onlyAdmin returns(bool) {
        tradeEnabled = true;
        emit TradeEnabled(true);

        return true;
    }

    function disableTrade() public onlyAlerter returns(bool) {
        tradeEnabled = false;
        emit TradeEnabled(false);

        return true;
    }

    function doTrade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address payable destAddress,
        uint conversionRate,
        bool validate
    )
        internal
        returns(bool)
    {
        // can skip validation if done at kyber network level
        if (validate) {
            require(conversionRate > 0);
            if (srcToken == ETH_TOKEN_ADDRESS)
                require(msg.value == srcAmount, "doTrade: msg value is not correct for ETH trade");
            else
                require(msg.value == 0, "doTrade: msg value is not correct for token trade");
        }

        if (srcToken != ETH_TOKEN_ADDRESS) {
            // collect source amount
            require(srcToken.transferFrom(msg.sender, address(this), srcAmount), "doTrade: collect src token failed");
        }

        ERC20[] memory path = getConversionPath(srcToken, destToken);
        require(path.length > 0, "doTrade: couldn't find path");

        // both BNT and ETH has decimals of 18 (MAX_DECIMALS)
        uint userExpectedDestAmount = calcDstQty(srcAmount, MAX_DECIMALS, MAX_DECIMALS, conversionRate);
        uint destAmount;

        if (srcToken == ETH_TOKEN_ADDRESS) {
            destAmount = bancorNetwork.convert2.value(srcAmount)(path, srcAmount, userExpectedDestAmount, address(0), 0);
        } else {
            destAmount = bancorNetwork.convert2(path, srcAmount, userExpectedDestAmount, address(0), 0);
        }

        require(destAmount >= userExpectedDestAmount, "doTrade: dest amount is lower than expected amount");

        if (destToken == ETH_TOKEN_ADDRESS) {
            destAddress.transfer(userExpectedDestAmount);
        } else {
            require(destToken.transfer(destAddress, userExpectedDestAmount), "doTrade: transfer back dest token failed");
        }

        emit TradeExecute(msg.sender, address(srcToken), srcAmount, address(destToken), userExpectedDestAmount, destAddress);
        return true;
    }

    function getConversionPath(ERC20 src, ERC20 dest) public view returns(ERC20[] memory path) {
        ERC20 bntToken = bancorToken;

        // handle special case ETH-BNT trade to save gas
        if (src == bntToken) {
            // trade from BNT to ETH
            path = new ERC20[](3);
            path[0] = bntToken;
            path[1] = bntToken;
            path[2] = bancorEth;
            return path;
        } else if (dest == bntToken) {
            // trade from ETH to BNT
            path = new ERC20[](3);
            path[0] = bancorEth;
            path[1] = bntToken;
            path[2] = bntToken;
            return path;
        }
    }

    function valueAfterReducingFee(uint val) internal view returns(uint) {
        require(val <= MAX_QTY, "valueAfterReducingFee: val > MAX_QTY");
        return ((BPS - feeBps) * val) / BPS;
    }
}
