/**
 *Submitted for verification at Etherscan.io on 2020-02-04
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-17
*/

pragma solidity 0.5.9;
                                                                                                                 
// 'BitcoinSoV' contract
// Mineable & Deflationary ERC20 Token using Proof Of Work
// Website: https://btcsov.com
//
// Symbol      : BSOV
// Name        : BitcoinSoV 
// Total supply: 21,000,000.00
// Decimals    : 8
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract tokenContract {
     function mint(uint256 nonce, bytes32 challenge_digest) public returns(bool) {}
}

contract MergeMiner {
    address constant public btc = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31; //0xbtc
    address constant public sedo = 0x0F00f1696218EaeFa2D2330Df3D6D1f94813b38f; //sedo
    address constant public bsov = 0x26946adA5eCb57f3A1F91605050Ce45c482C9Eb1; //bsov
    
     function multiMint(uint256 nonce, bytes32 challenge_digest, uint8 diff) public
    returns (bool)
    {
        bool success = false;
        if (diff <= 1) {
           tokenContract a = tokenContract(btc);
           success = a.mint(nonce,challenge_digest);//(bytes4(keccak256("mint(uint256,bytes32)")),nonce,challenge_digest);
        //    success = bsov.call(bytes4(keccak256("mint(uint256,bytes32)")),nonce,challenge_digest);
           // success = bsov.call(abi.enc("mint(uint256,bytes32))",nonce,challenge_digest);
        }
        if (diff <= 2) {
            success = false;
            tokenContract a = tokenContract(sedo);
            success = a.mint(nonce,challenge_digest);
         //    success = sedo.call(bytes4(keccak256("mint(uint256,bytes32)")),nonce,challenge_digest);
        }
        if (diff <= 3) {
            success = true;
            tokenContract a = tokenContract(btc);
            success = a.mint(nonce,challenge_digest);
          //  success = btc.call(bytes4(keccak256("mint(uint256,bytes32)")),nonce,challenge_digest);
        }


      return success;

    }
}
