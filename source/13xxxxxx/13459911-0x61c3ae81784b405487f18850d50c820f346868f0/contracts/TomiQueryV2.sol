// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.1;

import "hardhat/console.sol";

struct Config {
        uint minValue;
        uint maxValue;
        uint maxSpan;
        uint value;
        uint enable;  // 0:disable, 1: enable
    }

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface ITomiConfig {
    function tokenCount() external view returns(uint);
    function tokenList(uint index) external view returns(address);
    function getConfigValue(bytes32 _name) external view returns (uint);
    function configs(bytes32 name) external view returns(Config memory);
    function tokenStatus(address token) external view returns(uint);
}

interface ITomiPlatform {
    function existPair(address tokenA, address tokenB) external view returns (bool);
    function swapPrecondition(address token) external view returns (bool);
    function getReserves(address tokenA, address tokenB) external view returns (uint256, uint256);
}

interface ITomiFactory {
    function getPair(address tokenA, address tokenB) external view returns(address);
}

interface ITomiDelegate {
    function getPlayerPairCount(address player) external view returns(uint);
    function playerPairs(address user, uint index) external view returns(address);
}

interface ITomiLP {
    function tokenA() external view returns (address);
    function tokenB() external view returns (address);
}

interface ITomiPair {
    function token0() external view returns(address);
    function token1() external view returns(address);
    function getReserves() external view returns(uint, uint, uint);
    function lastMintBlock(address user) external view returns(uint); 
}

interface ITomiGovernance {
    function ballotCount() external view returns(uint);
    function rewardOf(address ballot) external view returns(uint);
    function tokenBallots(address ballot) external view returns(address);
    function ballotTypes(address ballot) external view returns(uint);
    function revenueBallots(uint index) external view returns(address);
    function ballots(uint index) external view returns(address);
    function balanceOf(address owner) external view returns (uint);
    function ballotOf(address ballot) external view returns (uint);
    function allowance(address owner) external view returns (uint);
    function configBallots(address ballot) external view returns (bytes32);
    function stakingSupply() external view returns (uint);
    function collectUsers(address ballot, address user) external view returns(uint);
    function ballotRevenueCount() external view returns (uint);
}

interface ITomiBallot {
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }
    function subject() external view returns(string memory);
    function content() external view returns(string memory);
    function createTime() external view returns(uint);
    function endTime() external view returns(uint);
    function executionTime() external view returns(uint);
    function result() external view returns(bool);
    function proposer() external view returns(address);
    function proposals(uint index) external view returns(uint);
    function ended() external view returns (bool);
    function value() external view returns (uint);
    function voters(address user) external view returns (Voter memory);
}

interface ITomiBallotRevenue {
    struct Participator {
        uint256 weight; // weight is accumulated by delegation
        bool participated; // if true, that person already voted
        address delegate; // person delegated to
    }
    function subject() external view returns(string memory);
    function content() external view returns(string memory);
    function createTime() external view returns(uint);
    function endTime() external view returns(uint);
    function executionTime() external view returns(uint);
    function proposer() external view returns(address);
    function proposals(uint index) external view returns(uint);
    function ended() external view returns (bool);
    function participators(address user) external view returns (Participator memory);
    function total() external view returns(uint256);
}

interface ITomiTransferListener {
    function pairWeights(address pair) external view returns(uint);
}

pragma experimental ABIEncoderV2;

