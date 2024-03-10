pragma solidity ^0.5.8;

contract IPledgeMining {
    event PledgeEvent(address indexed user, uint256 indexed amount, uint256 indexed day);
    event ReceiveIncomeEvent(address indexed user, uint256 indexed amount, uint256 indexed index);
    event RemovePledgeEvent(address indexed user, uint256 indexed amount, uint256 indexed index);


    function pledge(uint256 _amount, uint256 _type) public returns (uint256);

    function calcReceiveIncome(address addr, uint256 _index) public view returns (uint256);

    function receiveIncome(uint256 _index) public returns (uint256);

    function removePledge(uint256 _index) public returns (uint256);

    function closeRenewal(uint256 _index) public;

    function openRenewal(uint256 _index) public;

    function getUserRecords(address addr, uint256 offset, uint256 size) public view returns (
        uint256 [4] memory page,
        uint256 [] memory data
    );

}
