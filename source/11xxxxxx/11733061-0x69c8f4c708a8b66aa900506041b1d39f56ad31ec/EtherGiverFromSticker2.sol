// This probably won't explode... for real this time
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;
interface ZeroXChanSticker {
	function originalTokenOwner(uint256 tokenId) external view returns(address);
	function tokenProperty(uint256 tokenId) external view returns(uint256);
}
contract EtherGiverFromSticker2{
    uint256 constant MAX_TOKENS = 195;
    address internal admin;
    ZeroXChanSticker internal thingWithUserWorth;
    uint256 internal contractAirdropStore;
    uint256 internal contractBalanceStore;
    uint256 internal contractStore;
    mapping (address => uint256) public userShares;
    address[] internal airdropReceivers;
    constructor(){
        contractStore = (
            0xffffffffffffffffffffffffffffffff00000000000000000000000000000000 | // claimStartTime = claimEndTime = inifnity (later set by deposit)
            (241655500000000000000) // totalShares = 241655500000000000000
        );
        thingWithUserWorth = ZeroXChanSticker(0x238C0ebf1Af19b9A8881155b4FffaA202Be50D35);
	    admin = 0x8FFDE97829408c39cdE8fAdcD4060fd6fFd5A355;
    }
    function totalDeposit() public view returns (uint128){
        return (uint128(contractBalanceStore >> 128));
    }
    function leftoverAmount() public view returns(uint128){
       return (uint128(contractBalanceStore));
    }
    function airdropShares() public view returns(uint128){
        return (uint128(contractAirdropStore));
    }
    function airdropIndex() public view returns(uint128){
        return (uint128(contractAirdropStore >> 128));
    }
    function totalUsersClaimed() public view returns(uint128){
        return (uint128(airdropReceivers.length));
    }
    function claimStartTime() public view returns(uint64){
        return(uint64(contractStore >> 192));
    }
    function claimEndTime() public view returns(uint64){
        return(uint64(contractStore >> 128));
    }
    function totalShares() public view returns(uint128){
        return(uint128(contractStore));
    }
    function abort() public{
        require(msg.sender == admin, "a"); // "You're not allowed to do this"
	    require(block.timestamp < claimStartTime(), "b"); // "Too late to abort"
	    selfdestruct(payable(msg.sender));
    }
    // Must be fallback in order to receive funds from the multisig contract
    fallback() external payable{
        require(msg.sender == admin, "a"); // "You're not allowed to do this"
        require(block.timestamp < claimStartTime(), "c"); // "Cannot do this during claim time"
        // Add value to leftoverAmount and totalDeposit 
        contractBalanceStore += ((msg.value << 128) | msg.value);
        // Get this shit on the road
        contractStore &= (
            ((block.timestamp + 3600) << 192) | // claimStartTime = currenTime + 1 hour
            ((block.timestamp + 608400) << 128) | // claimEndTime = currenTime + 1 hour + 1 week
            0xffffffffffffffffffffffffffffffff
        );
    }
    function makeClaim(uint256[] calldata tokenIds) public{
        require(block.timestamp >= claimStartTime(), "d"); // "Too early to make a claim"
        require(block.timestamp < claimEndTime(), "e"); // "Too late to make a claim"
        require(tokenIds.length > 0, "f"); // "Nothing to claim"
        uint256 localUserShares = userShares[msg.sender];
        require(localUserShares == 0, "g"); // "Already claimed"
        uint256 tokensClaimed = 0;
        uint256 tokenId;
        for(uint256 i = 0; i < tokenIds.length; i += 1){
            tokenId = tokenIds[i];
            require(tokenId < MAX_TOKENS, "h"); // "Invalid token ID"
            // This works because there are less than 255 total tokens
            require(tokensClaimed & (2 ** tokenId) == 0, "i"); // "You cannot claim the same token twice"
            require(thingWithUserWorth.originalTokenOwner(tokenId) == msg.sender, "j"); // "Token must be created by you"
            localUserShares += thingWithUserWorth.tokenProperty(tokenId);
            tokensClaimed |= (2 ** tokenId); // We don't need to store claimed tokens as each address can only claim once
        }
        unchecked{
            // Add to airdropShares, Impossible to overflow
            contractAirdropStore += localUserShares;
        }
        uint256 valueToSend = uint256(totalDeposit()) * localUserShares / uint256(totalShares());
        // Subtract from leftoverAmount, used in airdrops later
        contractBalanceStore -= valueToSend;
        payable(msg.sender).transfer(valueToSend);
        airdropReceivers.push(msg.sender);
        
        userShares[msg.sender] = localUserShares;
    }
    function doAirdrop(uint128 amountToDo) public{
        require(block.timestamp >= claimEndTime(), "c"); // "Cannot do this during claim time"
        uint128 startIndex = airdropIndex();
        // amountToDo becomes endIndex
        amountToDo += startIndex;
        if(amountToDo > uint128(airdropReceivers.length)){
            amountToDo = uint128(airdropReceivers.length);
        }
        uint256 localAirdropShares = uint256(airdropShares());
        for(uint128 i = startIndex; i < amountToDo; i += 1){
            payable(airdropReceivers[i]).transfer(uint256(leftoverAmount()) * userShares[airdropReceivers[i]] / localAirdropShares);
        }
        contractAirdropStore &= 0xffffffffffffffffffffffffffffffff;
        contractAirdropStore |= uint256(amountToDo) << 128;
        if(amountToDo == uint128(airdropReceivers.length)){
            selfdestruct(payable(msg.sender));
        }
    }
}
