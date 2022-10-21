pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;


interface IMerkleRedeem {
    function claimEpoch(address _liquidityProvider, uint256 _epoch, address _token, uint256 _claimedBalance, bytes32[] calldata _merkleProof) external;
}

contract MerkleRedeemHelper {
    IMerkleRedeem public redeem;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be the contract owner");
        _;
    }

    function setRedeem(IMerkleRedeem _redeem) external onlyOwner {
        redeem = _redeem;
    }

    struct Claim {
        uint256 epoch;
        address token;
        uint256 balance;
        bytes32[] merkleProof;
    }

    function claimEpochs(address _liquidityProvider, Claim[] memory claims) public
    {
        require(address(redeem) != address(0), "MerkleRedeemHelper: no merkle redeem");

        Claim memory claim;
        for (uint256 i = 0; i < claims.length; i++) {
            claim = claims[i];

            redeem.claimEpoch(
                _liquidityProvider,
                claim.epoch,
                claim.token,
                claim.balance,
                claim.merkleProof
            );
        }
    }
}
