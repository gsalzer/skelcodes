// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./libraries/Calculator.sol";
import "./libraries/Elections.sol";
import "./libraries/ElectionsPrincipal.sol";
import "./libraries/Proposals.sol";

import "../InitializableUpgrades.sol";

import "./LUTs.sol";
import "./Voting.sol";
import "./ChainlinkETHUSD.sol";

// solhint-disable ordering
contract ToonTokenV0 is
    ERC20Upgradeable,
    InitializableUpgrades,
    LUTs,
    Voting,
    ChainlinkETHUSD,
    ElectionsPrincipal
{
    /**
     * The price per token (in USD) the next chunk of a token can be purchased at.
     *
     * Tokens are being sold for exponentially growing price per token, as follows:
     * - the first million tokens are sold for $1 per token;
     * - then, the price gradually increases ten times for every doubling of the
     *   token supply, e.g. the 2,000,000'th token costs $10,
     *   the 4,000,000'th token costs $100, etc.
     */
    uint256 public currentPricePerToken;

    /**
     * Shows if there is a consensus about the current maintainer of the contract
     * exists among voters. Consensus is reached when the current maintainer
     * received the majority of votes (>50% of total votes excl. abstained votes);
     * otherwise consensus is broken. Consensus may be updated only during
     * elections initiated by calling either `holdElections()` or
     * `confirmConsensusAndUpdate()` or `breakConsensus()` method.
     *
     * When consensus is broken, the primary market is closed: no new tokens may
     * be purchased.
     *
     * `ConsensusChanged` event is emitted when consensus is being changed.
     *
     * See also: `hasConsensus` modifier
     */
    bool public consensus;

    /**
     * The address of the current maintainer of the contract.
     *
     * The maintainer:
     * - may set the wallet addresses the bonus tokens must be
     *   minted to (see `maintainerWallet` and `bountyWallet`);
     * - may propose the distribution of ethers accumulated at this contract
     *   address (see `proposeDistribution()`);
     * - may propose the new implementation to upgrade this contract to (see
     *   `proposeUpgrade()`).
     *
     * The maintainer is being elected by tokenholders who cast their votes for
     * candidates they prefer. A candidate who received a plurality of votes
     * becomes the new maintainer of the contract. The number of votes is equal
     * to the number of tokens on the balance of each voter at the time the
     * elections are being held.
     *
     * Maintainer cannot be represented by `address(0)`.
     *
     * `MaintainerChanged` event is emitted when this property is being changed.
     *
     * See also: `onlyMaintainer` modifier
     */
    address public maintainer;

    /**
     * The address maintainer bonus tokens must be minted to. This address may be
     * set by the current maintainer of the contract.
     *
     * `MaintainerBonusWalletChanged` is emitted when this address is being
     * changed.
     *
     * See also: `setWallets`
     */
    address public maintainerWallet;

    /**
     * The address bounty bonus tokens must be minted to. This address may be set
     * by the current maintainer of the contract.
     *
     * `BountyBonusWalletChanged` is emitted when this address is being
     * changed.
     *
     * See also: `setWallets`
     */
    address public bountyWallet;

    /**
     * The address proposed by the current maintainer of the contract the
     * `proposedDistributionAmount` of accumulated ethers to be distributed to
     * during the next elections.
     *
     * `DistributionProposed` event is emitted when a new distribution proposal
     * is being published by the current maintainer, or a current proposal
     * is being recalled (in that case, `proposedDistributionAddress` is set to
     * `address(0)`).
     *
     * A distribution proposal is meant to not exist if this address is set to
     * `address(0)`.
     *
     * Ethers distribution may be proposed by the current maintainer, but will be
     * executed during elections if and only if the following conditions are met:
     * 1) the candidate who won the elections is the one who made this proposal
     *    being the maintainer before the elections (i.e. who wins second time
     *    in a row);
     * 2) the consensus about the winner has been reached among voters during
     *    these elections (i.e., the winner received the majority of total votes
     *    excl. abstained votes);
     * 3) enough time has passed since this proposal was published (see
     *    `distributionProposedAt`). "Enough" depends on the number of votes
     *    given for the runner up candidate (see `Proposals.isExecutionAllowed()`
     *    for specific details).
     *
     * During this proposal execution the `proposedDistributionAmount` of ethers
     * is transferred from this contract address to the
     * `proposedDistributionAddress`, and the `ProposedDistributionExecuted`
     * event is emitted.
     *
     * See also: `proposeDistribution`
     */
    address payable public proposedDistributionAddress;

    /**
     * The amount of accumulated ethers proposed by the current maintainer
     * of the contract to be distributed to `proposedDistributionAddress`.
     *
     * Ethers distribution may be proposed by the current maintainer, but will be
     * executed during elections if and only if the following conditions are met:
     * 1) the candidate who won the elections is the one who made this proposal
     *    being the maintainer before the elections (i.e. who wins second time
     *    in a row);
     * 2) the consensus about the winner has been reached among voters during
     *    these elections (i.e., the winner received the majority of total votes
     *    excl. abstained votes);
     * 3) enough time has passed since this proposal was published (see
     *    `distributionProposedAt`). "Enough" depends on the number of votes
     *    given for the runner up candidate (see `Proposals.isExecutionAllowed()`
     *    for specific details).
     *
     * During this proposal execution the `proposedDistributionAmount` of ethers
     * is transferred from this contract address to the
     * `proposedDistributionAddress`, and the `ProposedDistributionExecuted`
     * event is emitted.
     *
     * See also: `proposeDistribution`
     */
    uint256 public proposedDistributionAmount;

    /**
     * The timestamp the distribution of accumulated ethers has been proposed
     * by the current maintainer of the contract at.
     *
     * See also: `proposeDistribution`
     */
    uint256 public distributionProposedAt;

    /**
     * The address with the new implementation proposed by the current
     * maintainer of the contract to upgrade this contract to.
     *
     * `UpgradeProposed` event is emitted when a new upgrade proposal
     * is being published by the current maintainer, or a current proposal
     * is being recalled (in that case, `proposedUpgradeImpl` is set to
     * `address(0)`).
     *
     * An upgrade proposal is meant to not exist if this address is set to
     * `address(0)`.
     *
     * An implementation to upgrade this contract to may be proposed by the
     * current maintainer, but will be executed during elections if and only
     * if the following conditions are met:
     * 1) the candidate who won the elections is the one who made this proposal
     *    being the maintainer before the elections (i.e. who wins second time
     *    in a row);
     * 2) the consensus about the winner has been reached among voters during
     *    these elections (i.e., the winner received the majority of total votes
     *    excl. abstained votes);
     * 3) enough time has passed since this proposal was published (see
     *    `upgradeProposedAt`). "Enough" depends on the number of votes
     *    given for the runner up candidate (see `Proposals.isExecutionAllowed()`
     *    for specific details).
     *
     * During this proposal execution the address of the current implementation
     * (see `ToonTokenProxy._implementation()`) is being replaced with the new
     * `proposedUpgradeImpl` address, then the `initialize()` method of the
     * new implementation contract is being called, and the
     * `ProposedDistributionExecuted` event is being emitted (see
     * `EIP1967Writer._upgradeTo()`).
     *
     * See also: `proposeUpgrade`
     */
    address public proposedUpgradeImpl;

    /**
     * The timestamp the new implementation to upgrade this contract to has been
     * proposed at by the maintainer of the contract at.
     *
     * See also: `proposeUpgrade`
     */
    uint256 public upgradeProposedAt;

    // EVENTS ==================================================================

    /**
     * Emitted when the consensus is being changed during the elections
     */
    event ConsensusChanged(bool newValue);

    /**
     * Emitted when another candidate wins the elections (by getting a plurality
     * of votes given by voters) and becomes the new maintainer of the contract
     */
    event MaintainerChanged(address newValue);

    /**
     * Emitted when the maintainer sets the new address its bonus tokens to
     * be assigned to. This address may be set to `address(0)` - in that case,
     * maintainer bonus tokens won't be minted.
     */
    event MaintainerBonusWalletChanged(address nextMaintainerWallet);

    /**
     * Emitted when the maintainer sets the new address bounty bonus tokens
     * to be assigned to. This address may be set to `address(0)` - in that case,
     * bounty bonus tokens won't be minted.
     */
    event BountyBonusWalletChanged(address nextBountyWallet);

    /**
     * Emitted when a new distribution proposal is being published by the current
     * maintainer. If `nextProposedDistributionAddress` is set to `address(0)`,
     * the previous proposal is being recalled.
     */
    event DistributionProposed(
        address payable nextProposedDistributionAddress,
        uint256 nextProposedDistributionAmount
    );

    /**
     * Emitted when a new upgrade proposal is being published by the current
     * maintainer. If `nextProposedUpgradeImpl` is set to `address(0)`,
     * the previous proposal is being recalled.
     */
    event UpgradeProposed(address nextProposedUpgradeImpl);

    /**
     * Emitted when the distribution proposal has been successfully executed,
     * meaning the `amount` of accumulated ethers has been transferred to `recipient`.
     */
    event ProposedDistributionExecuted(uint256 amount, address recipient);

    /**
     * Emitted when the upgrade proposal has been successfully executed, meaning
     * the current implementation address (see `EIP1967Reader._getImplementation()`)
     * has been replaced with the `newImplementation` and the `initialize()`
     * method of the new implementation has been called (see `EIP1967Writer._upgradeTo()`)
     */
    event ProposedUpgradeExecuted(address newImplementation);

    // MODIFIERS ===============================================================

    /**
     * Restricts access by the current maintainer of the contract.
     */
    function _onlyMaintainer() private view {
        require(_msgSender() == maintainer, "only maintainer");
    }

    /**
     * Restricts access by the current maintainer of the contract.
     */
    modifier onlyMaintainer() {
        _onlyMaintainer();
        _;
    }

    /**
     * Restricts access when the consensus about the current maintainer of the
     * contract among voters is broken.
     */
    function _hasConsensus() private view {
        require(consensus == true, "community must reach consensus");
    }

    /**
     * Restricts access when the consensus about the current maintainer of the
     * contract among voters is broken.
     */
    modifier hasConsensus() {
        _hasConsensus();
        _;
    }

    // SETUP ===================================================================

    /**
     * This method is called by the proxy contract during its deployment process
     * (see `ToonTokenProxy.constructor()`).
     */
    function initialize()
        external
        virtual
        override
        initializer
        implementationInitializer
    {
        __ToonTokenV0_init();
    }

    /**
     * Initializes the internal state of the contract, chained with parent
     * initializers.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __ToonTokenV0_init()
        internal
        initializer
        implementationInitializer
    {
        __ERC20_init("ToonToken", "TOON");
        __ToonTokenV0_init_unchained();
    }

    /**
     * Initializes the internal state of the contract.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __ToonTokenV0_init_unchained()
        internal
        initializer
        implementationInitializer
    {
        consensus = true;
    }

    // VOTING ==================================================================

    /**
     * Allows a tokenholder to announce its decision to cast its votes
     * for the given `candidate` for the maintainer.
     *
     * The number of votes is equal to the number of tokens on the balance of
     * each voter at the time the elections are being held. A candidate who
     * received a plurality of votes during the elections becomes the new
     * maintainer of the contract.
     *
     * A voter who decides to cast its votes for `address(0)` is treated as
     * an abstained voter.
     */
    function vote(address candidate) external {
        require(votesOf(_msgSender()) > 0, "voting for tokenholders");

        _vote(_msgSender(), candidate);
    }

    /**
     * Returns the address of the candidate a `voter` decided to cast its
     * votes for.
     * A zero address (`address(0)`) indicates a voter either didn't announced
     * its decision or decided to abstain.
     */
    function candidateOf(address voter) public view override returns (address) {
        return _votersDecisions[voter];
    }

    // ELECTIONS ===============================================================

    /**
     * Holds the elections for the maintainer of the contract, updates the
     * consensus, and executes the proposals (if there are any published by the
     * current maintainer and if the consensus is reached).
     *
     * A maintainer is being elected by tokenholders who cast their votes for
     * candidates they prefer. A winner, i.e a candidate who received a
     * plurality of votes, becomes the new maintainer of the contract.
     * The number of votes is equal to the number of tokens on the balance of
     * each voter at the time the elections are being held.
     *
     * Consensus is reached when the winner received the majority of votes
     * (>50% of total votes excl. abstained votes); otherwise consensus is broken.
     * In case when consensus is broken, only a winning candidate is allowed to
     * call this method to reach the consensus it again.
     *
     * The total number of votes does not contain votes given for `address(0)`.
     *
     * Distribution and (or) upgrade proposals are executed if and only if
     * the following conditions are met:
     * 1) the candidate who won the elections is the one who made these proposals
     *    being the maintainer before the elections (i.e. who wins second time
     *    in a row);
     * 2) the consensus about the winner has been reached among voters during
     *    these elections (i.e., the winner received the majority of total votes
     *    excl. abstained votes);
     * 3) enough time has passed since this proposal was published. "Enough"
     *    depends on the number of votes given for the runner up candidate
     *    (see `Proposals.isExecutionAllowed()` for specific details).
     *
     * May emit any of the following events:
     * - `ConsensusChanged`,
     * - `MaintainerChanged`,
     * - `ProposedDistributionExecuted`,
     * - `ProposedUpgradeExecuted`.
     *
     *
     * Technical considerations
     *
     * We decided to store the decision of each voter rather than an aggregated
     * votes for each candidate to keep transactional costs as low as possible:
     * postponing vote aggregation until elections helped us to avoid
     * costy balancing of the votes during token transfers.
     *
     * To hold the elections, we need to find the winner and the number of
     * votes given for it, the number of votes given for the runner up candidate,
     * and the total number of votes (excl. abstained votes cast for `address(0)`).
     * To make this happen:
     * 1. we iterate through the list of voters, and for every voter with
     *    positive balance who cast its vote for anyone but `address(0)`,
     *    we add its candidate to the temporary (in-memory) array of candidates, and
     *    add its balance to the corresponding element in the temporary (in-memory)
     *    array of votes given for each found candidate;
     * 2. then we iterate through this temporary array of candidates,
     *    - summing the total number of votes for all candidates,
     *    - finding the TOP-2 candidates by the number of given votes on the fly.
     *
     * See `Elections.findTop2()` for details.
     *
     * Since we are limited by max gas per block (currently, 30M of gas), this
     * method can handle no more than ≈2,500 voters. To get around this
     * limitation, see `confirmConsensusAndUpdate` and `breakConsensus` methods
     * that accept offchain-ordered lists of top voters.
     */
    function holdElectionsAndUpdate() external {
        (
            address winningCandidate,
            uint256 winningCandidateVotes,
            uint256 runnerUpCandidateVotes,
            uint256 totalVotes
        ) = Elections.findTop2(_voters, ElectionsPrincipal(this));

        bool newConsensus = Elections.calcConsensus(
            winningCandidateVotes,
            totalVotes
        );

        // only the expected maintainer may allow a broken consensus to be restored
        if (false == consensus && true == newConsensus) {
            require(
                msg.sender == winningCandidate,
                "only a winner can allow consensus to be restored"
            );
        }

        _finishElections(
            newConsensus,
            winningCandidate,
            runnerUpCandidateVotes,
            totalVotes
        );
    }

    /**
     * Holds the elections for the maintainer of the contract if and only if
     * the expected `winningCandidate` receives the majority of votes (>50%
     * of total votes excl. abstained votes), marks the consensus as reached,
     * and executes the proposals (if there are any published by the current
     * maintainer).
     *
     * In case when consensus is broken, only a winning candidate is allowed to
     * call this method to reach the consensus it again.
     *
     * The number of votes is equal to the number of tokens on the balance of
     * each voter at the time the elections are being held.
     *
     * The total number of votes here is equal to the total supply of tokens;
     * the abstained votes are determined by summing the number of tokens on the
     * balance of each member of `abstainedVoters` who have cast its votes
     * for `address(0)`;
     * the votes given for the `winningCandidate` are determined by summing the
     * number of tokens on the balance of each member of `voters` who have
     * cast its votes for `winningCandidate`.
     *
     *
     * Distribution and (or) upgrade proposals are executed if and only if
     * the following conditions are met:
     * 1) the candidate who won the elections is the one who made this proposal
     *    being the maintainer before the elections (i.e. who wins second time
     *    in a row);
     * 2) the consensus about the winner has been reached among voters during
     *    these elections (i.e., the winner received the majority of total votes
     *    excl. abstained votes);
     * 3) enough time has passed since this proposal was published. "Enough"
     *    depends on the number of votes given for the runner up candidate
     *    (see `Proposals.isExecutionAllowed()` for specific details).
     *
     * May emit any of the following events:
     * - `ConsensusChanged`,
     * - `MaintainerChanged`,
     * - `ProposedDistributionExecuted`,
     * - `ProposedUpgradeExecuted`.
     *
     *
     * The rationale for this function is to safely get around the limitation of
     * `holdElectionsAndUpdate` method which can handle no more than ≈2,500 voters
     * due to gas limit. It accepts an offchain-ordered list of top voters voted
     * for the winning candidate, and an offchain-ordered list of top abstained
     * voters, so only the necessary minimum number of voters is enough to be
     * provided to prove the consensus.
     *
     * For example, if there are 1000 tokens distributed across 100 tokenholders,
     * and among them there are two abstained voters (i.e. voters who have cast
     * their votes for `address(0)`) holding 99 tokens on their balances,
     * and there are ten voters holding 451 tokens who have cast their
     * votes for the given `winningCandidate`, then it is possible to call this
     * function providing `winningCandidate` as the first argument,
     * the ordered list of these ten voters as the second argument,
     * and the ordered list of these two abstained voters as the third argument
     * to successfully hold the elections, because the winner gets _at least_:
     *  451 / (1000 - 99) = 50.055%
     * of total votes, meaning that consensus about the `winningCandidate` is
     * reached.
     *
     * As for the share of votes given for the runner up candidate (which is used to
     * determine the possibility of proposals execution, see
     * `Proposals.isExecutionAllowed()` for details): since it is not possible
     * to pass the onchain-verifiable list of voters who cast their votes for
     * the runner up candidate, we rely on the worst-case scenario assuming that
     * all other possible votes (not covered by the provided lists) are cast for
     * the runner up candidate.
     * In the example above, it is assumed that runner up has been given
     *  1000 - (451 + 99) = 450 votes, or
     *  (1000 - (451 + 99)) / (1000 - 99) = 49.9%
     * of total votes.
     *
     *
     * Security considerations:
     * - first, this function accepts only ordered arrays to ensure their
     *   elements are unique within each;
     * - second, this function DOES NOT rely on offchain data by far, reading
     *   each provided voter's decision directly from this contract storage;
     * - third, this function accepts only consensus-positive resolution as this
     *   is the only way to avoid spoofing (by providing the incomplete list
     *   of voters); otherwise, this function does nothing.
     *
     * In this case possible attack vectors are prevented by design:
     * - providing less voters than possible just tightens conditions until
     *   they prevent this function to work; provide less voters and you get
     *   less votes, execution is not possible;
     * - provide more voters who cast their votes for the wrong candidate, and
     *   this function would skip them while reading their decisions from the
     *   storage.
     *
     * Since this function can only confirm consensus, there is an inverse method
     * dedicated for breaking consensus: see `breakConsensus`.
     *
     * @param winningCandidate the winning candidate who is expected to become a maintainer
     * @param voters the offchain-ordered list of voters who are expected to cast the majority of votes for the `winningCandidate`
     * @param abstainedVoters the offchain-ordered list of voters who are expected to cast their votes for `address(0)`
     */
    function confirmConsensusAndUpdate(
        address winningCandidate,
        address[] memory voters,
        address[] memory abstainedVoters
    ) external {
        // sum votes given for the winningCandidate
        uint256 winningCandidateVotes = Elections.sumVotesFor(
            winningCandidate,
            voters,
            ElectionsPrincipal(this)
        );

        // sum votes given for address(0)
        uint256 abstainedVotes = Elections.sumVotesFor(
            address(0),
            abstainedVoters,
            ElectionsPrincipal(this)
        );

        // total votes = supply - abstained votes
        uint256 totalVotes = totalSupply() - abstainedVotes;

        // expect the sum of votes for the winning candidate > 50% of total votes
        // (excl. abstained votes)
        // otherwise we can guarantee nothing and so do nothing
        if (Elections.calcConsensus(winningCandidateVotes, totalVotes)) {
            // only the expected maintainer may allow a broken consensus to be restored
            if (false == consensus) {
                require(
                    msg.sender == winningCandidate,
                    "only a winner can allow consensus to be restored"
                );
            }

            // assuming the worst-case scenario: all other votes has been given
            // for the runner up candidate
            uint256 runnerUpCandidateVotes = totalVotes - winningCandidateVotes;
            _finishElections(
                true,
                winningCandidate,
                runnerUpCandidateVotes,
                totalVotes
            );
        }
    }

    /**
     * Breaks the consensus if and only if the majority of votes (>50% of total
     * votes excl. abstained votes) were given for anyone but the current
     * maintainer.
     *
     * The number of votes is equal to the number of tokens on the balance of
     * each voter at the time the elections are being held.
     *
     * The total number of votes here is equal to the total supply of tokens;
     * the abstained votes are determined by summing the number of tokens on the
     * balance of each member of `abstainedVoters` who have cast its votes
     * for `address(0)`;
     * the votes given for anyone but the current maintainer or `address(0)` are
     *  determined by summing the number of tokens on the balance of each member
     * of `alternativeCandidateVoters` who have cast its votes for anyone
     * but the current maintainer or `address(0)`.
     *
     * May emit `ConsensusChanged`.
     *
     *
     * The rationale for this function is to safely get around the limitation of
     * `holdElectionsAndUpdate` method which can handle no more than ≈2,500 voters
     * due to gas limit. Since `confirmConsensusAndUpdate` may only confirm
     * consensus, this function implements a integral and way to break it.
     * It is obvious that consensus is broken when the maintainer looses
     * the majority of votes, which means that >50% of votes are given for
     * anyone else. This function accepts an offchain-ordered list of top voters
     * who cast their votes for anyone but the current maintainer, and an
     * offchain-ordered list of top abstained voters, so only the necessary
     * minimum number of voters is enough to be provided to break the consensus.
     *
     * For example, if there are 1000 tokens distributed among 100 tokenholders,
     * and among them there are two abstained voters (i.e. voters who have cast
     * their votes for `address(0)`) holding 99 tokens on their balances,
     * and there are ten voters holding 451 tokens who have cast their votes
     * for ANYONE but the current maintainer, then it is possible to call this
     * function providing the ordered list of these ten voters as the first
     * argument, and the ordered list of these two abstained voters as the second
     * argument to successfully break the consensus, because we can verify that:
     *  451 / (1000 - 99) = 50.055%
     * of total votes are not cast for the current maintainer.
     *
     *
     * Security considerations:
     * - first, this function accepts only ordered arrays to ensure their
     *   elements are unique within each;
     * - second, this function DOES NOT rely on offchain data by far, reading
     *   each provided voter's decision directly from this contract storage;
     * - third, this function accepts only consensus-breaking resolution as this
     *   is the only way to avoid spoofing (by providing the incomplete list
     *   of voters); otherwise, this function does nothing.
     *
     * In this case possible attack vectors are prevented by design:
     * - providing less voters than possible just tightens conditions until
     *   they prevent this function to work; provide less voters and you get
     *   less votes, execution is not possible;
     * - provide more voters who cast their votes for the wrong candidate, and
     *   this function would skip them while reading their decisions from the
     *   storage.
     *
     * Since this function can only break consensus, there is an inverse function
     * dedicated for confirming consensus: `confirmConsensusAndUpdate`.
     *
     * @param alternativeCandidateVoters the offchain-ordered list of voters who are expected to cast the majority of votes for anyone but the current maintainer or `address(0)`
     * @param abstainedVoters the offchain-ordered list of voters who are expected to cast their votes for `address(0)`
     */
    function breakConsensus(
        address[] memory alternativeCandidateVoters,
        address[] memory abstainedVoters
    ) external hasConsensus {
        // sum votes given for anyone but the current maintainer AND address(0)
        uint256 votes = Elections.sumVotesExceptZeroAnd(
            maintainer,
            alternativeCandidateVoters,
            ElectionsPrincipal(this)
        );

        // sum votes given for address(0)
        uint256 abstainedVotes = Elections.sumVotesFor(
            address(0),
            abstainedVoters,
            ElectionsPrincipal(this)
        );

        // total votes = supply - abstained votes
        uint256 totalVotes = totalSupply() - abstainedVotes;

        if (Elections.calcConsensus(votes, totalVotes)) {
            // we just break the consensus, nothing more because anything else
            // cannot be proved from the data provided.
            _finishElections(false, maintainer, votes, totalVotes);
        }
    }

    /**
     * Performs changes caused by successful elections
     */
    function _finishElections(
        bool newConsensus,
        address winningCandidate,
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        // consensus has changed?
        if (consensus != newConsensus) {
            consensus = newConsensus;
            emit ConsensusChanged(newConsensus);
        }

        // maintainer has changed? Note that when the maintainer is being
        // replaced, its proposals are removed
        if (maintainer != winningCandidate) {
            _dropProposals();
            maintainer = winningCandidate;
            emit MaintainerChanged(winningCandidate);
        }

        // execute proposals if consensus is reached
        if (consensus) {
            _performProposedDistribution(runnerUpCandidateVotes, totalVotes);
            _performProposedUpgrade(runnerUpCandidateVotes, totalVotes);
        }
    }

    /**
     * Performs distribution proposal (if set) if the following conditions are met:
     * - consensus is reached;
     * - enough time has passed since each proposal was published.
     *
     * Emits `ProposedDistributionExecuted` on success.
     */
    function _performProposedDistribution(
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        if (
            consensus &&
            proposedDistributionAddress != address(0) &&
            Proposals.isExecutionAllowed(
                distributionProposedAt,
                runnerUpCandidateVotes,
                totalVotes
            )
        ) {
            address payable recipient = proposedDistributionAddress;
            uint256 amount = proposedDistributionAmount;

            // avoid reentrance vulnerability - first nullify...
            proposedDistributionAddress = payable(0);
            proposedDistributionAmount = 0;

            // ...then transfer
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "proposed distribution failed");

            emit ProposedDistributionExecuted(amount, recipient);
        }
    }

    /**
     * Performs upgrade proposal (if set) if the following conditions are met:
     * - consensus is reached;
     * - enough time has passed since each proposal was published.
     *
     * Emits `ProposedUpgradeExecuted` on success
     */
    function _performProposedUpgrade(
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) private {
        if (
            consensus &&
            proposedUpgradeImpl != address(0) &&
            Proposals.isExecutionAllowed(
                upgradeProposedAt,
                runnerUpCandidateVotes,
                totalVotes
            )
        ) {
            address impl = proposedUpgradeImpl;
            proposedUpgradeImpl = address(0);

            _upgradeTo(impl);
            emit ProposedUpgradeExecuted(impl);
        }
    }

    // MAINTAINER ==============================================================

    /**
     * The current maintainer may set wallet addresses bonus tokens will be minted to.
     * If any of these wallets is set to `address(0)`, a respective bonus
     * is not minted.
     *
     * See `_purchaseAndVote` for the details on how bonuses are minted.
     */
    function setWallets(address nextMaintainerWallet, address nextBountyWallet)
        external
        onlyMaintainer
    {
        if (maintainerWallet != nextMaintainerWallet) {
            maintainerWallet = nextMaintainerWallet;
            emit MaintainerBonusWalletChanged(maintainerWallet);
        }

        if (bountyWallet != nextBountyWallet) {
            bountyWallet = nextBountyWallet;
            emit BountyBonusWalletChanged(bountyWallet);
        }
    }

    /**
     * The current maintainer may propose to distribute a `nextProposedDistributionAmount`
     * of ethers (accumulated at this contract address) to `nextProposedDistributionAddress`.
     * Setting `nextProposedDistributionAddress` to `address(0)` removes the existing
     * proposal (if any). The maintainer cannot propose to distribute more
     * ethers than the amount of ethers accumulated at this contract address.
     *
     * Ethers distribution may be proposed by the current maintainer, but will be
     * executed during elections if and only if the following conditions are met:
     * 1) the candidate who won the elections is the one who made this proposal
     *    being the maintainer before the elections (i.e. who wins second time
     *    in a row);
     * 2) the consensus about the winner has been reached among voters during
     *    these elections (i.e., the winner received the majority of total votes
     *    excl. abstained votes);
     * 3) enough time has passed since this proposal was published (see
     *    `distributionProposedAt`). "Enough" depends on the number of votes
     *    given for the runner up candidate (see `Proposals.isExecutionAllowed()`
     *    for specific details).
     */
    function proposeDistribution(
        address payable nextProposedDistributionAddress,
        uint256 nextProposedDistributionAmount
    ) external onlyMaintainer {
        require(
            address(this).balance >= nextProposedDistributionAmount,
            "too much"
        );

        proposedDistributionAddress = nextProposedDistributionAddress;
        proposedDistributionAmount = nextProposedDistributionAmount;
        distributionProposedAt = block.timestamp;

        emit DistributionProposed(
            proposedDistributionAddress,
            proposedDistributionAmount
        );
    }

    /**
     * The current maintainer may propose to upgrade this contract implementation
     * to `nextProposedUpgradeImpl`. Setting `nextProposedUpgradeImpl`
     * to `address(0)` removes the existing proposal (if any).
     *
     * An implementation to upgrade this contract to may be proposed by the
     * current maintainer, but will be executed during elections if and only
     * if the following conditions are met:
     * 1) the candidate who won the elections is the one who made this proposal
     *    being the maintainer before the elections (i.e. who wins second time
     *    in a row);
     * 2) the consensus about the winner has been reached among voters during
     *    these elections (i.e., the winner received the majority of total votes
     *    excl. abstained votes);
     * 3) enough time has passed since this proposal was published (see
     *    `upgradeProposedAt`). "Enough" depends on the number of votes
     *    given for the runner up candidate (see `Proposals.isExecutionAllowed()`
     *    for specific details).
     */
    function proposeUpgrade(address nextProposedUpgradeImpl)
        external
        onlyMaintainer
    {
        proposedUpgradeImpl = nextProposedUpgradeImpl;
        upgradeProposedAt = block.timestamp;
        emit UpgradeProposed(proposedUpgradeImpl);
    }

    /**
     * Nullifies all (if any) proposals published by the current maintainer.
     * This is important when a new candidate becomes the current
     * maintainer: in this case, all proposals published by the previous
     * maintainer must be nullified.
     */
    function _dropProposals() private {
        proposedDistributionAddress = payable(0);
        proposedUpgradeImpl = address(0);
    }

    // PURCHASES ===============================================================

    /**
     * Returns the number of votes the `account` has.
     *
     * The number of votes is equal to the number of tokens on the balance of
     * each voter.
     */
    function votesOf(address account) public view override returns (uint256) {
        return balanceOf(account);
    }

    /**
     * Works the same way as the `purchase()` method: mints tokens for all
     * received ethers (converted to USD using the exchange rate taken from
     * Chainlink's ETHUSD data feed) and assigns them the caller's account,
     * increasing total supply, AND ADDITIONALLY implicitly alters the caller's
     * voting decision making it cast its votes for the current maintainer (but
     * only if there is no decision so far and its resulting balance
     * is greater than 1000 tokens).
     * The number of votes is equal to the number of tokens on the balance of
     * the voter at the time the elections are being held.
     */
    receive() external payable hasConsensus {
        address buyer = _msgSender();
        _purchase(buyer, _convertEthToUsd(msg.value));

        // implicitly alter this buyer's decision only if he is abstained
        // AND his balance > 1000 tokens
        if (
            candidateOf(buyer) == address(0) &&
            balanceOf(buyer) > (1000 * 10**decimals())
        ) {
            _vote(buyer, maintainer);
        }
    }

    /**
     * Mints tokens for all received ethers (converted to USD using the
     * exchange rate taken from Chainlink's ETHUSD data feed)
     * and assigns them the caller's account, increasing total supply.
     *
     * The amount of tokens that can be bought for the given amount of USD in ethers
     * is determined according to exponentially growing price per token, as follows:
     * - the first million tokens are sold for $1 per token;
     * - then, the price gradually increases ten times for every doubling of the
     *   token supply, e.g. the 2,000,000'th token costs $10,
     *   the 4,000,000'th token costs $100, etc.
     *
     * Additionally, maintainer bonus tokens and bounty bonus tokens are being
     * minted and assigned to `maintainerWallet` and `bountyWallet` respectively
     * increasing total supply after the current price per token crosses $10
     * and $20 respectively and only if these wallets are set.
     * The amount of each bonus tokens to be minted is 1/10 of purchased tokens.
     *
     * See `Calculator.calcTokens()` and `LUTsLoader` for details.
     */
    function purchase() external payable hasConsensus {
        _purchase(_msgSender(), _convertEthToUsd(msg.value));
    }

    /**
     * Works the same way as the `purchase()` method: mints tokens for all
     * received ethers (converted to USD using the exchange rate taken from
     * Chainlink's ETHUSD data feed) and assigns them the caller's account,
     * increasing total supply, AND ADDITIONALLY allows the caller to explicitly
     * alter its decision to cast its votes for the current maintainer.
     * The number of votes is equal to the number of tokens on the balance of
     * the voter at the time the elections are being held. Specifying
     * `address(0)` as a `candidate` means that voter decided to abstain.
     *
     * @param candidate the candidate for the maintainer the caller decides to cast its votes for
     */
    function purchaseAndVote(address candidate) external payable hasConsensus {
        _purchase(_msgSender(), _convertEthToUsd(msg.value));
        _vote(_msgSender(), candidate);
    }

    /**
     * Mints the amount of tokens that can be bought for `usdAmount` according
     * to exponentially growing price per token, and assigns them to
     * the `account`, increasing total supply.
     *
     * Maintainer bonus tokens and bounty bonus tokens are minted (if allowed
     * by `calcMaintainerBonus` and `calcBountyBonus`* flags respectively)
     * increasing total supply after the current price per token crosses
     * $10 (see `Calculator.MAINTAINER_BONUS_PRICE_THRESHOLD`) and $20 (see
     * `Calculator.BOUNTY_BONUS_PRICE_THRESHOLD`) respectively,
     * and each bonus is 1/10 of purchased tokens.
     *
     * The amount of tokens that can be bought for the given amount of USD in ethers
     * is determined according to exponentially growing price per token (in USD):
     * - the first million tokens are sold for $1 per token;
     * - then, the price gradually increases ten times for every doubling of the
     *   token supply, e.g. the 2,000,000'th token costs $10,
     *   the 4,000,000'th token costs $100, etc.
     *
     * See `Calculator.calcTokens` and `LUTsLoader` for details.
     */
    function _purchase(address account, uint256 usdAmount) internal {
        require(account != address(0), "purchase from the zero address");
        require(usdAmount > 0, "no funds");

        Calculator.Result memory r = Calculator.calcTokens(
            usdAmount,
            totalSupply(),
            _nodeId,
            address(0) == maintainerWallet,
            address(0) == bountyWallet,
            _supplyLUT,
            _priceLUT
        );

        _nodeId = r.nextNodeId;
        currentPricePerToken = r.nextPricePerToken;

        _mint(account, r.tokensAmount);

        if (r.maintainerBonusTokensAmount > 0)
            _mintMaintainerBonus(r.maintainerBonusTokensAmount);

        if (r.bountyBonusTokensAmount > 0)
            _mintBountyBonus(r.bountyBonusTokensAmount);
    }

    /**
     * Called when the `amount` of maintainer bonus tokens must be minted.
     *
     * This method mints the `amount` of tokens and assigns them to the
     * `maintainerWallet`.
     */
    function _mintMaintainerBonus(uint256 amount) internal virtual {
        _mint(maintainerWallet, amount);
    }

    /**
     * Called when the `amount` of bounty bonus tokens must be minted.
     *
     * Mints the `amount` of tokens and assigns them to `bountyWallet`.
     */
    function _mintBountyBonus(uint256 amount) internal virtual {
        _mint(bountyWallet, amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[40] private __gap;
}

