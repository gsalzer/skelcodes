/**
 *Submitted for verification at Etherscan.io on 2019-04-03
*/

pragma solidity ^0.5.6; 
//v.1609rev19032301 Ezlab 2016 all-rights reseved support@ezlab.it
//special purpose contract

//common base contract
contract BaseAgriChainContract {
    address payable creator; 
    bool public isSealed;
    constructor() public    {  creator = msg.sender; emit EventCreated(address(this),creator); }
    modifier onlyIfNotSealed() //semantic when sealed is not possible to change sensible data
    {
        if (isSealed)
            revert();
        _;
    }

    modifier onlyBy(address _account) //semantic only _account can operate
    {
        if (msg.sender != _account)
            revert();
        _;
    }
    
    function kill() public onlyBy(creator)   { selfdestruct(creator); }     
    function setCreator(address payable _creator) public  onlyBy(creator)  { creator = _creator;     }
    function setSealed()  onlyBy(creator)  public { isSealed = true;  emit  EventSealed(address(this));   } //seal down contract not reversible

    event EventReady(address self,string method); //invoked when method is ready
    event EventCreated(address self,address creator);
    event EventSealed(address self); //invoked when contract is sealed
    event EventChanged(address self,string property); // generic property change
    event EventChangedInt32(address self,string property,int32 value); //Int32 property change
    event EventChangedString(address self,string property,string value); //string property Change
    event EventChangedAddress(address self,string property,address value); //address property Changed
    
  
}



contract AgriChainSimpleContract   is BaseAgriChainContract    
{  


    string public Numeroguid            ;   
    string public DescrizioneProgetto   ; 
    

    string public IDProdotto            ;  
    string public DescriptionProdotto   ; 
   
    string public EtichettaLabel1       ; 
    string public ValoreEtichetta1      ; 
    
    string public EtichettaLabel2       ; 
    string public ValoreEtichetta2      ; 
    
    string public EtichettaLabel3       ; 
    
    string public ValoreEtichetta3      ; 
    
    string public EtichettaLabel4       ; 
    string public ValoreEtichetta4      ; 
    
    string public EtichettaLabel5       ; 
    string public ValoreEtichetta5      ; 
    
    string public IdentificativoRecord  ; 


    
    address public  AgriChainData;     //ProductionData
    string  public  AgriChainSeal;     //SecuritySeal
    string  public  Notes ;
    

     constructor( )  public      
    {    
          AgriChainData=address(this);
          emit EventReady(address(this),"constructor");
          
    }

  

   function setProgetto(string memory _Numeroguid,string memory _DescrizioneProgetto)  public   onlyBy(creator)  onlyIfNotSealed()   
    {    
         
          Numeroguid = _Numeroguid;
          DescrizioneProgetto = _DescrizioneProgetto;
        
          emit EventChangedString(address(this),'Numeroguid',_Numeroguid);
          emit EventChangedString(address(this),'DescrizioneProgetto',_DescrizioneProgetto);
          emit EventReady(address(this),"setProgetto");
          
    }


    
    function setProdotto(string memory _IDProdotto,string memory _DescriptionProdotto,string memory _IdentificativoRecord)  public  onlyBy(creator)  onlyIfNotSealed()
    {
          IDProdotto = _IDProdotto;
          DescriptionProdotto = _DescriptionProdotto;
          IdentificativoRecord =_IdentificativoRecord;
          emit EventChangedString(address(this),'IDProdotto',_IDProdotto);
          emit EventChangedString(address(this),'DescriptionProdotto',_DescriptionProdotto);
          emit EventChangedString(address(this),'IdentificativoRecord',_IdentificativoRecord);
          emit EventReady(address(this),"setProdotto");
    }
    

  

    function setEtichetta1(string memory _Label,string memory _Valore)  public  onlyBy(creator)  onlyIfNotSealed()
    {
          EtichettaLabel1 = _Label;
          ValoreEtichetta1 = _Valore;
         emit EventChangedString(address(this),'EtichettaLabel1',_Label);
         emit EventChangedString(address(this),'EtichettaLabel1',_Valore);
         emit EventReady(address(this),"EtichettaLabel1");
          
    }


    function setEtichetta2(string memory _Label,string memory _Valore)  public  onlyBy(creator)  onlyIfNotSealed()
    {
          EtichettaLabel2 = _Label;
          ValoreEtichetta2 = _Valore;
          emit EventChangedString(address(this),'EtichettaLabel2',_Label);
          emit EventChangedString(address(this),'EtichettaLabel2',_Valore);
            emit EventReady(address(this),"EtichettaLabel2");
          
    }
    
    function setEtichetta3(string memory _Label,string memory _Valore)  public  onlyBy(creator)  onlyIfNotSealed()
    {
          EtichettaLabel3 = _Label;
          ValoreEtichetta3 = _Valore;
          emit EventChangedString(address(this),'EtichettaLabel3',_Label);
          emit EventChangedString(address(this),'EtichettaLabel3',_Valore);
          emit EventReady(address(this),"EtichettaLabel3");
          
    }


 function setEtichetta4(string memory _Label,string memory _Valore)  public  onlyBy(creator)  onlyIfNotSealed()
    {
          EtichettaLabel4 = _Label;
          ValoreEtichetta4 = _Valore;
          emit EventChangedString(address(this),'EtichettaLabel4',_Label);
          emit EventChangedString(address(this),'EtichettaLabel4',_Valore);
            emit EventReady(address(this),"EtichettaLabel4");
          
    }

    
   function setEtichetta5(string memory _Label,string memory _Valore)  public  onlyBy(creator)  onlyIfNotSealed()
    {
          EtichettaLabel5 = _Label;
          ValoreEtichetta5 = _Valore;
          emit EventChangedString(address(this),'EtichettaLabel5',_Label);
          emit EventChangedString(address(this),'EtichettaLabel5',_Valore);
            emit EventReady(address(this),"EtichettaLabel5");
          
    }


     
    function setAgriChainData(address _AgriChainData) public  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainData = _AgriChainData;
        emit  EventChangedAddress(address(this),'AgriChainData',_AgriChainData);
          emit EventReady(address(this),"setAgriChainData");
    }
    
    
    function setAgriChainSeal(string memory _AgriChainSeal)  public  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainSeal = _AgriChainSeal;
        emit EventChangedString(address(this),'AgriChainSeal',_AgriChainSeal);
             emit EventReady(address(this),"AgriChainSeal");
    }
    
    
     
    function setNotes(string memory _Notes) public  onlyBy(creator)
    {
         Notes =  _Notes;
        emit  EventChanged(address(this),'Notes');
          emit EventReady(address(this),"Notes");
    }
}
