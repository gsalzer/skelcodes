pragma solidity ^0.5.1;
import "../Genesis.sol";

/**
 * 
 * @title ERC20 Standard Token
 * 
 * Inherits events, modifiers & data from the genesis contract which complies with the ERC20 token Standard.
 * Inizalizes genesis functions & extra added functions
 * 
 **/
contract ERC20_Token is Genesis {                                                     // Build on genesis contract
    // Initalise global constants
    string constant ERR_INSUFFICENT_BALANCE = "Insufficent amount of DRP";          // Error message 102
    string constant ERR_INVALID_DELEGATE    = "Invalid delegate address";           // Error message 103
    string constant ERR_ALLOWANCE_EXCEEDED  = "Allowance exceeded!";                // Error message 104
    string constant ERR_INVALID_KILL_CODE   = "Invalid kill code!";                 // Error message 105
    string constant KILL_CODE               = "K-C102-473";                         // WARNING! Contracts kill code

    // Create new tokens
    // @para tokens_ number of new tokens to create
    function mintCoins(uint tokens_) ownerOnly public returns (uint balance) {
        tokens_ = tokens_.toklets(decimals);                                        // Convert tokens to toklets
        coinSupply = coinSupply.add(tokens_);                                       // Create new tokens
        balances[coinOwner] = balances[coinOwner].add(tokens_);                     // Update owners balace
      return coinSupply;
    }
    
    // Destroy tokens
    // @para tokens_ number of tokens to destroy
    function burnCoins(uint tokens_) ownerOnly public returns (uint balance) {      // Restricted to owner only
        tokens_ = tokens_.toklets(decimals);                                        // Convert tokens to toklets
        if (valid(tokens_ <= balances[coinOwner], 102)) {                           // Check enough tokens available
            coinSupply = coinSupply.sub(tokens_);                                   // Decrease total coin supply
            balances[coinOwner] = balances[coinOwner].sub(tokens_);                 // Update owners token balance
          return coinSupply;
        }
    }
    
    // Genesis: Transfer tokens to receiver
    function transfer(address receiver_,
                     uint tokens_) public returns (bool sucess) {
      super.transfer(receiver_, tokens_);
        if (valid(tokens_ <= balances[msg.sender] &&                                // Check enough tokens available
            tokens_ > 0, 102)) {                                                    // and amount greater than zero
            balances[msg.sender] = balances[msg.sender].sub(tokens_);               // Decrease senders token balance
            balances[receiver_] = balances[receiver_].add(tokens_);                 // Increase receivers token balance
            emit Transfer(msg.sender, receiver_, tokens_);                          // Transfer tokens
          return true;
        }
    }

    // Genesis: Approve token allowence for delegate
    function approve(address delegate_,
                    uint tokens_) public returns (bool sucess) {
      super.approve(delegate_, tokens_);
        if (valid(delegate_ != msg.sender, 103)) {                                  // Check not delegating to yourself
            if (tokens_ > coinSupply) { tokens_ = coinSupply; }                     // Limit allowance to total supply
            allowed[msg.sender][delegate_] = tokens_;                               // Update token allowence
            emit Approval(msg.sender, delegate_, tokens_);                          // Approve token allowance
          return true;
        }
    }

    // Genesis: Transfer token from delegated address
    function transferFrom(address owner_, address receiver_,
                         uint tokens_) public returns (bool sucess) {
      super.transferFrom(owner_ , receiver_, tokens_);
        if (valid(tokens_ > 0 && tokens_ <= balances[owner_], 102) &&               // Check amount greater than zero and enough tokens available
            valid(tokens_ <= allowed[owner_][msg.sender], 104)) {                   // Make sure smount is equal or less than token allowance
            balances[owner_] = balances[owner_].sub(tokens_);                       // Decrease owner of tokens balance
            allowed[owner_][msg.sender] = allowed[owner_][msg.sender].sub(tokens_); // Decrease senders tokens allowance
            balances[receiver_] = balances[receiver_].add(tokens_);                 // Increase receivers tokens balance
            emit Transfer(owner_, receiver_, tokens_);                              // Transfer tokens from the owner to the receiver
        return true;
        }
    }
    
    // Validation for autherisation and input error handler
    function valid(bool valid_, uint errorID_) internal pure returns (bool) {       // Check for fatal errors
        if (errorID_ == 101) {require(valid_, ERR_PERMISSION_DENIED);}              // Calling address doesn't have permission
          else if (errorID_ == 102) {require(valid_, ERR_INSUFFICENT_BALANCE);}     // Cancel trasaction due to insufficent value
          else if (errorID_ == 103) {require(valid_, ERR_INVALID_DELEGATE);}        // Cannot delegate to address 
          else if (errorID_ == 104) {require(valid_, ERR_ALLOWANCE_EXCEEDED);}      // Cancel trasaction due to insufficent value
          else if (errorID_ == 105) {require(valid_, ERR_INVALID_KILL_CODE);}       // Cancel trasaction due to insufficent value
          else if (errorID_ == 100) {require (valid_);}                             // Check if required?
        return valid_;
    }
    
    // WARNING! CONFIRM NOTHING ELSE NEEDS THIS CONTRACT BEFORE BURNING IT!
    // Terminates contract
    // @param killCode_ The contracts kill code
    // @return if contract has been terminated
    function burnContract(string memory killCode_) ownerOnly public {
        if (valid((keccak256(abi.encodePacked(killCode_)) ==
                   keccak256(abi.encodePacked(KILL_CODE))), 105))                    // Authenticate kill code
                   { selfdestruct(address(0)); }                                     // Kill contract
    }
}
