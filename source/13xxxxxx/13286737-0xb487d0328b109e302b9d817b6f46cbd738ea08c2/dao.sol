// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.7;

contract DAO {
    address public dao;

    event DAOChanged(address from, address to);

    constructor() {
        dao = msg.sender;
        emit DAOChanged(address(0), msg.sender);
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    function changeDAO(address _dao) external onlyDAO {
        require(_dao != address(0), "DAO to ZERO");
        address olddao = dao;
        dao = _dao;
        emit DAOChanged(olddao, dao);
    }

}

