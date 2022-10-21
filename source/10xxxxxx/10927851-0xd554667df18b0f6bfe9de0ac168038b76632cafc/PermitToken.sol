pragma solidity ^0.5.16;

import './Ownable.sol';
import './ERC20.sol';


contract PermitToken is ERC20 {
  string  public constant name     = "Permittable";
  string  public constant symbol   = "PERM";
  string  public constant version  = "1";
  uint8   public constant decimals = 18;
  mapping (address => uint) public nonces;

  bytes32 public DOMAIN_SEPARATOR;
  // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
  bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
  constructor(uint256 supply, uint256 chainid_)  public {

    DOMAIN_SEPARATOR = keccak256(abi.encode(
          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
          keccak256(bytes(name)),
          keccak256(bytes(version)),
          chainid_,
          address(this)
      ));
    _mint(msg.sender, supply);
  }
  // --- Approve by signature ---
   function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                   bool allowed, uint8 v, bytes32 r, bytes32 s) external
   {
       bytes32 digest =
           keccak256(abi.encodePacked(
               "\x19\x01",
               DOMAIN_SEPARATOR,
               keccak256(abi.encode(PERMIT_TYPEHASH,
                                    holder,
                                    spender,
                                    nonce,
                                    expiry,
                                    allowed))
       ));

       require(holder != address(0), "dai/invalid-address-0");
       require(holder == ecrecover(digest, v, r, s), "dai/invalid-permit");
       require(expiry == 0 || now <= expiry, "dai/permit-expired");
       require(nonce == nonces[holder]++, "dai/invalid-nonce");
       uint wad = allowed ? uint(-1) : 0;
       _approve(holder, spender, wad);
       emit Approval(holder, spender, wad);
   }
}

