pragma solidity ^0.7.6;

interface AvastarsContract {
        function useTraits(uint256 _primeId, bool[12] calldata _traitFlags) external;
        function getPrimeReplicationByTokenId(uint256 _tokenId) external view returns (uint256 tokenId, bool[12] memory replicated); 
}

interface ARTContract {
        function burnArt(uint256 artToBurn) external;
        function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AvastarsInterface {
    
        constructor() {
            Avastars = AvastarsContract(AvastarsAddress);
            AvastarReplicantToken = ARTContract(ARTAddress);
            owner = msg.sender;
            setPaymentIncrement(5000000000000000);
        }
        
        modifier isOwner() {
        require(msg.sender == owner, "Must be owner of contract");
        _;
        }
        
        address public AvastarsAddress = 0xF3E778F839934fC819cFA1040AabaCeCBA01e049; //mainnet: 0xF3E778F839934fC819cFA1040AabaCeCBA01e049
        address public ARTAddress = 0x69ad42A8726f161Bd4C76305DFa8F4ecc120115c; //mainnet: 0x69ad42A8726f161Bd4C76305DFa8F4ecc120115c
        address public owner;
        uint256 public paymentIncrement;
        
        address payable paymentWallet = 0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073; //nft42 wallet: 0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073
        
        event TraitsBurned(address msgsender, uint256 paymentTier); 
        
        AvastarsContract Avastars;
        ARTContract AvastarReplicantToken;
        
        function burnReplicantTraits(uint256 paymentTier, uint[] memory avastarIDs, bool[12][] memory avastarTraits) public payable {
            
            require(msg.value >= paymentTier * paymentIncrement);
            require(avastarIDs.length == avastarTraits.length);
            
            uint256 totalAvastars = avastarIDs.length;
            
            bool[12] memory traitIsUsed;
            bool[12] memory traitsToBurn;
            
            for (uint i = 0; i < totalAvastars; i = i + 1){
                (, traitIsUsed) = Avastars.getPrimeReplicationByTokenId(avastarIDs[i]);
                traitsToBurn = avastarTraits[i];
                
                for(uint j = 0; j < 12; j = j + 1) {
                    if(traitIsUsed[j] == true) {
                        require(traitsToBurn[j] == false);
                    }
                }
                
                Avastars.useTraits(avastarIDs[i],avastarTraits[i]);                
            }    
            
            AvastarReplicantToken.transferFrom(msg.sender,address(this),1000000000000000000);
            AvastarReplicantToken.burnArt(1);
            paymentWallet.transfer(msg.value);
    
            emit TraitsBurned(msg.sender, paymentTier);
        }
        
        function setPaymentIncrement(uint256 newIncrement) public isOwner {
            paymentIncrement = newIncrement;
        }
        
        function setOwner(address newOwner) public isOwner {
            owner = newOwner;
        }
        
        function setPaymentWallet(address payable newWallet) public isOwner {
            paymentWallet = newWallet;
        }
        
}
