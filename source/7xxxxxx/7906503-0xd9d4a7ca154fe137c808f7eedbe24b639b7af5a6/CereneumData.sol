pragma solidity ^0.5.2;

import "./MerkleProof.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract CereneumData is ERC20
{
	using SafeMath for uint256;

  //Launch timestamp of contract used to track how long contract has been running
  uint256 internal m_tContractLaunchTime;

	//Root hashes of the 5 UTXO Merkle trees. Used to verify claims.
  //0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  bytes32[5] public m_hMerkleTreeRootsArray;

	//Total number of UTXO's at snapshot. Used for calculating bonus rewards.
  uint256 public constant m_nUTXOCountAtSnapshot = 85997439;

  //Maximum number of redeemable coins at snapshot.
  uint256 public constant m_nMaxRedeemable = 21275254524468718;

  //For Prosperous bonus we need to use the adjusted redeemable amount
  //That has the whale penalties applied (lowering claimable supply)
  uint256 public constant m_nAdjustedMaxRedeemable = 15019398043400000;

	//Genesis Address
  address constant internal m_genesis = 0xb26165df612B1c9dc705B9872178B3F48151b24d;

	//Eth Pool Genesis Address
	address payable constant internal m_EthGenesis = 0xbe9CEF4196a835F29B117108460ed6fcA299b611;

	//The public donation address for referrals
	address payable constant internal m_publicReferralAddress = 0x8eAf4Fec503da352EB66Ef1E2f75C63e5bC635e1;

  //Store the BTC ratios for BCH, BSV, ETH and LTC
  uint16[4] public m_blockchainRatios;

  enum AddressType { LegacyUncompressed, LegacyCompressed, SegwitUncompressed, SegwitCompressed }
  enum BlockchainType { Bitcoin, BitcoinCash, BitcoinSV, Ethereum, Litecoin }

	//Track how many tokens and UTXOs have been redeemed.
	//These are used for calculating bonus rewards.
  uint256 public m_nTotalRedeemed = 0;
  uint256 public m_nRedeemedCount = 0;

  //Map of redeemed UTXOs to boolean (true/false if redeemed or not)
  mapping(uint8 => mapping(bytes32 => bool)) internal m_claimedUTXOsMap;

  //Store the last day UpdateDailyData() was successfully executed
	//Starts at 14 to give a two week buffer after contract launch
  uint256 internal m_nLastUpdatedDay = 14;

  //Daily data
  struct DailyDataStuct
	{
    uint256 nPayoutAmount;
    uint256 nTotalStakeShares;
		uint256 nTotalEthStaked;
  }

	//Map to store daily historical data.
  mapping(uint256 => DailyDataStuct) public m_dailyDataMap;

  //Stakes Storage
  struct StakeStruct
	{
    uint256 nAmountStaked;
    uint256 nSharesStaked;	//Get bonus shares for longer stake times
		uint256 nCompoundedPayoutAccumulated;
    uint256 tLockTime;
    uint256 tEndStakeCommitTime;
		uint256 tLastCompoundedUpdateTime;
    uint256 tTimeRemovedFromGlobalPool;
		uint8 nVotedOnMultiplier;
		bool bIsInGlobalPool;
    bool bIsLatePenaltyAlreadyPooled;
  }

	//Eth Pool Stakes Storage
  struct EthStakeStruct
	{
    uint256 nAmount;
    uint256 nDay;
  }

	//Map of addresses to StakeStructs.
  mapping(address => StakeStruct[]) public m_staked;

	//Map of addresses to ETH amount (in Wei) participating in the Eth pool
	mapping(address => EthStakeStruct[]) public m_EthereumStakers;

	//Accumulated early/late unstake penalties to go into next staker pool as rewards
  uint256 internal m_nEarlyAndLateUnstakePool;

	//Track the number of staked tokens and shares
  uint256 public m_nTotalStakedTokens;
  uint256 public m_nTotalStakeShares;

	//The daily amount of ETH in the ETH pool
	uint256 public m_nTotalEthStaked = 0;

	//The latest interest multiplier voted on by the majority of the staker pool
  uint8 public m_nInterestMultiplier = 1;

	//The number of stake shares voting for each interest multiplier
	//1 keeps the base 5% interest (minimum), 2 is 10%, ... 10 is 50% (maximum)
	mapping(uint8 => uint256) public m_votingMultiplierMap;

  //Maximum stake time allowed
  uint256 internal constant m_nMaxStakingTime = 365 days * 5;	//years is deprecated because of leap years

	//Two week buffer window after launch before interest starts
	uint256 internal constant m_nClaimPhaseBufferDays = 14;

	uint256 public m_nLastEthWithdrawalTime = 0;

	bool internal m_bHasAirdroppedExchanges = false;

	address[12] internal m_exchangeAirdropAddresses;
	uint256[12] internal m_exchangeAirdropAmounts;
}

