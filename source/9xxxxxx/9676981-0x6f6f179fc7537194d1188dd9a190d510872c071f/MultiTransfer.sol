pragma solidity ^0.6.3;

interface ERC20 {
    function transfer(address _recipient, uint256 amount) external;
}

contract MultiTransfer {
    mapping(address => bool) public Owners;

    modifier onlyOwner() {
        require(Owners[msg.sender], "Error, You are not an Owner");
        _;
    }

    constructor() public {
        Owners[msg.sender] = true;
    }

    function multiTransfer(
        ERC20 token,
        address[] memory _addresses,
        uint256[] memory amount
    ) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], amount[i]);
        }
    }

    function addOwner(address newOwner) public onlyOwner {
        Owners[newOwner] = true;
    }
}

//0x23231758be09a95bac2176a0bdc0c1cb81e887fc,["0xF0Ecbd73405928046207F737D73ed15889f546DB","0x0443E4E465E755F1D54605ec925DeA031A5038F4"],[4,6]
