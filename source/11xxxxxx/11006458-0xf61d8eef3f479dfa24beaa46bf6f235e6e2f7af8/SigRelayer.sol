pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "Comp.sol";
import "GovernorAlpha.sol";


interface GasToken {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}
contract SigRelayer {
	modifier discountGST2 {
		uint256 gasStart = gasleft();
		_;
		uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
		uint gas_left = gasleft();
		uint maxtokens = (gas_left - 27710) / 7020;
		uint tokens = (gasSpent + 14154) / 41130;
		if(tokens > maxtokens) tokens = maxtokens;
		GasToken(0x0000000000b3F879cb30FE243b4Dfee438691c04).freeFromUpTo(msg.sender, tokens);
	}

	bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
	bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
	bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");
	string public constant name = "Compound";
	string public constant name2 = "Compound Governor Alpha";

	address public governorAlpha;
	address public compToken = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
	address public owner;

	constructor(address governorAlpha_) public {
		governorAlpha = governorAlpha_;
		owner = msg.sender;
	}

	function setGovernorAlpha(address newGovernorAlpha) public  {
		require(msg.sender == owner);
		governorAlpha = newGovernorAlpha;
	}


	function relayBySigs(DelegationSig[] memory s1, VoteSig[] memory s2) public discountGST2 {
		for (uint i = 0; i < s1.length; i++) {
			DelegationSig memory sig = s1[i];
			compToken.call(abi.encodeWithSignature("delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)", sig.delegatee, sig.nonce, sig.expiry, sig.v, sig.r, sig.s));
		}
		for (uint i = 0; i < s2.length; i++) {
			VoteSig memory sig = s2[i];
			governorAlpha.call(abi.encodeWithSignature("castVoteBySig(uint256,bool,uint8,bytes32,bytes32)", sig.proposalId,sig.support,sig.v,sig.r,sig.s));
		}
	}

	function signatoryFromDelegateSig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public view returns (address) {
	    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), compToken));
	    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
	    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	    address signatory = ecrecover(digest, v, r, s);
	    require(signatory != address(0), "invalid signature");
	    require(now <= expiry, "signature expired");
	    return signatory;
	}

	function signatoryFromVoteSig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public view returns (address) {
	    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name2)), getChainId(), governorAlpha));
	    bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
	    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	    address signatory = ecrecover(digest, v, r, s);
	    require(signatory != address(0), "invalid signature");
	    return signatory;
	}


  	struct DelegationSig {
	    address delegatee;
	    uint nonce;
	    uint expiry;
	    uint8 v;
	    bytes32 r;
	    bytes32 s;
  	}
  	struct VoteSig {
  		uint proposalId;
  		bool support;
  		uint8 v;
  		bytes32 r;
  		bytes32 s;
  	}

  	function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
