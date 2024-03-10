pragma solidity ^0.4.24;

contract BurnStats  {
     address owner;
      constructor() public{
       owner = msg.sender;
}
    mapping(uint128 => uint) public burns;
    uint public totalBurn = 228312000000000000000000;
    function burn(uint amount, uint128 day) public {
        require(msg.sender == owner);
        0x10Ef64cb79Fd4d75d4Aa7e8502d95C42124e434b.call(bytes4(keccak256("burn(uint256)")), amount);
        totalBurn =  totalBurn + amount;
        burns[day] = totalBurn;
    }
    function setDay(uint amount, uint128 day) public {
        require(msg.sender == owner);
        burns[day] = amount;
    }
    function setTotal(uint total) public {
        require(msg.sender == owner);
        totalBurn = total;
    }
    function getDay( uint128 day) public view returns (uint) {
       return burns[day];
    }
}
