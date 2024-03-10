pragma solidity ^0.5.2;

import "./CereneumData.sol";

contract CereneumImplementation is CereneumData
{
	using SafeMath for uint256;

	//Events
  event ClaimEvent(
    uint256 nOriginalClaimAmount,
    uint256 nAmountGranted,
    uint256 nBonuses,
		uint256 nPenalties,
    bool bWasReferred
  );

  event StartStakeEvent(
    uint256 nAmount,
    uint256 nDays
  );

	event CompoundInterestEvent(
		uint256 nInterestCompounded
	);

  event EndStakeEvent(
    uint256 nPrincipal,
    uint256 nPayout,
    uint256 nDaysServed,
    uint256 nPenalty,
    uint256 nStakeShares,
    uint256 nDaysCommitted
  );

  event EndStakeForAFriendEvent(
    uint256 nShares,
    uint256 tStakeEndTimeCommit
  );

	event StartEthStakeEvent(
    uint256 nEthAmount
  );

	event EndEthStakeEvent(
    uint256 nPayout
  );

	/// @dev Returns the number of current stakes for given address.
	///	@param a_address Address of stake to lookup
	///	@return The number of stakes.
	function GetNumberOfStakes(
		address a_address
	)
	external view returns (uint256)
	{
		return m_staked[a_address].length;
	}

	/// @dev Returns the number of current Eth pool stakes for given address.
	///	@param a_address Address of stake to lookup
	///	@return The number of stakes.
	function GetNumberOfEthPoolStakes(
		address a_address
	)
	external view returns (uint256)
	{
		return m_EthereumStakers[a_address].length;
	}

  /// @dev Returns the timestamp until the next daily update
	///	@return The time until the next daily update.
	function GetTimeUntilNextDailyUpdate() external view returns (uint256)
	{
    uint256 nDay = 1 days;
		return nDay.sub((block.timestamp.sub(m_tContractLaunchTime)).mod(1 days));
	}

	/// @dev Calculates difference between 2 timestamps in days
 	/// @param a_nStartTime beginning timestamp
  /// @param a_nEndTime ending timestamp
  /// @return Difference between timestamps in days
  function DifferenceInDays(
    uint256 a_nStartTime,
    uint256 a_nEndTime
  ) public pure returns (uint256)
	{
    return (a_nEndTime.sub(a_nStartTime).div(1 days));
  }

  /// @dev Calculates the number of days since contract launch for a given timestamp.
  /// @param a_tTimestamp Timestamp to calculate from
  /// @return Number of days into contract
  function TimestampToDaysSinceLaunch(
    uint256 a_tTimestamp
  ) public view returns (uint256)
	{
    return (a_tTimestamp.sub(m_tContractLaunchTime).div(1 days));
  }

  /// @dev Gets the number of days since the launch of the contract
  /// @return Number of days since contract launch
  function DaysSinceLaunch() public view returns (uint256)
	{
    return (TimestampToDaysSinceLaunch(block.timestamp));
  }

  /// @dev Checks if we're still in the claimable phase (first 52 weeks)
  /// @return Boolean on if we are still in the claimable phase
  function IsClaimablePhase() public view returns (bool)
	{
    return (DaysSinceLaunch() < 364);
  }

	/// @dev Starts a 1 day stake in the ETH pool. Requires minimum of 0.01 ETH
	function StartEthStake() external payable
	{
		//Require the minimum value for staking
		require(msg.value >= 0.01 ether, "ETH Sent not above minimum value");

		require(DaysSinceLaunch() >= m_nClaimPhaseBufferDays, "Eth Pool staking doesn't begin until after the buffer window");

		UpdateDailyData();

		m_EthereumStakers[msg.sender].push(
      EthStakeStruct(
        msg.value, // Ethereum staked
				DaysSinceLaunch()	//Day staked
      )
    );

		emit StartEthStakeEvent(
      msg.value
    );

		m_nTotalEthStaked = m_nTotalEthStaked.add(msg.value);
  }

	/// @dev The default function
	function() external payable
	{

  }

	/// @dev Withdraw CER from the Eth pool after stake has completed
 	/// @param a_nIndex The index of the stake to be withdrawn
	function WithdrawFromEthPool(uint256 a_nIndex) external
	{
		//Require that the stake index doesn't go out of bounds
		require(m_EthereumStakers[msg.sender].length > a_nIndex, "Eth stake does not exist");

		UpdateDailyData();

		uint256 nDay = m_EthereumStakers[msg.sender][a_nIndex].nDay;

		require(nDay < DaysSinceLaunch(), "Must wait until next day to withdraw");

		uint256 nAmount = m_EthereumStakers[msg.sender][a_nIndex].nAmount;

		uint256 nPayoutAmount = m_dailyDataMap[nDay].nPayoutAmount.div(10);	//10%

		uint256 nEthPoolPayout = nPayoutAmount.mul(nAmount)
			.div(m_dailyDataMap[nDay].nTotalEthStaked);

		_mint(msg.sender, nEthPoolPayout);

		emit EndEthStakeEvent(
      nEthPoolPayout
    );

		uint256 nEndingIndex = m_EthereumStakers[msg.sender].length.sub(1);

    //Only copy if we aren't removing the last index
    if(nEndingIndex != a_nIndex)
    {
      //Copy last stake in array over stake we are removing
      m_EthereumStakers[msg.sender][a_nIndex] = m_EthereumStakers[msg.sender][nEndingIndex];
    }

    //Lower array length by 1
    m_EthereumStakers[msg.sender].length = nEndingIndex;
	}

	/// @dev Transfers ETH in the contract to the genesis address
	/// Only callable once every 12 weeks.
	function TransferContractETH() external
  {
  	require(address(this).balance != 0, "No Eth to transfer");

		require(m_nLastEthWithdrawalTime.add(12 weeks) <= block.timestamp, "Can only withdraw once every 3 months");

    m_EthGenesis.transfer(address(this).balance);

		m_nLastEthWithdrawalTime = block.timestamp;
  }

	/// @dev Updates and stores the global interest for each day.
	/// Additionally adds the frenzy/prosperous bonuses and the Early/Late unstake penalties.
	/// This function gets called at the start of popular public functions to continuously update.
  function UpdateDailyData() public
	{
    for(m_nLastUpdatedDay; DaysSinceLaunch() > m_nLastUpdatedDay; m_nLastUpdatedDay++)
		{
			//Gives 5% inflation per 365 days
      uint256 nPayoutRound = totalSupply().div(7300);

      uint256 nUnclaimedCoins = 0;
    	//Frenzy/Prosperous bonuses and Unclaimed redistribution only available during claims phase.
      if(m_nLastUpdatedDay < 364)
			{
        nUnclaimedCoins = m_nMaxRedeemable.sub(m_nTotalRedeemed);
				nUnclaimedCoins = GetRobinHoodMonthlyAmount(nUnclaimedCoins, m_nLastUpdatedDay);

        nPayoutRound = nPayoutRound.add(nUnclaimedCoins);

				//Pay frenzy and Prosperous bonuses to genesis address
        _mint(m_genesis, nPayoutRound.mul(m_nRedeemedCount).div(m_nUTXOCountAtSnapshot)); // Frenzy
        _mint(m_genesis, nPayoutRound.mul(m_nTotalRedeemed).div(m_nAdjustedMaxRedeemable)); // Prosperous

        nPayoutRound = nPayoutRound.add(
          //Frenzy bonus 0-100% based on total users claiming
          nPayoutRound.mul(m_nRedeemedCount).div(m_nUTXOCountAtSnapshot)
        ).add(
          //Prosperous bonus 0-100% based on size of claims
          nPayoutRound.mul(m_nTotalRedeemed).div(m_nAdjustedMaxRedeemable)
        );
      }
			else
			{
				//If we are not in the claimable phase anymore apply the voted on interest multiplier

				//First we need to check if there is a new "most voted on" multiplier
				uint8 nVoteMultiplier = 1;
				uint256 nVoteCount = m_votingMultiplierMap[1];

				for(uint8 i=2; i <= 10; i++)
				{
					if(m_votingMultiplierMap[i] > nVoteCount)
					{
						nVoteCount = m_votingMultiplierMap[i];
						nVoteMultiplier = i;
					}
				}

				nPayoutRound = nPayoutRound.mul(nVoteMultiplier);

				//Store last interest multiplier for public viewing
				m_nInterestMultiplier = nVoteMultiplier;
			}

			//Add nPayoutRound to contract's balance
			_mint(address(this), nPayoutRound.sub(nUnclaimedCoins));

      //Add early and late unstake pool to payout round
			if(m_nEarlyAndLateUnstakePool != 0)
			{
      	nPayoutRound = nPayoutRound.add(m_nEarlyAndLateUnstakePool);
				//Reset back to 0 for next day
      	m_nEarlyAndLateUnstakePool = 0;
			}

    	//Store daily data
      m_dailyDataMap[m_nLastUpdatedDay] = DailyDataStuct(
        nPayoutRound,
        m_nTotalStakeShares,
				m_nTotalEthStaked
      );

			m_nTotalEthStaked = 0;
    }
  }

  /// @dev Gets the circulating supply (total supply minus staked coins).
  /// @return Circulating Supply
  function GetCirculatingSupply() external view returns (uint256)
	{
    return totalSupply().sub(balanceOf(address(this)));
  }

  /// @dev Verify a Merkle proof using the UTXO Merkle tree
  /// @param a_hMerkleTreeBranches Merkle tree branches from leaf to root
  /// @param a_hMerkleLeaf Merkle leaf hash that must be present in the UTXO Merkle tree
  /// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  /// @return Boolean on validity of proof
  function VerifyProof(
    bytes32[] memory a_hMerkleTreeBranches,
    bytes32 a_hMerkleLeaf,
    BlockchainType a_nWhichChain
  ) public view returns (bool)
	{
    require(uint8(a_nWhichChain) >= 0 && uint8(a_nWhichChain) <= 4, "Invalid blockchain option");

    return MerkleProof.verify(a_hMerkleTreeBranches, m_hMerkleTreeRootsArray[uint8(a_nWhichChain)], a_hMerkleLeaf);
  }

  /// @dev Validate the ECDSA parameters of signed message
  /// ECDSA public key associated with the specified Ethereum address
  /// @param a_addressClaiming Address within signed message
  /// @param a_publicKeyX X parameter of uncompressed ECDSA public key
  /// @param a_publicKeyY Y parameter of uncompressed ECDSA public key
  /// @param a_v v parameter of ECDSA signature
  /// @param a_r r parameter of ECDSA signature
  /// @param a_s s parameter of ECDSA signature
  /// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  /// @return Boolean on if the signature is valid
  function ECDSAVerify(
    address a_addressClaiming,
    bytes32 a_publicKeyX,
    bytes32 a_publicKeyY,
    uint8 a_v,
    bytes32 a_r,
    bytes32 a_s,
    BlockchainType a_nWhichChain
  ) public pure returns (bool)
	{
    bytes memory addressAsHex = GenerateSignatureMessage(a_addressClaiming, a_nWhichChain);

    bytes32 hHash;
    if(a_nWhichChain != BlockchainType.Ethereum)  //All Bitcoin chains and Litecoin do double sha256 hash
    {
      hHash = sha256(abi.encodePacked(sha256(abi.encodePacked(addressAsHex))));
    }
    else //Otherwise ETH
    {
      hHash = keccak256(abi.encodePacked(addressAsHex));
    }

    return ValidateSignature(
      hHash,
      a_v,
      a_r,
      a_s,
      PublicKeyToEthereumAddress(a_publicKeyX, a_publicKeyY)
    );
  }

  /// @dev Convert an uncompressed ECDSA public key into an Ethereum address
  /// @param a_publicKeyX X parameter of uncompressed ECDSA public key
  /// @param a_publicKeyY Y parameter of uncompressed ECDSA public key
  /// @return Ethereum address generated from the ECDSA public key
  function PublicKeyToEthereumAddress(
    bytes32 a_publicKeyX,
    bytes32 a_publicKeyY
  ) public pure returns (address)
	{
		bytes32 hash = keccak256(abi.encodePacked(a_publicKeyX, a_publicKeyY));
    return address(uint160(uint256((hash))));
  }

  /// @dev Calculate the Bitcoin-style address associated with an ECDSA public key
  /// @param a_publicKeyX First half of ECDSA public key
  /// @param a_publicKeyY Second half of ECDSA public key
  /// @param a_nAddressType Whether BTC/LTC is Legacy or Segwit address and if it was compressed
  /// @return Raw Bitcoin address
  function PublicKeyToBitcoinAddress(
    bytes32 a_publicKeyX,
    bytes32 a_publicKeyY,
    AddressType a_nAddressType
  ) public pure returns (bytes20)
	{
    bytes20 publicKey;
    uint8 initialByte;
    if(a_nAddressType == AddressType.LegacyCompressed || a_nAddressType == AddressType.SegwitCompressed)
		{
      //Hash the compressed format
      initialByte = (uint256(a_publicKeyY) & 1) == 0 ? 0x02 : 0x03;
      publicKey = ripemd160(abi.encodePacked(sha256(abi.encodePacked(initialByte, a_publicKeyX))));
    }
		else
		{
      //Hash the uncompressed format
      initialByte = 0x04;
      publicKey = ripemd160(abi.encodePacked(sha256(abi.encodePacked(initialByte, a_publicKeyX, a_publicKeyY))));
    }

    if(a_nAddressType == AddressType.LegacyUncompressed || a_nAddressType == AddressType.LegacyCompressed)
    {
      return publicKey;
    }
    else if(a_nAddressType == AddressType.SegwitUncompressed || a_nAddressType == AddressType.SegwitCompressed)
    {
      return ripemd160(abi.encodePacked(sha256(abi.encodePacked(hex"0014", publicKey))));
    }
  }

  /// @dev Appends an Ethereum address onto the expected string for a Bitcoin signed message
  /// @param a_address Ethereum address
  /// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  /// @return Correctly formatted message for bitcoin signing
	function GenerateSignatureMessage(
    address a_address,
    BlockchainType a_nWhichChain
  ) public pure returns(bytes memory)
	{
		bytes16 hexDigits = "0123456789abcdef";
		bytes memory prefix;
    uint8 nPrefixLength = 0;

    //One of the bitcoin chains
    if(a_nWhichChain >= BlockchainType.Bitcoin && a_nWhichChain <= BlockchainType.BitcoinSV)
    {
      nPrefixLength = 46;
      prefix = new bytes(nPrefixLength);
      prefix = "\x18Bitcoin Signed Message:\n\x3CClaim_Cereneum_to_0x";
    }
    else if(a_nWhichChain == BlockchainType.Ethereum) //Ethereum chain
    {
      nPrefixLength = 48;
      prefix = new bytes(nPrefixLength);
      prefix = "\x19Ethereum Signed Message:\n60Claim_Cereneum_to_0x";
    }
    else  //Otherwise LTC
    {
      nPrefixLength = 47;
      prefix = new bytes(nPrefixLength);
      prefix = "\x19Litecoin Signed Message:\n\x3CClaim_Cereneum_to_0x";
    }

		bytes20 addressBytes = bytes20(a_address);
		bytes memory message = new bytes(nPrefixLength + 40);
		uint256 nOffset = 0;

		for(uint i = 0; i < nPrefixLength; i++)
		{
    	message[nOffset++] = prefix[i];
    }

		for(uint i = 0; i < 20; i++)
		{
      message[nOffset++] = hexDigits[uint256(uint8(addressBytes[i] >> 4))];
      message[nOffset++] = hexDigits[uint256(uint8(addressBytes[i] & 0x0f))];
    }

		return message;
	}

  /// @dev Validate ECSDA signature was signed by the specified address
  /// @param a_hash Hash of signed data
  /// @param a_v v parameter of ECDSA signature
  /// @param a_r r parameter of ECDSA signature
  /// @param a_s s parameter of ECDSA signature
  /// @param a_address Ethereum address matching the signature
  /// @return Boolean on if the signature is valid
  function ValidateSignature(
    bytes32 a_hash,
    uint8 a_v,
    bytes32 a_r,
    bytes32 a_s,
    address a_address
  ) public pure returns (bool)
	{
    return ecrecover(
      a_hash,
      a_v,
      a_r,
      a_s
    ) == a_address;
  }

  /// @dev Verify that a UTXO with the Merkle leaf hash can be claimed
  /// @param a_hMerkleLeafHash Merkle tree hash of the UTXO to be checked
  /// @param a_hMerkleTreeBranches Merkle tree branches from leaf to root
  /// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  /// @return Boolean on if the UTXO from the given hash can be redeemed
  function CanClaimUTXOHash(
    bytes32 a_hMerkleLeafHash,
    bytes32[] memory a_hMerkleTreeBranches,
    BlockchainType a_nWhichChain
  ) public view returns (bool)
	{
    //Check that the UTXO has not yet been redeemed and that it exists in the Merkle tree
    return(
			(m_claimedUTXOsMap[uint8(a_nWhichChain)][a_hMerkleLeafHash] == false) && VerifyProof(a_hMerkleTreeBranches, a_hMerkleLeafHash, a_nWhichChain)
    );
  }

  /// @dev Check if address can make a claim
  /// @param a_addressRedeeming Raw Bitcoin address (no base58-check encoding)
  /// @param a_nAmount Amount of UTXO to redeem
  /// @param a_hMerkleTreeBranches Merkle tree branches from leaf to root
  /// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  /// @return Boolean on if the UTXO can be redeemed
  function CanClaim(
    bytes20 a_addressRedeeming,
    uint256 a_nAmount,
    bytes32[] memory a_hMerkleTreeBranches,
    BlockchainType a_nWhichChain
  ) public view returns (bool)
	{
    //Calculate the hash of the Merkle leaf associated with this UTXO
    bytes32 hMerkleLeafHash = keccak256(
      abi.encodePacked(
        a_addressRedeeming,
        a_nAmount
      )
    );

    //Check if it can be redeemed
    return CanClaimUTXOHash(hMerkleLeafHash, a_hMerkleTreeBranches, a_nWhichChain);
  }

	/// @dev Calculates the monthly Robin Hood reward
  /// @param a_nAmount The amount to calculate from
  /// @param a_nDaysSinceLaunch The number of days since contract launch
  /// @return The amount after applying monthly Robin Hood calculation
	function GetRobinHoodMonthlyAmount(uint256 a_nAmount, uint256 a_nDaysSinceLaunch) public pure returns (uint256)
	{
		uint256 nScaledAmount = a_nAmount.mul(1000000000000);
		uint256 nScalar = 400000000000000;	// 0.25%
		//Month 1 - 0.25% late penalty
		if(a_nDaysSinceLaunch < 43)
		{
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 2 - Additional 0.5% penalty
		// 0.25% + 0.5% = .75%
		else if(a_nDaysSinceLaunch < 72)
		{
			nScalar = 200000000000000;	// 0.5%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 3 - Additional 0.75% penalty
		// 0.25% + 0.5% + .75% = 1.5%
		else if(a_nDaysSinceLaunch < 101)
		{
			nScalar = 133333333333333;	// 0.75%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 4 - Additional 1.5%
		// 0.25% + 0.5% + .75% + 1.5% = 3%
		else if(a_nDaysSinceLaunch < 130)
		{
			nScalar = 66666666666666;	// 1.5%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 5 - Additional 3%
		// 0.25% + 0.5% + .75% + 1.5% + 3% = 6%
		else if(a_nDaysSinceLaunch < 159)
		{
			nScalar = 33333333333333;	// 3%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 6 - Additional 6%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% = 12%
		else if(a_nDaysSinceLaunch < 188)
		{
			nScalar = 16666666666666;	// 6%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 7 - Additional 8%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% = 20%
		else if(a_nDaysSinceLaunch < 217)
		{
			nScalar = 12499999999999;	// 8%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 8 - Additional 10%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% = 30%
		else if(a_nDaysSinceLaunch < 246)
		{
			nScalar = 10000000000000;	// 10%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 9 - Additional 12.5%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% + 12.5% = 42.5%
		else if(a_nDaysSinceLaunch < 275)
		{
			nScalar = 7999999999999;	// 12.5%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 10 - Additional 15%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% + 12.5% + 15% = 57.5%
		else if(a_nDaysSinceLaunch < 304)
		{
			nScalar = 6666666666666;	// 15%
			return nScaledAmount.div(nScalar.mul(29));
		}
		//Month 11 - Additional 17.5%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% + 12.5% + 15% + 17.5% = 75%
		else if(a_nDaysSinceLaunch < 334)
		{
			nScalar = 5714285714290;	// 17.5%
			return nScaledAmount.div(nScalar.mul(30));
		}
		//Month 12 - Additional 25%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% + 12.5% + 15% + 17.5% + 25% = 100%
		else if(a_nDaysSinceLaunch < 364)
		{
			nScalar = 4000000000000;	// 25%
			return nScaledAmount.div(nScalar.mul(30));
		}
	}

	/// @dev Calculates the monthly late penalty
  /// @param a_nAmount The amount to calculate from
  /// @param a_nDaysSinceLaunch The number of days since contract launch
  /// @return The amount after applying monthly late penalty
	function GetMonthlyLatePenalty(uint256 a_nAmount, uint256 a_nDaysSinceLaunch) public pure returns (uint256)
	{
		if(a_nDaysSinceLaunch <= m_nClaimPhaseBufferDays)
		{
			return 0;
		}

		uint256 nScaledAmount = a_nAmount.mul(1000000000000);
		uint256 nPreviousMonthPenalty = 0;
		uint256 nScalar = 400000000000000;	// 0.25%
		//Month 1 - 0.25% late penalty
		if(a_nDaysSinceLaunch <= 43)
		{
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(14);
			return nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
		}
		//Month 2 - Additional 0.5% penalty
		// 0.25% + 0.5% = .75%
		else if(a_nDaysSinceLaunch <= 72)
		{
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(43);
			nScalar = 200000000000000;	// 0.5%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 3 - Additional 0.75% penalty
		// 0.25% + 0.5% + .75% = 1.5%
		else if(a_nDaysSinceLaunch <= 101)
		{
			nScalar = 133333333333333;	// 0.75%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(72);
			nScalar = 133333333333333;	// 0.75%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 4 - Additional 1.5%
		// 0.25% + 0.5% + .75% + 1.5% = 3%
		else if(a_nDaysSinceLaunch <= 130)
		{
			nScalar = 66666666666666;	// 1.5%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(101);
			nScalar = 66666666666666;	// 1.5%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 5 - Additional 3%
		// 0.25% + 0.5% + .75% + 1.5% + 3% = 6%
		else if(a_nDaysSinceLaunch <= 159)
		{
			nScalar = 33333333333333;	// 3%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(130);
			nScalar = 33333333333333;	// 3%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 6 - Additional 6%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% = 12%
		else if(a_nDaysSinceLaunch <= 188)
		{
			nScalar = 16666666666666;	// 6%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(159);
			nScalar = 16666666666666;	// 6%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 7 - Additional 8%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% = 20%
		else if(a_nDaysSinceLaunch <= 217)
		{
			nScalar = 8333333333333;	// 12%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(188);
			nScalar = 12499999999999;	// 8%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 8 - Additional 10%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% = 30%
		else if(a_nDaysSinceLaunch <= 246)
		{
			nScalar = 5000000000000;	// 20%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(217);
			nScalar = 10000000000000;	// 10%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 9 - Additional 12.5%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% + 12.5% = 42.5%
		else if(a_nDaysSinceLaunch <= 275)
		{
			nScalar = 3333333333333;	// 30%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(246);
			nScalar = 7999999999999;	// 12.5%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 10 - Additional 15%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% + 12.5% + 15% = 57.5%
		else if(a_nDaysSinceLaunch <= 304)
		{
			nScalar = 2352941176472;	// 42.5%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(275);
			nScalar = 6666666666666;	// 15%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(29));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 11 - Additional 17.5%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% + 12.5% + 15% + 17.5% = 75%
		else if(a_nDaysSinceLaunch <= 334)
		{
			nScalar = 1739130434782;	// 57.5%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(304);
			nScalar = 5714285714290;	// 17.5%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(30));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		//Month 12 - Additional 25%
		// 0.25% + 0.5% + .75% + 1.5% + 3% + 6% + 8% + 10% + 12.5% + 15% + 17.5% + 25% = 100%
		else if(a_nDaysSinceLaunch < 364)
		{
			nScalar = 1333333333333;	// 75%
			nPreviousMonthPenalty = nScaledAmount.div(nScalar);
			a_nDaysSinceLaunch = a_nDaysSinceLaunch.sub(334);
			nScalar = 4000000000000;	// 25%
			nScaledAmount = nScaledAmount.mul(a_nDaysSinceLaunch).div(nScalar.mul(30));
			return nScaledAmount.add(nPreviousMonthPenalty);
		}
		else
		{
			return a_nAmount;
		}
	}

	/// @dev Returns claim amount with deduction based on weeks since contract launch.
	/// @param a_nAmount Amount of claim from UTXO
	/// @return Amount after any late penalties
	function GetLateClaimAmount(uint256 a_nAmount) internal view returns (uint256)
	{
		uint256 nDaysSinceLaunch = DaysSinceLaunch();

		return a_nAmount.sub(GetMonthlyLatePenalty(a_nAmount, nDaysSinceLaunch));
	}

  /// @dev Calculates speed bonus for claiming early
  /// @param a_nAmount Amount of claim from UTXO
  /// @return Speed bonus amount
  function GetSpeedBonus(uint256 a_nAmount) internal view returns (uint256)
	{
		uint256 nDaysSinceLaunch = DaysSinceLaunch();

		//We give a two week buffer after contract launch before penalties
		if(nDaysSinceLaunch < m_nClaimPhaseBufferDays)
		{
			nDaysSinceLaunch = 0;
		}
		else
		{
			nDaysSinceLaunch = nDaysSinceLaunch.sub(m_nClaimPhaseBufferDays);
		}

    uint256 nMaxDays = 350;
    a_nAmount = a_nAmount.div(5);
    return a_nAmount.mul(nMaxDays.sub(nDaysSinceLaunch)).div(nMaxDays);
  }

	/// @dev Gets the redeem amount with the blockchain ratio applied.
	/// @param a_nAmount Amount of UTXO in satoshis
	/// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  /// @return Amount with blockchain ratio applied
	function GetRedeemRatio(uint256 a_nAmount, BlockchainType a_nWhichChain) internal view returns (uint256)
	{
		if(a_nWhichChain != BlockchainType.Bitcoin)
		{
			uint8 nWhichChain = uint8(a_nWhichChain);
			--nWhichChain;

			//Many zeros to avoid rounding errors
			uint256 nScalar = 100000000000000000;

			uint256 nRatio = nScalar.div(m_blockchainRatios[nWhichChain]);

			a_nAmount = a_nAmount.mul(1000000000000).div(nRatio);
		}

		return a_nAmount;
	}

  /// @dev Gets the redeem amount and bonuses based on time since contract launch
  /// @param a_nAmount Amount of UTXO in satoshis
  /// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  /// @return Claim amount, bonuses and penalty
  function GetRedeemAmount(uint256 a_nAmount, BlockchainType a_nWhichChain) public view returns (uint256, uint256, uint256)
	{
    a_nAmount = GetRedeemRatio(a_nAmount, a_nWhichChain);

    uint256 nAmount = GetLateClaimAmount(a_nAmount);
    uint256 nBonus = GetSpeedBonus(a_nAmount);

    return (nAmount, nBonus, a_nAmount.sub(nAmount));
  }

	/// @dev Verify claim ownership from signed message
	/// @param a_nAmount Amount of UTXO claim
	/// @param a_hMerkleTreeBranches Merkle tree branches from leaf to root
	/// @param a_addressClaiming Ethereum address within signed message
	/// @param a_pubKeyX First half of uncompressed ECDSA public key from signed message
	/// @param a_pubKeyY Second half of uncompressed ECDSA public key from signed message
  /// @param a_nAddressType Whether BTC/LTC is Legacy or Segwit address
	/// @param a_v v parameter of ECDSA signature
	/// @param a_r r parameter of ECDSA signature
	/// @param a_s s parameter of ECDSA signature
  /// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  function ValidateOwnership(
    uint256 a_nAmount,
    bytes32[] memory a_hMerkleTreeBranches,
    address a_addressClaiming,
    bytes32 a_pubKeyX,
    bytes32 a_pubKeyY,
    AddressType a_nAddressType,
    uint8 a_v,
    bytes32 a_r,
    bytes32 a_s,
    BlockchainType a_nWhichChain
  ) internal
	{
    //Calculate the UTXO Merkle leaf hash for the correct chain
    bytes32 hMerkleLeafHash;
    if(a_nWhichChain != BlockchainType.Ethereum)  //All Bitcoin chains and Litecoin have the same raw address format
    {
      hMerkleLeafHash = keccak256(abi.encodePacked(PublicKeyToBitcoinAddress(a_pubKeyX, a_pubKeyY, a_nAddressType), a_nAmount));
    }
    else //Otherwise ETH
    {
      hMerkleLeafHash = keccak256(abi.encodePacked(PublicKeyToEthereumAddress(a_pubKeyX, a_pubKeyY), a_nAmount));
    }

    //Require that the UTXO can be redeemed
    require(CanClaimUTXOHash(hMerkleLeafHash, a_hMerkleTreeBranches, a_nWhichChain), "UTXO Cannot be redeemed.");

    //Verify the ECDSA parameters match the signed message
    require(
      ECDSAVerify(
        a_addressClaiming,
        a_pubKeyX,
        a_pubKeyY,
        a_v,
        a_r,
        a_s,
        a_nWhichChain
      ),
			"ECDSA verification failed."
    );

    //Save the UTXO as redeemed in the global map
    m_claimedUTXOsMap[uint8(a_nWhichChain)][hMerkleLeafHash] = true;
  }

  /// @dev Claim tokens from a UTXO at snapshot block
  /// granting CER tokens proportional to amount of UTXO.
  /// BCH, BSV, ETH & LTC chains get proportional BTC ratio awards.
  /// @param a_nAmount Amount of UTXO
  /// @param a_hMerkleTreeBranches Merkle tree branches from leaf to root
  /// @param a_addressClaiming The Ethereum address for the claimed CER tokens to be sent to
  /// @param a_publicKeyX X parameter of uncompressed ECDSA public key from UTXO
  /// @param a_publicKeyY Y parameter of uncompressed ECDSA public key from UTXO
  /// @param a_nAddressType Whether BTC/LTC is Legacy or Segwit address and if it was compressed
  /// @param a_v v parameter of ECDSA signature
  /// @param a_r r parameter of ECDSA signature
  /// @param a_s s parameter of ECDSA signature
  /// @param a_nWhichChain Which blockchain is claiming, 0=BTC, 1=BCH, 2=BSV, 3=ETH, 4=LTC
  /// @param a_referrer Optional address of referrer. Address(0) for no referral
  /// @return The number of tokens redeemed, if successful
  function Claim(
    uint256 a_nAmount,
    bytes32[] memory a_hMerkleTreeBranches,
    address a_addressClaiming,
    bytes32 a_publicKeyX,
    bytes32 a_publicKeyY,
    AddressType a_nAddressType,
    uint8 a_v,
    bytes32 a_r,
    bytes32 a_s,
    BlockchainType a_nWhichChain,
    address a_referrer
  ) public returns (uint256)
	{
    //No claims after the first 50 weeks of contract launch
    require(IsClaimablePhase(), "Claim is outside of claims period.");

    require(uint8(a_nWhichChain) >= 0 && uint8(a_nWhichChain) <= 4, "Incorrect blockchain value.");

    require(a_v <= 30 && a_v >= 27, "V parameter is invalid.");

    ValidateOwnership(
      a_nAmount,
      a_hMerkleTreeBranches,
      a_addressClaiming,
      a_publicKeyX,
      a_publicKeyY,
      a_nAddressType,
      a_v,
      a_r,
      a_s,
      a_nWhichChain
    );

    UpdateDailyData();

    m_nTotalRedeemed = m_nTotalRedeemed.add(GetRedeemRatio(a_nAmount, a_nWhichChain));

    (uint256 nTokensRedeemed, uint256 nBonuses, uint256 nPenalties) = GetRedeemAmount(a_nAmount, a_nWhichChain);

		//Transfer coins from contracts wallet to claim wallet
    _transfer(address(this), a_addressClaiming, nTokensRedeemed);

    //Mint speed bonus to claiming address
    _mint(a_addressClaiming, nBonuses);
		//Speed bonus matched for genesis address
    _mint(m_genesis, nBonuses);

    m_nRedeemedCount = m_nRedeemedCount.add(1);

    if(a_referrer != address(0))
		{
			//Grant 10% bonus token to the person being referred
			_mint(a_addressClaiming, nTokensRedeemed.div(10));
			nBonuses = nBonuses.add(nTokensRedeemed.div(10));

      //Grant 20% bonus of tokens to referrer
      _mint(a_referrer, nTokensRedeemed.div(5));

			//Match referral bonus for genesis address (20% for referral and 10% for claimer referral = 30%)
      _mint(m_genesis, nTokensRedeemed.mul(1000000000000).div(3333333333333));
    }

    emit ClaimEvent(
      a_nAmount,
      nTokensRedeemed,
      nBonuses,
			nPenalties,
      a_referrer != address(0)
    );

    //Return the number of tokens redeemed
    return nTokensRedeemed.add(nBonuses);
  }

  /// @dev Calculates stake payouts for a given stake
  /// @param a_nStakeShares Number of shares to calculate payout for
  /// @param a_tLockTime Starting timestamp of stake
  /// @param a_tEndTime Ending timestamp of stake
  /// @return payout amount
  function CalculatePayout(
    uint256 a_nStakeShares,
    uint256 a_tLockTime,
    uint256 a_tEndTime
  ) public view returns (uint256)
	{
		if(m_nLastUpdatedDay == 0)
			return 0;

    uint256 nPayout = 0;

		uint256 tStartDay = TimestampToDaysSinceLaunch(a_tLockTime);

    //Calculate what day stake was closed
    uint256 tEndDay = TimestampToDaysSinceLaunch(a_tEndTime);

    //Iterate through each day and sum up the payout
    for(uint256 i = tStartDay; i < tEndDay; i++)
		{
      uint256 nDailyPayout = m_dailyDataMap[i].nPayoutAmount.mul(a_nStakeShares)
        .div(m_dailyDataMap[i].nTotalStakeShares);

      //Keep sum of payouts
      nPayout = nPayout.add(nDailyPayout);
    }

    return nPayout;
  }

  /// @dev Updates current amount of stake to apply compounding interest
	/// @notice This applies all of your earned interest to future payout calculations
  /// @param a_nStakeIndex index of stake to compound interest for
  function CompoundInterest(
		uint256 a_nStakeIndex
	) external
	{
		require(m_nLastUpdatedDay != 0, "First update day has not finished.");

    //Get a reference to the stake to save gas from constant map lookups
    StakeStruct storage rStake = m_staked[msg.sender][a_nStakeIndex];

		require(block.timestamp < rStake.tEndStakeCommitTime, "Stake has already matured.");

		UpdateDailyData();

		uint256 nInterestEarned = CalculatePayout(
			rStake.nSharesStaked,
		  rStake.tLastCompoundedUpdateTime,
			block.timestamp
		);

		if(nInterestEarned != 0)
		{
			rStake.nCompoundedPayoutAccumulated = rStake.nCompoundedPayoutAccumulated.add(nInterestEarned);
			rStake.nSharesStaked = rStake.nSharesStaked.add(nInterestEarned);

			//InterestRateMultiplier votes
			m_votingMultiplierMap[rStake.nVotedOnMultiplier] = m_votingMultiplierMap[rStake.nVotedOnMultiplier].add(nInterestEarned);

			m_nTotalStakeShares = m_nTotalStakeShares.add(nInterestEarned);
			rStake.tLastCompoundedUpdateTime = block.timestamp;

			emit CompoundInterestEvent(
				nInterestEarned
			);
		}
  }

  /// @dev Starts a stake
  /// @param a_nAmount Amount of token to stake
  /// @param a_nDays Number of days to stake
	/// @param a_nInterestMultiplierVote Pooled interest rate to vote for (1-10 => 5%-50% interest)
  function StartStake(
    uint256 a_nAmount,
    uint256 a_nDays,
		uint8 a_nInterestMultiplierVote
  ) external
	{
		require(DaysSinceLaunch() >= m_nClaimPhaseBufferDays, "Staking doesn't begin until after the buffer window");

    //Verify account has enough tokens
    require(balanceOf(msg.sender) >= a_nAmount, "Not enough funds for stake.");

    //Don't allow 0 amount stakes
    require(a_nAmount > 0, "Stake amount must be greater than 0");

		require(a_nDays >= 7, "Stake is under the minimum time required.");

		require(a_nInterestMultiplierVote >= 1 && a_nInterestMultiplierVote <= 10, "Interest multiplier range is 1-10.");

		//Calculate Unlock time
    uint256 tEndStakeCommitTime = block.timestamp.add(a_nDays.mul(1 days));

    //Don't allow stakes over the maximum stake time
    require(tEndStakeCommitTime <= block.timestamp.add(m_nMaxStakingTime), "Stake time exceeds maximum.");

    UpdateDailyData();

		//Calculate bonus interest for longer stake periods (20% bonus per year)
		uint256 nSharesModifier = 0;

		//Minimum stake time of 3 months to get amplifier bonus
		if(a_nDays >= 90)
		{
			//We can't have a fractional modifier such as .5 so we need to use whole numbers and divide later
			nSharesModifier = a_nDays.mul(2000000).div(365);
		}

    //20% bonus shares per year of committed stake time
    uint256 nStakeShares = a_nAmount.add(a_nAmount.mul(nSharesModifier).div(10000000));

    //Create and store the stake
    m_staked[msg.sender].push(
      StakeStruct(
        a_nAmount, // nAmountStaked
        nStakeShares, // nSharesStaked
				0,	//Accumulated Payout from CompoundInterest
        block.timestamp, // tLockTime
        tEndStakeCommitTime, // tEndStakeCommitTime
				block.timestamp, //tLastCompoundedUpdateTime
        0, // tTimeRemovedFromGlobalPool
				a_nInterestMultiplierVote,
				true, // bIsInGlobalPool
        false // bIsLatePenaltyAlreadyPooled
      )
    );

    emit StartStakeEvent(
      a_nAmount,
      a_nDays
    );

		//InterestRateMultiplier
		m_votingMultiplierMap[a_nInterestMultiplierVote] = m_votingMultiplierMap[a_nInterestMultiplierVote].add(nStakeShares);

    //Globally track staked tokens
    m_nTotalStakedTokens = m_nTotalStakedTokens.add(a_nAmount);

    //Globally track staked shares
    m_nTotalStakeShares = m_nTotalStakeShares.add(nStakeShares);

    //Transfer staked tokens to contract wallet
    _transfer(msg.sender, address(this), a_nAmount);
  }

  /// @dev Calculates penalty for unstaking late
  /// @param a_tEndStakeCommitTime Timestamp stake matured
  /// @param a_tTimeRemovedFromGlobalPool Timestamp stake was removed from global pool
  /// @param a_nInterestEarned Interest earned from stake
  /// @return penalty value
  function CalculateLatePenalty(
    uint256 a_tEndStakeCommitTime,
    uint256 a_tTimeRemovedFromGlobalPool,
    uint256 a_nInterestEarned
  ) public pure returns (uint256)
	{
    uint256 nPenalty = 0;

		//One week grace period
    if(a_tTimeRemovedFromGlobalPool > a_tEndStakeCommitTime.add(1 weeks))
		{
      //Penalty is 1% per day after the 1 week grace period
      uint256 nPenaltyPercent = DifferenceInDays(a_tEndStakeCommitTime.add(1 weeks), a_tTimeRemovedFromGlobalPool);

			//Cap max percent at 100
			if(nPenaltyPercent > 100)
			{
				nPenaltyPercent = 100;
			}

      //Calculate penalty
			nPenalty = a_nInterestEarned.mul(nPenaltyPercent).div(100);
    }

    return nPenalty;
  }

  /// @dev Calculates penalty for unstaking early
	/// @param a_tLockTime Starting timestamp of stake
  /// @param a_nEndStakeCommitTime Timestamp the stake matures
  /// @param a_nAmount Amount that was staked
	/// @param a_nInterestEarned Interest earned from stake
  /// @return penalty value
  function CalculateEarlyPenalty(
		uint256 a_tLockTime,
		uint256 a_nEndStakeCommitTime,
    uint256 a_nAmount,
		uint256 a_nInterestEarned
  ) public view returns (uint256)
	{
    uint256 nPenalty = 0;

    if(block.timestamp < a_nEndStakeCommitTime)
		{
			//If they didn't stake for at least 1 full day we give them no interest
			//To prevent any abuse
			if(DifferenceInDays(a_tLockTime, block.timestamp) == 0)
			{
				nPenalty = a_nInterestEarned;
			}
			else
			{
				//Base penalty is half of earned interest
				nPenalty = a_nInterestEarned.div(2);
			}

			uint256 nCommittedStakeDays = DifferenceInDays(a_tLockTime, a_nEndStakeCommitTime);

			if(nCommittedStakeDays >= 90)
			{
				//Take another 10% per year of committed stake
				nPenalty = nPenalty.add(nPenalty.mul(nCommittedStakeDays).div(3650));
			}

			//5% yearly interest converted to daily interest multiplied by stake time
			uint256 nMinimumPenalty = a_nAmount.mul(nCommittedStakeDays).div(7300);

			if(nMinimumPenalty > nPenalty)
			{
				nPenalty = nMinimumPenalty;
			}
		}

    return nPenalty;
  }

  /// @dev Removes completed stake from global pool
  /// @notice Removing finished stakes will increase the payout to other stakers.
  /// @param a_nStakeIndex Index of stake to process
	/// @param a_address Address of the staker
  function EndStakeForAFriend(
    uint256 a_nStakeIndex,
		address a_address
  ) external
	{
		//Require that the stake index doesn't go out of bounds
		require(m_staked[a_address].length > a_nStakeIndex, "Stake does not exist");

    //Require that the stake has been matured
    require(block.timestamp > m_staked[a_address][a_nStakeIndex].tEndStakeCommitTime, "Stake must be matured.");

		ProcessStakeEnding(a_nStakeIndex, a_address, true);
  }

 	/// @dev Ends a stake, even if it is before it has matured.
	/// @notice If stake has matured behavior is the same as EndStakeSafely
  /// @param a_nStakeIndex Index of stake to close
  function EndStakeEarly(
    uint256 a_nStakeIndex
  ) external
	{
		//Require that the stake index doesn't go out of bounds
		require(m_staked[msg.sender].length > a_nStakeIndex, "Stake does not exist");

    ProcessStakeEnding(a_nStakeIndex, msg.sender, false);
  }

  /// @dev Ends a stake safely. Will only execute if a stake is matured.
  /// @param a_nStakeIndex Index of stake to close
  function EndStakeSafely(
    uint256 a_nStakeIndex
  ) external
	{
		//Require that the stake index doesn't go out of bounds
		require(m_staked[msg.sender].length > a_nStakeIndex, "Stake does not exist");

		//Require that stake is matured
		require(block.timestamp > m_staked[msg.sender][a_nStakeIndex].tEndStakeCommitTime, "Stake must be matured.");

    ProcessStakeEnding(a_nStakeIndex, msg.sender, false);
  }

	function ProcessStakeEnding(
    uint256 a_nStakeIndex,
		address a_address,
		bool a_bWasForAFriend
  ) internal
	{
		UpdateDailyData();

    //Get a reference to the stake to save gas from constant map lookups
    StakeStruct storage rStake = m_staked[a_address][a_nStakeIndex];

    uint256 tEndTime = block.timestamp > rStake.tEndStakeCommitTime ?
			rStake.tEndStakeCommitTime : block.timestamp;

		//Calculate Payout
		uint256 nTotalPayout = CalculatePayout(
			rStake.nSharesStaked,
			rStake.tLastCompoundedUpdateTime,
			tEndTime
		);

		//Add any accumulated interest payout from user calling CompoundInterest
		nTotalPayout = nTotalPayout.add(rStake.nCompoundedPayoutAccumulated);

		//Add back the original amount staked
		nTotalPayout = nTotalPayout.add(rStake.nAmountStaked);

		//Is stake still in the global pool?
		if(rStake.bIsInGlobalPool)
		{
			//Update global staked token tracking
			m_nTotalStakedTokens = m_nTotalStakedTokens.sub(rStake.nAmountStaked);

			//Update global stake shares tracking
			m_nTotalStakeShares = m_nTotalStakeShares.sub(rStake.nSharesStaked);

			//InterestRateMultiplier
			m_votingMultiplierMap[rStake.nVotedOnMultiplier] = m_votingMultiplierMap[rStake.nVotedOnMultiplier].sub(rStake.nSharesStaked);

			//Set time removed
			rStake.tTimeRemovedFromGlobalPool = block.timestamp;

			//Set flag that it is no longer in the global pool
			rStake.bIsInGlobalPool = false;

			if(a_bWasForAFriend)
			{
				emit EndStakeForAFriendEvent(
					rStake.nSharesStaked,
					rStake.tEndStakeCommitTime
				);
			}
		}

		//Calculate penalties if any
		uint256 nPenalty = 0;
		if(!a_bWasForAFriend)	//Can't have an early penalty if it was called by EndStakeForAFriend
 		{
			nPenalty = CalculateEarlyPenalty(
				rStake.tLockTime,
				rStake.tEndStakeCommitTime,
				rStake.nAmountStaked,
				nTotalPayout.sub(rStake.nAmountStaked)
			);
		}

		//Only calculate late penalty if there wasn't an early penalty
		if(nPenalty == 0)
		{
			nPenalty = CalculateLatePenalty(
				rStake.tEndStakeCommitTime,
				rStake.tTimeRemovedFromGlobalPool,
				nTotalPayout.sub(rStake.nAmountStaked)
			);
		}

		//Don't payout penalty amount that has already been paid out
		if(nPenalty != 0 && !rStake.bIsLatePenaltyAlreadyPooled)
		{
			//Split penalty between genesis and pool
			m_nEarlyAndLateUnstakePool = m_nEarlyAndLateUnstakePool.add(nPenalty.div(2));
			_transfer(address(this), m_genesis, nPenalty.div(2));
		}

		if(a_bWasForAFriend)
		{
			//Set flag
			rStake.bIsLatePenaltyAlreadyPooled =	true;
		}
		else
		{
			//Apply penalty
			nTotalPayout = nTotalPayout.sub(nPenalty);

			emit EndStakeEvent(
				rStake.nAmountStaked,
				nTotalPayout,
        block.timestamp < rStake.tEndStakeCommitTime ?
  				DifferenceInDays(rStake.tLockTime, block.timestamp) :
  				DifferenceInDays(rStake.tLockTime, rStake.tTimeRemovedFromGlobalPool),
				nPenalty,
				rStake.nSharesStaked,
				DifferenceInDays(rStake.tLockTime, rStake.tEndStakeCommitTime)
			);

			//Payout staked coins from contract
			_transfer(address(this), a_address, nTotalPayout);

			//Remove stake
			RemoveStake(a_address, a_nStakeIndex);
		}
	}

  /// @dev Remove stake from array
  /// @param a_address address of staker
  /// @param a_nStakeIndex index of the stake to delete
  function RemoveStake(
    address a_address,
    uint256 a_nStakeIndex
  ) internal
	{
    uint256 nEndingIndex = m_staked[a_address].length.sub(1);

    //Only copy if we aren't removing the last index
    if(nEndingIndex != a_nStakeIndex)
    {
      //Copy last stake in array over stake we are removing
      m_staked[a_address][a_nStakeIndex] = m_staked[a_address][nEndingIndex];
    }

    //Lower array length by 1
    m_staked[a_address].length = nEndingIndex;
  }
}

