// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract Parameters {
    uint256 public warmUpDuration = 2 days;
    uint256 public activeDuration = 2 days;
    uint256 public queueDuration = 1 days;
    uint256 public gracePeriodDuration = 4 days;

    uint256 public acceptanceThreshold = 60;
    uint256 public minQuorum = 40;

    uint256 constant ACTIVATION_THRESHOLD = 20_000_000 * 10**18;
    uint256 constant PROPOSAL_MAX_ACTIONS = 10;

    modifier onlyDAO() {
        require(msg.sender == address(this), "Only DAO can call");
        _;
    }

    function setWarmUpDuration(uint256 period) public onlyDAO {
        warmUpDuration = period;
    }

    function setActiveDuration(uint256 period) public onlyDAO {
        require(period >= 4 hours, "period must be > 0");
        activeDuration = period;
    }

    function setQueueDuration(uint256 period) public onlyDAO {
        queueDuration = period;
    }

    function setGracePeriodDuration(uint256 period) public onlyDAO {
        require(period >= 4 hours, "period must be > 0");
        gracePeriodDuration = period;
    }

    function setAcceptanceThreshold(uint256 threshold) public onlyDAO {
        require(threshold <= 100, "Maximum is 100.");
        require(threshold > 50, "Minimum is 50.");

        acceptanceThreshold = threshold;
    }

    function setMinQuorum(uint256 quorum) public onlyDAO {
        require(quorum > 5, "quorum must be greater than 5");
        require(quorum <= 100, "Maximum is 100.");

        minQuorum = quorum;
    }
}

