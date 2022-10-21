pragma solidity ^0.4.24;

import "Proxy.sol";
import "AuthModule.sol";
import "TokenModule.sol";
import "Authorization.sol";
import "SafeMath.sol";
import "LibMapAddressBool.sol";
import "StringUtils.sol";


contract StorageModule is Authorization {

    using SafeMath for uint256;
    using LibMapAddressBool for LibMapAddressBool.MapAddressBool;
    using StringUtils for string;

    LibMapAddressBool.MapAddressBool shareholders;
    mapping(address => bool) investorWhitelist;
    mapping(address => bool) investorBlacklist;
    mapping(address => InvestorInfo) investorInfo;
    mapping(address => InvestorDocument) investorDocuments;
    mapping(uint => address) usedHashid;

    mapping(bytes32 => uint256) retailInvestorCounts;
    mapping(bytes32 => mapping(address => uint256)) retailInvestors;
    
    bool public isTXFrozen;
    uint256 public shareholderMaxAmount;
    string[] public allowCountrys;

    event AddInvestorToWhitelist(address _investor);
    event AddInvestorsToWhitelist(address[] _investors);
    event RemoveInvestorFromWhitelist(address _investor);
    event UpdateBlacklist(address[] _investors, bool _black);
    event SetShareholderMaxAmount(uint _oldValue, uint _newValue);
    event InitShareholders(address[] _shareholders, bool _original);
    event AddShareholder(address _shareholder, uint _balance);
    event RemoveShareholder(address _shareholder, uint _balance);
    // event AddInvestorInfo(address _investor, uint hashid, string _country, bool _kyc, uint _validDate);
    event UpdateInvestorInfo(address _investor, uint hashid, string _country, bool _kyc, uint _validDate, bool _pi);
    // event AddDocument(address _investor, string _url, uint _hash);
    event UpdateDocument(address _investor, string _url, uint _hash);

    struct Shareholder {
        bool inited;
        bool original;
    }

    //专业投资者 Pi,合规投资者,前x名合规投资者
    struct InvestorInfo {
        bool inited;
        uint hashid; //是投资者所有资料串在一起的hash值
        string country;//地区
        bool kyc;// 合规投资者认证
        uint validDate;
        bool pi; //is professional, pi和kyc必须要有一个是true
    }

    struct InvestorDocument {
        string url;
        uint hash;
    }

    constructor(address _proxy) public Authorization(_proxy) {
        
    }

    function freezeTX(bool _freeze) public onlyAdmin(msg.sender) whenNotPaused {
        isTXFrozen = _freeze;
    }

    function addInvestorToWhitelist(address _investor) external onlyIssuerOrExchange(msg.sender) whenNotPaused {
        investorWhitelist[_investor] = true;
        emit AddInvestorToWhitelist(_investor);
    }

    function addInvestorsToWhitelist(address[] _investors) external onlyIssuerOrExchange(msg.sender) whenNotPaused {
        for(uint i = 0; i < _investors.length; i++) {
            investorWhitelist[_investors[i]] = true;
        }
        emit AddInvestorsToWhitelist(_investors);
    }

    function updateBlacklist(address[] _investors, bool _black) external onlyIssuerOrExchange(msg.sender) whenNotPaused {
        for(uint i = 0; i < _investors.length; i++) {
            investorBlacklist[_investors[i]] = _black;
        }
        emit UpdateBlacklist(_investors, _black);
    }

    function removeInvestorFromWhitelist(address _investor) external onlyIssuerOrExchange(msg.sender) whenNotPaused {
        delete investorWhitelist[_investor];
        emit RemoveInvestorFromWhitelist(_investor);
    }

    function addRetailInvestor(address _investor) external onlyIssuerOrExchange(msg.sender) whenNotPaused {
        bytes32 _country= getInvestorCountry(_investor);
        if(retailInvestors[_country][_investor] != 0)
            return;
        retailInvestors[_country][_investor] = ++retailInvestorCounts[_country];
    }

    function getRetailInvestorCount(bytes32 _country) external view returns (uint256) {
        return retailInvestorCounts[_country];
    }

    function getRetailInvestor(address _investor) external view returns (uint256) {
        bytes32 _country= getInvestorCountry(_investor);
        return retailInvestors[_country][_investor];
    }

    function isInvestorInWhitelist(address _investor) external view returns (bool) {
        return investorWhitelist[_investor];
    }

    function isInBlacklist(address _investor) external view returns (bool) {
        return investorBlacklist[_investor];
    }

    function isProfessionalInvestor(address _investor) external view returns (bool) {
        return investorInfo[_investor].pi;
    }

    function setShareholderMaxAmount(uint256 _shareholderMaxAmount) public onlyIssuer(msg.sender) whenNotPaused {
        uint256 preValue = shareholderMaxAmount;
        shareholderMaxAmount = _shareholderMaxAmount;
        emit SetShareholderMaxAmount(preValue, shareholderMaxAmount);
    }

    // called after mint
    function initShareholders(address[] _shareholders, bool _original) public onlyInside(msg.sender) whenNotPaused {
        for(uint i = 0; i < _shareholders.length; i++) {
            shareholders.add(_shareholders[i], _original);
        }
        emit InitShareholders(_shareholders, _original);
    }

    // called after transaction or burn
    function updateShareholders(address _from, address _to) public onlyInside(msg.sender) whenNotPaused {
        TokenModule token = TokenModule(proxy.getModule("TokenModule"));
        uint balanceFrom = token.balanceOf(_from);
        uint balanceTo = token.balanceOf(_to);
        if(balanceFrom == 0)
            removeShareholder(_from, 0);
        // no need to check investors amount here, cause ComplicanceModule will do the job.
        // _to will be 0 while burn
        if(_to != address(0))
            addShareholder(_to, balanceTo); 
    }  

    function addShareholder(address _shareholder, uint _balance) private {
        bool newAdded = shareholders.add(_shareholder, false);
        if(newAdded)
            emit AddShareholder(_shareholder, _balance);
    }

    function removeShareholder(address _shareholder, uint _balance) private {
        bool removed = shareholders.remove(_shareholder);
        if(removed)
            emit RemoveShareholder(_shareholder, _balance);
    }

    function shareholderAmount() public view returns (uint256) {
        return shareholders.length;
    }

    function isShareholder(address _address) public view returns (bool) {
        return shareholders.contain(_address);
    }
    
    function shareholderExceeded(uint amount) public view returns (bool) {
        return shareholders.length + amount > shareholderMaxAmount;
    }

    function getInvestorCountry(address _address) public view returns (bytes32 result) {
        string memory country = investorInfo[_address].country;
        assembly {
            result := mload(add(country, 32))
        }
    }

    // function addInvestorInfo(
    //     address _investor, 
    //     uint _investorHash,
    //     string _country, 
    //     bool _kyc, 
    //     uint _validDate
    // ) 
    //     external 
    //     onlyIssuerOrExchange(msg.sender) 
    // {
    //     require(investorInfo[_investor].inited == false, "Investor already exists");
    //     investorInfo[_investor] = InvestorInfo(true, _investorHash, _country, _kyc, _validDate);
    //     emit AddInvestorInfo(_investor, _investorHash, _country, _kyc, _validDate);
    // }

    function updateInvestorInfo(
        address _investor, 
        uint _hashid,
        string _country, 
        bool _kyc, 
        uint _validDate ,
        bool _pi
    ) 
        external 
        onlyIssuerOrExchange(msg.sender) 
        whenNotPaused
        returns(bool)
    {
        // require(investorInfo[_investor].inited == true, "Investor do not exist");
        bool temp_pi = true; //temp_pi = _pi; // force set all guys is professional.
        require (_kyc || temp_pi, "require _kyc or _pi at less one be true");
        require (isAllowCountry(_country), "country not allow");
        require (_hashid != 0);
        require (usedHashid[_hashid] == address(0) || usedHashid[_hashid] == _investor);
        
        //uint oldhashid = investorInfo[_investor].hashid;
        investorInfo[_investor] = InvestorInfo(true, _hashid, _country, _kyc, _validDate, temp_pi);
        usedHashid[_hashid] = _investor;
        //if (oldhashid != _hashid) //
        //    delete usedHashid[oldhashid];
        emit UpdateInvestorInfo(_investor, _hashid, _country, _kyc, _validDate, temp_pi);
        return true;
    }

    function getInvestorInfo(address _investor) public view returns (uint, string, bool, uint, bool) {
        InvestorInfo storage info = investorInfo[_investor];
        return (info.hashid, info.country, info.kyc, info.validDate, info.pi);
    }

    // function addDocument(
    //     address _investor, 
    //     string _url, 
    //     uint _hash
    // ) 
    //     external 
    //     onlyIssuerOrExchange(msg.sender) 
    // {
    //     InvestorDocument storage doc = investorDocuments[_investor];
    //     require(doc.hash == 0, "Investor document already exists");
    //     investorDocuments[_investor] = InvestorDocument(_url, _hash);
    //     emit AddDocument(_investor, _url, _hash);
    // }

    function updateDocument(
        address _investor, 
        string _url, 
        uint _hash
    ) 
        external 
        onlyIssuerOrExchange(msg.sender) 
        whenNotPaused
    {
        // InvestorDocument storage doc = investorDocuments[_investor];
        // require(doc.hash != 0, "Investor document do not exists");
        investorDocuments[_investor] = InvestorDocument(_url, _hash);
        emit UpdateDocument(_investor, _url, _hash);
    }

    function getDocument(address _investor) external view returns (string, uint) {
        InvestorDocument storage doc = investorDocuments[_investor];
        return (doc.url, doc.hash);
    }

    function addAllowCountrys(string _country)
        external 
        onlyIssuerOrExchange(msg.sender)
        returns (bool)
    {
        bytes memory strmemct = bytes(_country);
        require (strmemct.length > 0, "country can not empty");

        uint aclen = allowCountrys.length;
        uint firstEmptyPlace = aclen;
        for (uint i=0; i < aclen; i++)
        {
            if (allowCountrys[i].equal(_country))
                return false;
            bytes memory strmem = bytes(allowCountrys[i]);
            if (strmem.length == 0 && firstEmptyPlace == aclen)
                firstEmptyPlace = i;
        }
        if (firstEmptyPlace != aclen)
            allowCountrys[firstEmptyPlace] = _country;
        else
            allowCountrys.push(_country);
        return true;
    }

    function removeAllowCountrys(string _country) 
        external
        onlyIssuerOrExchange(msg.sender)
        returns (bool) 
    {
        uint aclen = allowCountrys.length;
        for (uint i=0; i < aclen; i++)
        {
            if (allowCountrys[i].equal(_country))
            {
                delete allowCountrys[i];
                return true;
            }
        }
        return false;
    }

    function isAllowCountry(string _country)
        public
        returns(bool)
    {
        uint aclen = allowCountrys.length;
        for (uint i=0; i < aclen; i++)
        {
            if (allowCountrys[i].equal(_country)) {
                return true;
            }
        }
        return false;
    }
}
