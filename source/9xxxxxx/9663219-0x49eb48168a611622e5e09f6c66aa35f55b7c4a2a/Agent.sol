pragma solidity ^0.5.10;

import "./Ownable.sol";

/**
 * @title Agent contract - base contract with an agent
 */
contract Agent is Ownable {
    mapping(address => bool) public Agents;

    event UpdatedAgent(address _agent, bool _status);

    modifier onlyAgent() {
        assert(Agents[msg.sender]);
        _;
    }

    function updateAgent(address _agent, bool _status) public onlyOwner {
        assert(_agent != address(0));
        Agents[_agent] = _status;

        emit UpdatedAgent(_agent, _status);
    }
}

