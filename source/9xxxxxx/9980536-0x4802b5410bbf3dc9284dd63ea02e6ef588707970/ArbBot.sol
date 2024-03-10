interface OneSplitI {
  function getExpectedReturn ( address fromToken, address toToken, uint256 amount, uint256 parts, uint256 featureFlags ) external view returns ( uint256 returnAmount, uint256[] memory distribution );
  function isOwner (  ) external view returns ( bool );
  function oneSplitImpl (  ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function setNewImpl ( address impl ) external;
  function swap ( address fromToken, address toToken, uint256 amount, uint256 minReturn, uint256[] calldata distribution, uint256 featureFlags ) external payable;
  function transferOwnership ( address newOwner ) external;
}
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

pragma solidity ^0.5.17;
contract ArbBot {
    address constant public split = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    OneSplitI constant onesplit = OneSplitI(split);
    
    function ratemultiple(address[] memory a,address[] memory b , uint256[] memory amount,uint256 parts, uint256[] memory flags)public view returns(uint256[] memory){
        uint256[] memory z = new uint256[](a.length);
        for (uint i=0; i<a.length; i++){
            ( z[i],) =  onesplit.getExpectedReturn(a[i],b[i],amount[i],parts,flags[i]);
        
        }  
        return z;
    }
    
    
    function buysellrate(address a,address b,uint256 amount,uint256 parts,uint256 flags)view internal returns(uint256) {
            ( uint256 firstoken,) =  onesplit.getExpectedReturn(a,b,amount, parts,flags);
           ( uint256 secondtoken,) =  onesplit.getExpectedReturn(b,a,firstoken, parts,flags);
           return secondtoken;
    } 
        
    function buysellmultiple(address[] memory a,address[] memory b , uint256[] memory amount,uint256 parts, uint256 flags) public view returns(uint256[] memory){
        uint256[] memory z = new uint256[](a.length);
        for (uint i=0; i<a.length; i++){
            z[i] = buysellrate(a[i],b[i],amount[i],parts,flags);
        }  
        return z;

    }
  

}
