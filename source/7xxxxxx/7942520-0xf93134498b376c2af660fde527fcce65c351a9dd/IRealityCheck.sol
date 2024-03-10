pragma solidity ^0.5.2;

// RealityCheck API used to interract with realit.io, we only need to describe the
// functions we'll be using.
// cf https://raw.githubusercontent.com/realitio/realitio-dapp/master/truffle/contracts/RealityCheck.sol
interface IRealityCheck {
    function askQuestion(
        uint256 template_id, string calldata question,
        address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external returns (bytes32);
    function isFinalized(bytes32 question_id) external view returns (bool);
    function getFinalAnswer(bytes32 question_id) external view returns (bytes32);
    function getOpeningTS(bytes32 question_id) external view returns(uint32);
}

