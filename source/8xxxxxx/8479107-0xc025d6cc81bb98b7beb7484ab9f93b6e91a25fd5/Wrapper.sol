pragma solidity 0.4.24;
import "./Modifiers.sol";

/**
** Wrapper for Router Contract to interact with all the functions' signatures
**/

contract Wrapper is Modifiers {

    //DividendsDistributor.sol
    function withdrawDividends() external returns (bool) {}
    function withdrawFoundersComission() external returns (bool) {}

    //LuckyPot
    function increaseLuckyPot() external payable {}
    function drawLuckyPot(address _user, uint _bankPercent, uint _pixelId) external {}

    //GameStateController.sol
    function pauseGame() external {}
    function resumeGame() external {}
    function withdrawEther() external returns (bool) {}

    //Referral.sol
    function createRefLink(string _refLink) external {}
    function getReferralsForUser(address _user) external view returns (address[]) {}
    function getReferralData(address _user) external view returns (uint registrationTime, uint moneySpent) {}

    //Roles.sol
    function addAdmin(address _new) external {}
    function removeAdmin(address _admin) external {}
    function renounceAdmin() external {}

    //Game.sol
    function setPriceLimitPaints(uint _paintsNumber) external {}
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint totalCallPrice) {}
    function paint(uint[] _pixels, uint _color, string _refLink) external payable {}
    function drawTimeBank() public {}
    function cashBackAmount(address _painter) public view returns(uint cashBackInWei) {}
    function withdrawCashBack() external {}

    //ERC1538.sol
    function updateContract(address _delegate, string _functionSignatures, string commitMessage) external {}

    //GameMock.sol
    function mock() external {}
    function mock2() external {}
    function mock3(uint _winnerColor) external {}
    function mockMaxPaintsInPool() external {}

    //Helpers.sol
    function getUsername(address _painter) external view returns(string username) {}
    function isUsernameExists(string _username) external view returns(bool) {}
    function createUsername(string _username) external {}
    function getPixelColor(uint _pixel) external view returns (uint) {}
    function addNewColor() external {}

}