contract TomiQuery2 {
    bytes32 public constant PRODUCE_TGAS_RATE = bytes32('PRODUCE_TGAS_RATE');
    bytes32 public constant SWAP_FEE_PERCENT = bytes32('SWAP_FEE_PERCENT');
    bytes32 public constant LIST_TGAS_AMOUNT = bytes32('LIST_TGAS_AMOUNT');
    bytes32 public constant UNSTAKE_DURATION = bytes32('UNSTAKE_DURATION');
    bytes32 public constant REMOVE_LIQUIDITY_DURATION = bytes32('REMOVE_LIQUIDITY_DURATION');
    bytes32 public constant TOKEN_TO_TGAS_PAIR_MIN_PERCENT = bytes32('TOKEN_TO_TGAS_PAIR_MIN_PERCENT');
    bytes32 public constant LIST_TOKEN_FAILURE_BURN_PRECENT = bytes32('LIST_TOKEN_FAILURE_BURN_PRECENT');
    bytes32 public constant LIST_TOKEN_SUCCESS_BURN_PRECENT = bytes32('LIST_TOKEN_SUCCESS_BURN_PRECENT');
    bytes32 public constant PROPOSAL_TGAS_AMOUNT = bytes32('PROPOSAL_TGAS_AMOUNT');
    bytes32 public constant VOTE_DURATION = bytes32('VOTE_DURATION');
    bytes32 public constant VOTE_REWARD_PERCENT = bytes32('VOTE_REWARD_PERCENT');
    bytes32 public constant PAIR_SWITCH = bytes32('PAIR_SWITCH');
    bytes32 public constant TOKEN_PENGDING_SWITCH = bytes32('TOKEN_PENGDING_SWITCH');
    bytes32 public constant TOKEN_PENGDING_TIME = bytes32('TOKEN_PENGDING_TIME');

    address public configAddr;
    address public platform;
    address public factory;
    address public owner;
    address public governance;
    address public transferListener;
    address public delegate;

    uint public T_REVENUE = 5;
    
    struct Proposal {
        address proposer;
        address ballotAddress;
        address tokenAddress;
        string subject;
        string content;
        uint proposalType;
        uint createTime;
        uint endTime;
        uint executionTime;
        bool end;
        bool result;
        uint YES;
        uint NO;
        uint totalReward;
        uint ballotType;
        uint weight;
        bool minted;
        bool voted;
        uint voteIndex;
        bool audited;
        uint value;
        bytes32 key;
        uint currentValue;
    }

    struct RevenueProposal {
        address proposer;
        address ballotAddress;
        address tokenAddress;
        string subject;
        string content;
        uint createTime;
        uint endTime;
        uint executionTime;
        uint total;
        bool end;
        uint totalReward;
        uint ballotType;
        uint weight;
        bool minted;
        bool participated;
        bool audited;
    }
    
    struct Token {
        address tokenAddress;
        string symbol;
        uint decimal;
        uint balance;
        uint allowance;
        uint allowanceGov;
        uint status;
        uint totalSupply;
    }
    
    struct Liquidity {
        address pair;
        address lp;
        uint balance;
        uint totalSupply;
        uint lastBlock;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function upgrade(address _config, address _platform, address _factory, address _governance, address _transferListener, address _delegate) public {
        require(owner == msg.sender);
        configAddr = _config;
        platform = _platform;
        factory = _factory;
        governance = _governance;
        transferListener = _transferListener;
        delegate = _delegate;
    }
   
    function queryTokenList() public view returns (Token[] memory token_list) {
        uint count = ITomiConfig(configAddr).tokenCount();
        if(count > 0) {
            token_list = new Token[](count);
            for(uint i = 0;i < count;i++) {
                Token memory tk;
                tk.tokenAddress = ITomiConfig(configAddr).tokenList(i);
                tk.symbol = IERC20(tk.tokenAddress).symbol();
                tk.decimal = IERC20(tk.tokenAddress).decimals();
                tk.balance = IERC20(tk.tokenAddress).balanceOf(msg.sender);
                tk.allowance = IERC20(tk.tokenAddress).allowance(msg.sender, delegate);
                tk.allowanceGov = IERC20(tk.tokenAddress).allowance(msg.sender, governance);
                tk.status = ITomiConfig(configAddr).tokenStatus(tk.tokenAddress);
                tk.totalSupply = IERC20(tk.tokenAddress).totalSupply();
                token_list[i] = tk;
            }
        }
    }

    function countTokenList() public view returns (uint) {
        return ITomiConfig(configAddr).tokenCount();
    }

    function iterateTokenList(uint _start, uint _end) public view returns (Token[] memory token_list) {
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        uint count = ITomiConfig(configAddr).tokenCount();
        if(count > 0) {
            if (_end > count) _end = count;
            count = _end - _start;
            token_list = new Token[](count);
            uint index = 0;
            for(uint i = _start; i < _end; i++) {
                Token memory tk;
                tk.tokenAddress = ITomiConfig(configAddr).tokenList(i);
                tk.symbol = IERC20(tk.tokenAddress).symbol();
                tk.decimal = IERC20(tk.tokenAddress).decimals();
                tk.balance = IERC20(tk.tokenAddress).balanceOf(msg.sender);
                tk.allowance = IERC20(tk.tokenAddress).allowance(msg.sender, delegate);
                tk.allowanceGov = IERC20(tk.tokenAddress).allowance(msg.sender, governance);
                tk.status = ITomiConfig(configAddr).tokenStatus(tk.tokenAddress);
                tk.totalSupply = IERC20(tk.tokenAddress).totalSupply();
                token_list[index] = tk;
                index++;
            }
        }
    }
    
    function queryLiquidityList() public view returns (Liquidity[] memory liquidity_list) {
        uint count = ITomiDelegate(delegate).getPlayerPairCount(msg.sender);
        if(count > 0) {
            liquidity_list = new Liquidity[](count);
            for(uint i = 0;i < count;i++) {
                Liquidity memory l;
                l.lp  = ITomiDelegate(delegate).playerPairs(msg.sender, i);
                l.pair = ITomiFactory(factory).getPair(ITomiLP(l.lp).tokenA(), ITomiLP(l.lp).tokenB());
                l.balance = IERC20(l.lp).balanceOf(msg.sender);
                l.totalSupply = IERC20(l.pair).totalSupply();
                l.lastBlock = ITomiPair(l.pair).lastMintBlock(msg.sender);
                liquidity_list[i] = l;
            }
        }
    }

    function countLiquidityList() public view returns (uint) {
        return ITomiDelegate(delegate).getPlayerPairCount(msg.sender);
    }
        
    function iterateLiquidityList(uint _start, uint _end) public view returns (Liquidity[] memory liquidity_list) {
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        uint count = ITomiDelegate(delegate).getPlayerPairCount(msg.sender);
        if(count > 0) {
            if (_end > count) _end = count;
            count = _end - _start;
            liquidity_list = new Liquidity[](count);
            uint index = 0;
            for(uint i = 0;i < count;i++) {
                Liquidity memory l;
                l.lp  = ITomiDelegate(delegate).playerPairs(msg.sender, i);
                l.pair = ITomiFactory(factory).getPair(ITomiLP(l.lp).tokenA(), ITomiLP(l.lp).tokenB());
                l.balance = IERC20(l.lp).balanceOf(msg.sender);
                l.totalSupply = IERC20(l.pair).totalSupply();
                l.lastBlock = ITomiPair(l.pair).lastMintBlock(msg.sender);
                liquidity_list[index] = l;
                index++;
            }
        }
    }

    function queryPairListInfo(address[] memory pair_list) public view returns (address[] memory token0_list, address[] memory token1_list,
    uint[] memory reserve0_list, uint[] memory reserve1_list) {
        uint count = pair_list.length;
        if(count > 0) {
            token0_list = new address[](count);
            token1_list = new address[](count);
            reserve0_list = new uint[](count);
            reserve1_list = new uint[](count);
            for(uint i = 0;i < count;i++) {
                token0_list[i] = ITomiPair(pair_list[i]).token0();
                token1_list[i] = ITomiPair(pair_list[i]).token1();
                (reserve0_list[i], reserve1_list[i], ) = ITomiPair(pair_list[i]).getReserves();
            }
        }
    }
    
    function queryPairReserve(address[] memory token0_list, address[] memory token1_list) public
    view returns (uint[] memory reserve0_list, uint[] memory reserve1_list, bool[] memory exist_list) {
        uint count = token0_list.length;
        if(count > 0) {
            reserve0_list = new uint[](count);
            reserve1_list = new uint[](count);
            exist_list = new bool[](count);
            for(uint i = 0;i < count;i++) {
                if(ITomiPlatform(platform).existPair(token0_list[i], token1_list[i])) {
                    (reserve0_list[i], reserve1_list[i]) = ITomiPlatform(platform).getReserves(token0_list[i], token1_list[i]);
                    exist_list[i] = true;
                } else {
                    exist_list[i] = false;
                }
            }
        }
    }
    
    function queryConfig() public view returns (uint fee_percent, uint proposal_amount, uint unstake_duration, 
    uint remove_duration, uint list_token_amount, uint vote_percent){
        fee_percent = ITomiConfig(configAddr).getConfigValue(SWAP_FEE_PERCENT);
        proposal_amount = ITomiConfig(configAddr).getConfigValue(PROPOSAL_TGAS_AMOUNT);
        unstake_duration = ITomiConfig(configAddr).getConfigValue(UNSTAKE_DURATION);
        remove_duration = ITomiConfig(configAddr).getConfigValue(REMOVE_LIQUIDITY_DURATION);
        list_token_amount = ITomiConfig(configAddr).getConfigValue(LIST_TGAS_AMOUNT);
        vote_percent = ITomiConfig(configAddr).getConfigValue(VOTE_REWARD_PERCENT);
    }
    
    function queryCondition(address[] memory path_list) public view returns (uint){
        uint count = path_list.length;
        for(uint i = 0;i < count;i++) {
            if(!ITomiPlatform(platform).swapPrecondition(path_list[i])) {
                return i + 1;
            }
        }
        
        return 0;
    }
    
    function generateProposal(address ballot_address) public view returns (Proposal memory proposal){
        proposal.proposer = ITomiBallot(ballot_address).proposer();
        proposal.subject = ITomiBallot(ballot_address).subject();
        proposal.content = ITomiBallot(ballot_address).content();
        proposal.createTime = ITomiBallot(ballot_address).createTime();
        proposal.endTime = ITomiBallot(ballot_address).endTime();
        proposal.executionTime = ITomiBallot(ballot_address).executionTime();
        proposal.end = block.number > ITomiBallot(ballot_address).endTime() ? true: false;
        proposal.audited = ITomiBallot(ballot_address).ended();
        proposal.YES = ITomiBallot(ballot_address).proposals(1);
        proposal.NO = ITomiBallot(ballot_address).proposals(2);
        proposal.totalReward = ITomiGovernance(governance).ballotOf(ballot_address);
        proposal.ballotAddress = ballot_address;
        proposal.voted = ITomiBallot(ballot_address).voters(msg.sender).voted;
        proposal.voteIndex = ITomiBallot(ballot_address).voters(msg.sender).vote;
        proposal.weight = ITomiBallot(ballot_address).voters(msg.sender).weight;
        proposal.minted = ITomiGovernance(governance).collectUsers(ballot_address, msg.sender) == 1;
        proposal.ballotType = ITomiGovernance(governance).ballotTypes(ballot_address);
        proposal.tokenAddress = ITomiGovernance(governance).tokenBallots(ballot_address);
        proposal.value = ITomiBallot(ballot_address).value();
        proposal.proposalType = ITomiGovernance(governance).ballotTypes(ballot_address);
        proposal.result = ITomiBallot(ballot_address).result();

        if(proposal.ballotType == 1) {  
            proposal.key = ITomiGovernance(governance).configBallots(ballot_address);
            proposal.currentValue = ITomiConfig(governance).getConfigValue(proposal.key);
        }
    }

    function generateRevenueProposal(address ballot_address) public view returns (RevenueProposal memory proposal){
        proposal.proposer = ITomiBallotRevenue(ballot_address).proposer();
        proposal.subject = ITomiBallotRevenue(ballot_address).subject();
        proposal.content = ITomiBallotRevenue(ballot_address).content();
        proposal.createTime = ITomiBallotRevenue(ballot_address).createTime();
        proposal.endTime = ITomiBallotRevenue(ballot_address).endTime();
        proposal.executionTime = ITomiBallotRevenue(ballot_address).executionTime();
        proposal.end = block.timestamp > ITomiBallotRevenue(ballot_address).endTime() ? true: false;
        proposal.audited = ITomiBallotRevenue(ballot_address).ended();
        proposal.totalReward = ITomiGovernance(governance).ballotOf(ballot_address);
        proposal.ballotAddress = ballot_address;
        proposal.participated = ITomiBallotRevenue(ballot_address).participators(msg.sender).participated;
        proposal.weight = ITomiBallotRevenue(ballot_address).participators(msg.sender).weight;
        proposal.minted = ITomiGovernance(governance).collectUsers(ballot_address, msg.sender) == 1;
        proposal.ballotType = ITomiGovernance(governance).ballotTypes(ballot_address);
        proposal.tokenAddress = ITomiGovernance(governance).tokenBallots(ballot_address);
        proposal.total = ITomiBallotRevenue(ballot_address).total();
    }    

    function queryTokenItemInfo(address token) public view returns (string memory symbol, uint decimal, uint totalSupply, uint balance, uint allowance) {
        symbol = IERC20(token).symbol();
        decimal = IERC20(token).decimals();
        totalSupply = IERC20(token).totalSupply();
        balance = IERC20(token).balanceOf(msg.sender);
        allowance = IERC20(token).allowance(msg.sender, delegate);
    }
    
    function queryConfigInfo(bytes32 name) public view returns (Config memory config_item){
        config_item = ITomiConfig(configAddr).configs(name);
    }
    
    function queryStakeInfo() public view returns (uint stake_amount, uint stake_block, uint total_stake) {
        stake_amount = ITomiGovernance(governance).balanceOf(msg.sender);
        stake_block = ITomiGovernance(governance).allowance(msg.sender);
        total_stake = ITomiGovernance(governance).stakingSupply();
    }

    function queryProposalList() public view returns (Proposal[] memory proposal_list){
        uint count = ITomiGovernance(governance).ballotCount();
        proposal_list = new Proposal[](count);
        for(uint i = 0;i < count;i++) {
            address ballot_address = ITomiGovernance(governance).ballots(i);
            proposal_list[count - i - 1] = generateProposal(ballot_address);
        }
    }

    function queryRevenueProposalList() public view returns (RevenueProposal[] memory proposal_list){
        uint count = ITomiGovernance(governance).ballotRevenueCount();
        proposal_list = new RevenueProposal[](count);
        for(uint i = 0;i < count;i++) {
            address ballot_address = ITomiGovernance(governance).revenueBallots(i);
            proposal_list[count - i - 1] = generateRevenueProposal(ballot_address);(ballot_address);
        }
    }

    function countProposalList() public view returns (uint) {
        return ITomiGovernance(governance).ballotCount();
    }

    function iterateProposalList(uint _start, uint _end) public view returns (Proposal[] memory proposal_list){
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        uint count = ITomiGovernance(governance).ballotCount();
        if (_end > count) _end = count;
        count = _end - _start;
        proposal_list = new Proposal[](count);
        uint index = 0;
        for(uint i = 0;i < count;i++) {
            address ballot_address = ITomiGovernance(governance).ballots(i);
            proposal_list[index] = generateProposal(ballot_address);
            index++;
        }
    }

    function iterateReverseProposalList(uint _start, uint _end) public view returns (Proposal[] memory proposal_list){
        require(_end <= _start && _end >= 0 && _start >= 0, "INVAID_PARAMTERS");
        uint count = ITomiGovernance(governance).ballotCount();
        if (_start > count) _start = count;
        count = _start - _end;
        proposal_list = new Proposal[](count);
        uint index = 0;
        for(uint i = 0;i < count;i++) {
            address ballot_address = ITomiGovernance(governance).ballots(i);
            proposal_list[index] = generateProposal(ballot_address);
            index++;
        }
    }
        
    function queryPairWeights(address[] memory pairs) public view returns (uint[] memory weights){
        uint count = pairs.length;
        weights = new uint[](count);
        for(uint i = 0; i < count; i++) {
            weights[i] = ITomiTransferListener(transferListener).pairWeights(pairs[i]);
        }
    }

    function getPairReserve(address _pair) public view returns (address token0, address token1, uint8 decimals0, uint8 decimals1, uint reserve0, uint reserve1) {
        token0 = ITomiPair(_pair).token0();
        token1 = ITomiPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ITomiPair(_pair).getReserves();
    }

    function getPairReserveWithUser(address _pair, address _user) public view returns (address token0, address token1, uint8 decimals0, uint8 decimals1, uint reserve0, uint reserve1, uint balance0, uint balance1) {
        token0 = ITomiPair(_pair).token0();
        token1 = ITomiPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ITomiPair(_pair).getReserves();
        balance0 = IERC20(token0).balanceOf(_user);
        balance1 = IERC20(token1).balanceOf(_user);
    }
}

