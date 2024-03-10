pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAaveProtoGovernance {
    function submitVoteByVoter(uint256 _proposalId, uint256 _vote, IERC20 _asset) external;
}
