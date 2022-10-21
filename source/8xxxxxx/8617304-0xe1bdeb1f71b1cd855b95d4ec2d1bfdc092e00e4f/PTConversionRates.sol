pragma solidity 0.5.11;

import "./ERC20Interface.sol";
import "./Utils.sol";
import "./PermissionGroups.sol";


interface KyberProxy {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty)
        external view
        returns(uint expectedRate, uint slippageRate);
}


interface MedianizerInterface {
    function peek() external view returns (bytes32, bool);
}


/*
PT = Promotion Token, used by KyberSwap for promotional purposes
1 PT token should convert to slightly more than 1 DAI.
*/
contract PTToDaiConversionRate is Utils, PermissionGroups {
    MedianizerInterface public medianizer = MedianizerInterface(0x729D19f657BD0614b4985Cf1D82531c67569197B);
    ERC20 public constant ETH_ADDRESS = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ERC20 public ptTokenAddress = ERC20(0x094c875704c14783049DDF8136E298B3a099c446);

    constructor(address _admin) public PermissionGroups (_admin) {}

    function setMedianizer(MedianizerInterface _medianizer) public onlyAdmin {
        require(address(_medianizer) != address(0), "medianizer address is null");
        medianizer = _medianizer;
    }

    function setPTTokenAddress(ERC20 _ptTokenAddress) public onlyAdmin {
        require(address(_ptTokenAddress) != address(0), "PT token address is null");
        ptTokenAddress = _ptTokenAddress;
    }

    function recordImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public
    {
      //do nothing
    }

    function getRate(ERC20 token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint) {
        if(address(token) != address(ptTokenAddress)) return 0;
        if(buy) return 0;

        //fetch value from Maker's Medianizer
        (bytes32 usdPerEthInWei, bool valid) = medianizer.peek();
        require(valid, "medianizer rate not valid");

        uint usdPerEthInPrecision = uint(usdPerEthInWei);
        /*
        buyRate = ETH -> DAI rate. We want to return a rate such that 1 PT token ~ 1 DAI
        */
        return 1005 * (PRECISION * PRECISION / usdPerEthInPrecision) / 1000;
    }
}

