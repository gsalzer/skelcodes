pragma solidity 0.4.24;
import "./Modifiers.sol";

/**
** Wrapper for Router Contract to interact with all the functions' signatures
**/

contract Wrapper is Modifiers {

    //ColorTeam.sol
    function distributeCBP() external {}

    //TimeTeam.sol
    function distributeTBP() external {}

    //DividendsDistributor.sol
    function claimDividends() external {}
    function approveClaim(uint _claimId) public {}

    //GameStateController.sol
    function pauseGame() external {}
    function resumeGame() external {}
    function withdrawEther() external returns (bool) {}

    //Referral.sol
    function buyRefLink(string _refLink) external payable {}
    function getReferralsForUser(address _user) external view returns (address[]) {}
    function getReferralData(address _user) external view returns (uint registrationTime, uint moneySpent) {}

    //Roles.sol
    function addAdmin(address _new) external {}
    function removeAdmin(address _admin) external {}
    function renounceAdmin() external {}

    //Game.sol
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint totalCallPrice) {}
    function paint(uint[] _pixels, uint _color, string _refLink) external payable {}
    function drawTimeBank() public {}

    //ERC1538.sol
    function updateContract(address _delegate, string _functionSignatures, string commitMessage) external {}

    //GameMock.sol
    function mock() external {}
    function mock2() external {}
    function mock3(uint _winnerColor) external {}
    function mockMaxPaintsInPool() external {}

    //Helpers.sol
    function getPixelColor(uint _pixel) external view returns (uint) {}
    function addNewColor() external {}

}
