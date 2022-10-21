pragma solidity >=0.4.21 <0.6.0;

import "./KOCToken.sol";

contract ResonanceF {
    address[5] internal admin = [address(0x8434750c01D702c9cfabb3b7C5AA2774Ee67C90D), address(0xD8e79f0D2592311E740Ff097FFb0a7eaa8cb506a), address(0x740beb9fa9CCC6e971f90c25C5D5CC77063a722D), address(0x1b5bbac599f1313dB3E8061A0A65608f62897B0C), address(0x6Fd6dF175B97d2E6D651b536761e0d36b33A9495)];

    address internal boosAddress = address(0x541f5417187981b28Ef9e7Df814b160Ae2Bcb72C);

    KOCToken  internal kocInstance;

    modifier onlyAdmin () {
        address adminAddress = msg.sender;
        require(adminAddress == admin[0] || adminAddress == admin[1] || adminAddress == admin[2] || adminAddress == admin[3]|| adminAddress == admin[4]);
        _;
    }

    function withdrawAll()
    public
    payable
    onlyAdmin()
    {
       address(uint160(boosAddress)).transfer(address(this).balance);
       kocInstance.transfer(address(uint160(boosAddress)), kocInstance.balanceOf(address(this)));
    }
}

