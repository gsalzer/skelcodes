// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./IWETH.sol";

contract WETH9 is IWETH
{
    string public override name     = "Wrapped Ether";
    string public override symbol   = "WETH";
    uint8  public override decimals = 18;

    mapping (address => uint)                       public override balanceOf;
    mapping (address => mapping (address => uint))  public override allowance;

    receive() external payable {
        deposit();
    }
    function deposit() public payable override {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public override {
        require(balanceOf[msg.sender] >= wad, "weth a: not enough balance");
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public override view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public override returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public override returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        override
        returns (bool)
    {
        require(balanceOf[src] >= wad, "weth b: not enough balance");

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "weth c: not enough allowance");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}
