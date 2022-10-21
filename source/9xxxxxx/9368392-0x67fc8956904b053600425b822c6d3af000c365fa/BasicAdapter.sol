/**

Deployed by Ren Project, https://renproject.io

Commit hash: 9be1a5a
Repository: https://github.com/renproject/darknode-sol
Issues: https://github.com/renproject/darknode-sol/issues

Licenses
openzeppelin-solidity: (MIT) https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
darknode-sol: (GNU GPL V3) https://github.com/renproject/darknode-sol/blob/master/LICENSE

*/

pragma solidity ^0.5.8;


interface IShifter {
    function shiftIn(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function shiftOut(bytes calldata _to, uint256 _amount) external returns (uint256);
    function shiftInFee() external view returns (uint256);
    function shiftOutFee() external view returns (uint256);
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IShifterRegistry {

    
    
    event LogShifterRegistered(string _symbol, string indexed _indexedSymbol, address indexed _tokenAddress, address indexed _shifterAddress);
    event LogShifterDeregistered(string _symbol, string indexed _indexedSymbol, address indexed _tokenAddress, address indexed _shifterAddress);
    event LogShifterUpdated(address indexed _tokenAddress, address indexed _currentShifterAddress, address indexed _newShifterAddress);

    
    function getShifters(address _start, uint256 _count) external view returns (IShifter[] memory);

    
    function getShiftedTokens(address _start, uint256 _count) external view returns (IERC20[] memory);

    
    
    
    
    function getShifterByToken(address _tokenAddress) external view returns (IShifter);

    
    
    
    
    function getShifterBySymbol(string calldata _tokenSymbol) external view returns (IShifter);

    
    
    
    
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}

contract BasicAdapter {

   function shiftIn(
       
       IShifterRegistry _shifterRegistry,
       string calldata _symbol,
       address         _address,
       
       uint256         _amount,
       bytes32         _nonce,
       bytes calldata  _sig
   ) external {
       bytes32 payloadHash = keccak256(abi.encode(_shifterRegistry, _symbol, _address));
       uint256 amount = _shifterRegistry.getShifterBySymbol(_symbol).shiftIn(payloadHash, _amount, _nonce, _sig);
       _shifterRegistry.getTokenBySymbol(_symbol).transfer(_address, amount);
   }

   function shiftOut(
       IShifterRegistry _shifterRegistry,
       string calldata _symbol,
       bytes calldata _to,
       uint256        _amount
   ) external {
       require(_shifterRegistry.getTokenBySymbol(_symbol).transferFrom(msg.sender, address(this), _amount), "token transfer failed");
       _shifterRegistry.getShifterBySymbol(_symbol).shiftOut(_to, _amount);
   }
}
