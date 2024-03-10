pragma solidity ^0.5.7;

interface ERC20Interface {
    function transfer(address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
}


contract mint {
    
    address public ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    function getAddressWETH() public pure returns (address eth) {
        eth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }
    
    function getAddressZRXExchange() public pure returns (address zrxExchange) {
        zrxExchange = 0x080bf510FCbF18b91105470639e9561022937712;
    }
    
    function mintWeth(bytes memory calldataHexString, address dest) public payable {
        ERC20Interface wethContract = ERC20Interface(getAddressWETH());
        wethContract.deposit.value(msg.value)();
        wethContract.approve(getAddressZRXExchange(), msg.value);
        getAddressZRXExchange().call(calldataHexString);
        ERC20Interface tokenContract = ERC20Interface(dest);
        uint tokenBal = tokenContract.balanceOf(address(this));
        assert(tokenContract.transfer(msg.sender, tokenBal));
    }
    
    function collectTokens(address token) public {
        if (token == ethAddr) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20Interface tokenContract = ERC20Interface(token);
            uint tokenBal = tokenContract.balanceOf(address(this));
            require(tokenContract.transfer(msg.sender, tokenBal), "Transfer failed");
        }
    }
    
}
