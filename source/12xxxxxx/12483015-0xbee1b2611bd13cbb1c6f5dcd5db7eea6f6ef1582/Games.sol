pragma solidity ^0.5.0;

import "../SafeMath.sol";
import "./GameInterface.sol";


contract Games {
    using SafeMath for int;
    using SafeMath for uint;

    mapping (uint => GameInterface) public games;

    /**
     * @dev constructor
     * @param gameContracts addresses of different game implementations.
     */
    constructor(address[] memory gameContracts) public {
        for (uint i = 0; i < gameContracts.length; i++) {
            // set first GameInterface to 0 0 => start with i + 1
            games[i + 1] = GameInterface(gameContracts[i]);
        }
    }

    /**
     * @dev Returns the max allowed bet for a specific game.
     * @param _gameType game identifier.
     * @param _num game specific bet number.
     * @param _bankRoll bank roll size.
     * @return max allowed bet.
     */
    function maxBet(uint8 _gameType, uint _num, uint _bankRoll) public view returns(uint) {
        uint maxBetVal = getGameImplementation(_gameType).maxBet(_num, _bankRoll);
        return maxBetVal.add(5e14).div(1e15).mul(1e15); // round to multiple of 0.001 Ether
    }

    /**
     * @dev Calculates the result of the bet.
     * @param _gameType game identifier.
     * @param _serverSeed server seed.
     * @param _userSeed user seed.
     * @param _num game specific bet number.
     * @return result number.
     */
    function resultNumber(uint8 _gameType, bytes32 _serverSeed, bytes32 _userSeed, uint _num) public view returns(uint) {
        return getGameImplementation(_gameType).resultNumber(_serverSeed, _userSeed, _num);
    }

    /**
     * @dev Calculates the user profit for the bet.
     * @param _gameType game identifier.
     * @param _num game specific bet number.
     * @param _betValue bet value.
     * @param _resultNum bet result.
     * @return user profit.
     */
    function userProfit(uint8 _gameType, uint _num, uint _betValue, uint _resultNum) public view returns(int) {
        uint betValue = _betValue / 1e9; // convert to gwei

        int res = getGameImplementation(_gameType).userProfit(_num, betValue, _resultNum);

        return res.mul(1e9); // convert to wei
    }

    /**
     * @dev Calculates the maximal posible user profit for the given bet.
     * @param _gameType game identifier.
     * @param _num game specific bet number e.g. 0 or 1 for RollADice.
     * @param _betValue bet value.
     * @return max user profit.
     */
    function maxUserProfit(uint8 _gameType, uint _num, uint _betValue) public view returns(int) {
        uint betValue = _betValue / 1e9; // convert to gwei

        int res = getGameImplementation(_gameType).maxUserProfit(_num, betValue);

        return res.mul(1e9); // convert to wei
    }

    /**
     * @dev Returns the game implementation contract for the given game type.
     * @param _gameType game identifier.
     * @return game implementation contract.
     */
    function getGameImplementation(uint8 _gameType) private view returns(GameInterface) {
        require(games[_gameType] != GameInterface(0), "Invalid game type");
        return games[_gameType];

    }
}

