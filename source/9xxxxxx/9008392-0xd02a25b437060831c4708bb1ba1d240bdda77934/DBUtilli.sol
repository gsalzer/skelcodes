pragma solidity ^0.5.0;

import './Context.sol';
import './Whitelist.sol';
import './IDB.sol';

/**
 * @title DBUtilli
 * @dev This Provide database support services (db)
 */
contract DBUtilli is Context, Whitelist {

    //include other contract
    IDB internal db;

    /**
     * @dev Create store user information (db)
     * @param addr user address
     * @param code user invite Code
     * @param rCode recommend code
     */
    function _registerUser(address addr, string memory code, string memory rCode)
        internal
    {
        db.registerUser(addr, code, rCode);
	}

    /**
     * @dev Set store user information
     * @param addr user addr
     * @param status user status
     */
    function _setUser(address addr, uint status)
        internal
    {
		db.setUser(addr, status);
	}

    /**
     * @dev determine if user invite code is use (db)
     * @param code user invite Code
     * @return bool
     */
    function _isUsedCode(string memory code)
        internal
        view
        returns (bool isUser)
    {
        isUser = db.isUsedCode(code);
		return isUser;
	}

    /**
     * @dev get the user address of the corresponding user invite code (db)
     * Authorization Required
     * @param code user invite Code
     * @return address
     */
    function _getCodeMapping(string memory code)
        internal
        view
        returns (address addr)
    {
        addr = db.getCodeMapping(code);
        return  addr;
	}

    /**
     * @dev get the user address of the corresponding user id (db)
     * Authorization Required
     * @param uid user id
     * @return address
     */
    function _getIndexMapping(uint uid)
        internal
        view
        returns (address addr)
    {
        addr = db.getIndexMapping(uid);
		return addr;
	}

    /**
     * @dev get the user address of the corresponding User info (db)
     * Authorization Required or addr is owner
     * @param addr user address
     * @return info[id,status],code,rCode
     */
    function _getUserInfo(address addr)
        internal
        view
        returns (uint[2] memory info, string memory code, string memory rCode)
    {
        (info, code, rCode) = db.getUserInfo(addr);
		return (info, code, rCode);
	}

    /**
     * @dev get the current latest ID (db)
     * Authorization Required
     * @return current uid
     */
    function _getCurrentUserID()
        internal
        view
        returns (uint uid)
    {
        uid = db.getCurrentUserID();
		return uid;
	}

    /**
     * @dev get the rCodeMapping array length of the corresponding recommend Code (db)
     * Authorization Required
     * @param rCode recommend Code
     * @return rCodeMapping array length
     */
    function _getRCodeMappingLength(string memory rCode)
        internal
        view
        returns (uint length)
    {
        length = db.getRCodeMappingLength(rCode);
		return length;
	}

    /**
     * @dev get the user invite code of the recommend Code [rCodeMapping] based on the index (db)
     * Authorization Required
     * @param rCode recommend Code
     * @param index the index of [rCodeMapping]
     * @return user invite code
     */
    function _getRCodeMapping(string memory rCode, uint index)
        internal
        view
        returns (string memory code)
    {
        code = db.getRCodeMapping(rCode, index);
		return code;
	}

    /**
     * @dev determine if user invite code is use (db)
     * @param code user invite Code
     * @return bool
     */
    function isUsedCode(string memory code)
        public
        view
        returns (bool isUser)
    {
        isUser = _isUsedCode(code);
		return isUser;
	}

    /**
     * @dev get the user address of the corresponding user invite code (db)
     * Authorization Required
     * @param code user invite Code
     * @return address
     */
    function getCodeMapping(string memory code)
        public
        view
        returns (address addr)
    {
        require(checkWhitelist(), "DBUtilli: Permission denied");
        addr = _getCodeMapping(code);
		return addr;
	}

    /**
     * @dev get the user address of the corresponding user id (db)
     * Authorization Required
     * @param uid user id
     * @return address
     */
    function getIndexMapping(uint uid)
        public
        view
        returns (address addr)
    {
        require(checkWhitelist(), "DBUtilli: Permission denied");
		addr = _getIndexMapping(uid);
        return addr;
	}

    /**
     * @dev get the user address of the corresponding User info (db)
     * Authorization Required or addr is owner
     * @param addr user address
     * @return info[id,status],code,rCode
     */
    function getUserInfo(address addr)
        public
        view
        returns (uint[2] memory info, string memory code, string memory rCode)
    {
        require(checkWhitelist() || _msgSender() == addr, "DBUtilli: Permission denied for view user's privacy");
        (info, code, rCode) = _getUserInfo(addr);
		return (info, code, rCode);
	}
}

