pragma solidity 0.4.18;

// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/// @title Kyber Network interface


/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}


contract Trader {
    KyberNetworkProxyInterface KyberInterface = KyberNetworkProxyInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
   
    function getKyberRates(
        ERC20 srcToken,
        uint srcQty,
        ERC20 destToken
    ) public
      view
      returns (uint, uint)
    {
        return KyberInterface.getExpectedRate(srcToken, destToken, srcQty);

    }
    
    function executeSwap(
        ERC20 srcToken,
        uint srcQty,
        ERC20 destToken,
        uint minConversionRate
    ) public returns(uint) {
        bytes memory hint;
        
        // Check that the token transferFrom has succeeded
        require(srcToken.transferFrom(msg.sender, address(this), srcQty));
    
        // Mitigate ERC20 Approve front-running attack, by initially setting
        // allowance to 0
        require(srcToken.approve(address(KyberInterface), 0));
    
        // Set the spender's token allowance to tokenQty
        require(srcToken.approve(address(KyberInterface), srcQty));

        // Swap the ERC20 token and send to destAddress
        uint res = KyberInterface.tradeWithHint(
            srcToken,
            srcQty,
            destToken,
            msg.sender,
            (10**28),
            minConversionRate,
            0,
            hint
        );
        return res;
    }
}
