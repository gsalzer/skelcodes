// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./XIVDatabaseLib.sol";

interface Token{
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}


interface OracleWrapper{
    function getPrice(string calldata currencySymbol,uint256 oracleType) external view returns (uint256);
}
interface DatabaseContract{
    function transferTokens(address contractAddress,address userAddress,uint256 amount) external;
    function transferFromTokens(address contractAddress,address fromAddress, address toAddress,uint256 amount) external;
    function getTokensStaked(address userAddress) external view returns(uint256);
    function updateTokensStaked(address userAddress, uint256 amount) external;
    function getTokenStakedAmount() external view returns(uint256);
    function updateTokenStakedAmount(uint256 _tokenStakedAmount) external;
    function getBetId() external view returns(uint256);
    function updateBetId(uint256 _userBetId) external;
    function updateBetArray(XIVDatabaseLib.BetInfo memory bObject) external;
    function getBetArray() external view returns(XIVDatabaseLib.BetInfo[] memory);
    function getFindBetInArrayUsingBetIdMapping(uint256 _betid) external view returns(uint256);
    function updateFindBetInArrayUsingBetIdMapping(uint256 _betid, uint256 value) external;
    function updateUserStakedAddress(address _address) external;
    function updateUserStakedAddress(address[] memory _userStakedAddress) external;
    function getUserStakedAddress() external view returns(address[] memory);
    function getFixedMapping(address _betContractAddress, uint256 coinType) external view returns(XIVDatabaseLib.DefiCoin memory);
    function getFlexibleMapping(address _betContractAddress, uint256 coinType) external view returns(XIVDatabaseLib.DefiCoin memory);
    function getFlexibleDefiCoinArray() external view returns(XIVDatabaseLib.FlexibleInfo[] memory);
    function getFlexibleIndexArray() external view returns(XIVDatabaseLib.FlexibleInfo[] memory);
    function updateBetArrayIndex(XIVDatabaseLib.BetInfo memory bObject, uint256 index) external;
    function updateBetIndexArray(uint256 _betId, XIVDatabaseLib.IndexCoin memory iCArray) external;
    function updateBetBaseIndexValue(uint256 _betBaseIndexValue, uint256 coinType) external;
    function getBetBaseIndexValue(uint256 coinType) external view returns(uint256);
    function updateBetPriceHistoryMapping(uint256 _betId, XIVDatabaseLib.BetPriceHistory memory bPHObj) external;
    function updateBetActualIndexValue(uint256 _betActualIndexValue, uint256 coinType) external;
    function getBetActualIndexValue(uint256 coinType) external view returns(uint256);
    function getBetIndexArray(uint256 _betId) external view returns(XIVDatabaseLib.IndexCoin[] memory);
    function getBetPriceHistoryMapping(uint256 _betId) external view returns(XIVDatabaseLib.BetPriceHistory memory);
    function getXIVTokenContractAddress() external view returns(address);
    function getAllIndexContractAddressArray(uint256 coinType) external view returns(address[] memory);
    function getIndexMapping(address _ContractAddress, uint256 coinType) external view returns(XIVDatabaseLib.IndexCoin memory);
    
    function getOracleWrapperContractAddress() external view returns(address);
    function getPlentyOneDayPercentage() external view returns(uint256);
    function getPlentyThreeDayPercentage(uint256 _days) external view returns(uint256);
    function getPlentySevenDayPercentage(uint256 _days) external view returns(uint256);
    function getBetsAccordingToUserAddress(address userAddress) external view returns(uint256[] memory);
    function updateBetAddressesArray(address userAddress, uint256 _betId) external;
    function addUserAddressUsedForBetting(address userAddress) external;
    function getUserAddressUsedForBetting() external view returns(address[] memory);
    function getFixedDefiCoinArray() external view returns(XIVDatabaseLib.FixedInfo[] memory);
    function getFixedDefiIndexArray() external view returns(XIVDatabaseLib.FixedInfo[] memory);
    function getMaxStakeXIVAmount() external view returns(uint256);
    function getMinStakeXIVAmount() external view returns(uint256);
    function getBetFactorLP() external view returns(uint256);
    function updateActualAmountStakedByUser(address userAddress, uint256 amount) external;
    function getActualAmountStakedByUser(address userAddress) external view returns(uint256);
    function isDaysAvailable(uint256 _days) external view returns(bool);
    function updateExistingBetCheckMapping(address _userAddress,uint256 _betType, address _BetContractAddress,bool status) external;
    function getExistingBetCheckMapping(address _userAddress,uint256 _betType, address _BetContractAddress) external view returns(bool);
    function updateTotalTransactions(uint256 _totalTransactions) external;
    function getTotalTransactions() external view returns(uint256);
    function getFlexibleDefiCoinTimePeriodArray() external view returns(XIVDatabaseLib.TimePeriod[] memory);
    function getFlexibleIndexTimePeriodArray() external view returns(XIVDatabaseLib.TimePeriod[] memory);
    function getMinLPvalue() external view returns(uint256);
    function getLockingPeriodForLPMapping(address userAddress) external view returns(XIVDatabaseLib.LPLockedInfo memory);
    function updateLockingPeriodForLPMapping(address userAddress, uint256 _amountLocked, uint256 _lockedTimeStamp) external;
    function emitBetDetails(uint256  betId, uint256  status, uint256  betEndTime) external;
    function emitLPEvent(uint256 typeOfLP, address userAddress, uint256 amount, uint256 timestamp) external ;
    function updateIsStakeMapping(address userAddress,bool isStake) external;
    function getIsStakeMapping(address userAddress) external view returns(bool);
    function getAdminAddress() external view returns(address);
    function getMaxLPLimit() external view returns(uint256);
    
}


