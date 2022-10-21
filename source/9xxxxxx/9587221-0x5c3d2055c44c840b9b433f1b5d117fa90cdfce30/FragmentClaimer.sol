pragma solidity ^0.5.0;

import "ERC721MetadataMintable.sol";

contract fragmentClaimer {
    event UpdateWhitelist(address _account, bool _value);
    event aTokenWasClaimed(uint _tokenNumber, address _tokenClaimer);
    event yeeeeeeaaaaaahThxCoeurCoeurCoeur(address _tipper);
    event withdrawFunds(address _withdrawer, uint _funds);

    mapping(address => bool) public whitelist;
    mapping(uint => bool) public tokensThatWereClaimed;

    uint maxTokenId;
    uint totalFunds;
    address ERC721address;

    constructor(uint _maxTokenId, address _ERC721address) public {
        whitelist[msg.sender] = true;
        maxTokenId = _maxTokenId;
        ERC721address = _ERC721address;
    }

    function () external payable {
        if (msg.value > 0) {
            totalFunds += msg.value;
            emit yeeeeeeaaaaaahThxCoeurCoeurCoeur(msg.sender);
        }
    }

    function claimAToken(uint _tokenToClaim, string memory _tokenURI, bytes memory _signature) 
    public 
    payable
    returns (bool)
    {

        // Checking if the token has already been claimed
        require(!tokensThatWereClaimed[_tokenToClaim], "Claim: token already claimed");
        // Not sure this is useful but oh well
        require(_tokenToClaim <= maxTokenId, "Claim: tokenId outbounds");
        // Creating a hash unique to this token number, and this token contract
        bytes32 _hash = keccak256(abi.encode(ERC721address, _tokenToClaim, _tokenURI));
        // Making sure that the signer has been whitelisted
        require(signerIsWhitelisted(_hash, _signature), "Claim: signer not whitelisted");
        // All should be good, so we mint a token yeah
        ERC721MetadataMintable targetERC721Contract = ERC721MetadataMintable(ERC721address);
        targetERC721Contract.mintWithTokenURI(msg.sender, _tokenToClaim, _tokenURI);

        // Registering that the token was claimed
        // Note that there is a check in the ERC721 for this too
        tokensThatWereClaimed[_tokenToClaim] = true;
        // Emitting an event
        emit aTokenWasClaimed(_tokenToClaim, msg.sender);

        // If a tip was included, thank the tipper
        if (msg.value > 0) {
            emit yeeeeeeaaaaaahThxCoeurCoeurCoeur(msg.sender);
            totalFunds += msg.value;
        }
    }

    function withdrawTips() public onlyWhitelisted {
        msg.sender.transfer(totalFunds);
        emit withdrawFunds(msg.sender, totalFunds );
    }


    // 20/02/27: Borrowed from https://github.com/austintgriffith/bouncer-proxy/blob/master/BouncerProxy/BouncerProxy.sol
    //borrowed from OpenZeppelin's ESDA stuff:
    //https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/cryptography/ECDSA.sol
    function signerIsWhitelisted(bytes32 _hash, bytes memory _signature) internal view returns (bool) {
		bytes32 r;
		bytes32 s;
		uint8 v;
		// Check the signature length
		if (_signature.length != 65) {
			return false;
		}
		// Divide the signature in r, s and v variables
		// ecrecover takes the signature parameters, and the only way to get them
		// currently is to use assembly.
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := byte(0, mload(add(_signature, 96)))
		}
		// Version of signature should be 27 or 28, but 0 and 1 are also possible versions
		if (v < 27) {
			v += 27;
		}
		// If the version is correct return the signer address
		if (v != 27 && v != 28) {
			return false;
		} else {
			// solium-disable-next-line arg-overflow
			return whitelist[ecrecover(keccak256(
				abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
				), v, r, s)];
        }
	}

	//  20/02/27: Borrowed from https://github.com/rocksideio/contracts/blob/master/contracts/Identity.sol
	function updateWhitelist(address _account, bool _value) onlyWhitelisted public returns (bool) {
        whitelist[_account] = _value;
        emit UpdateWhitelist(_account, _value);
        return true;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Account Not Whitelisted");
        _;
    }
}

