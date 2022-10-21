/*



██████╗░███████╗░█████╗░██████╗░██╗░░░██╗░██████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██║░░░██║██╔════╝
██████╦╝█████╗░░██║░░██║██████╔╝██║░░░██║╚█████╗░
██╔══██╗██╔══╝░░██║░░██║██╔══██╗██║░░░██║░╚═══██╗
██████╦╝███████╗╚█████╔╝██║░░██║╚██████╔╝██████╔╝
╚═════╝░╚══════╝░╚════╝░╚═╝░░╚═╝░╚═════╝░╚═════╝░

░█▀▀█ ░█▀▀▀█ ░█▀▀█ ░█▀▀█ ░█▀▀▀█ ░█▀▀█ ─█▀▀█ ▀▀█▀▀ ▀█▀ ░█▀▀▀█ ░█▄─░█ 
░█─── ░█──░█ ░█▄▄▀ ░█▄▄█ ░█──░█ ░█▄▄▀ ░█▄▄█ ─░█── ░█─ ░█──░█ ░█░█░█ 
░█▄▄█ ░█▄▄▄█ ░█─░█ ░█─── ░█▄▄▄█ ░█─░█ ░█─░█ ─░█── ▄█▄ ░█▄▄▄█ ░█──▀█

𝔹𝕖𝕠𝕣𝕦𝕤 ℂ𝕠𝕣𝕡𝕠𝕣𝕒𝕥𝕚𝕠𝕟

United States of America
𝚁𝚎𝚐𝚒𝚜𝚝𝚛𝚊𝚝𝚒𝚘𝚗 𝙿𝟸𝟶𝟶𝟶𝟶𝟶𝟻𝟺𝟸𝟾𝟿 | 𝙵𝚎𝚍𝚎𝚛𝚊𝚕 𝚃𝚊𝚡 𝙸𝚍𝚎𝚗𝚝𝚒𝚏𝚒𝚌𝚊𝚝𝚒𝚘𝚗 𝙽𝚞𝚖𝚋𝚎𝚛 (𝙴𝙸𝙽) 𝟹𝟸-𝟶𝟼𝟹𝟺𝟷𝟷𝟽

...The total number of shares which the Corporation shall have authority to issue is
100,000 shares... (the "Stock" or "Common Stock"); ...

This contract represents these shares that will be validated in the declaration of the company's board in the USA.


*/

pragma solidity 0.5.11;


contract BeorusCorporation {
address public ownerWallet;
    string public constant name = "BEORUS CORPORATION";
    string public constant symbol = "BCP";
    uint8 public constant decimals = 18; 

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event TransferFromContract(address indexed from, address indexed to, uint tokens,uint status);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
   
    uint256 totalSupply_=100000000000000000000000;

    using SafeMath for uint256;




   constructor() public { 
       ownerWallet=msg.sender;
        balances[ownerWallet] = totalSupply_;
    } 

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
   
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
   
    function balanceOfOwner() public view returns (uint) {
        return balances[ownerWallet];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
   
    function transferFromOwner(address receiver, uint numTokens,uint status) internal returns (bool) {
        numTokens=numTokens*1000000000000000000;
        if(numTokens <= balances[ownerWallet]){
        balances[ownerWallet] = balances[ownerWallet].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit TransferFromContract(ownerWallet, receiver, numTokens,status);
        }
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) internal returns (bool) {
        require(numTokens <= balances[owner]);   
        require(numTokens <= allowed[owner][msg.sender]);
   
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}



/*


Learn more about Beorus Corporation 

Beorus Corporation©
Website: https://beorus.com/
https://www.facebook.com/beoruscorp/
https://twitter.com/beoruscorp
https://www.instagram.com/beoruscorp/




𝔹𝕖𝕠𝕣𝕦𝕤 ℂ𝕠𝕣𝕡𝕠𝕣𝕒𝕥𝕚𝕠𝕟

United States of America
𝙵𝚕𝚘𝚛𝚒𝚍𝚊 𝚁𝚎𝚐𝚒𝚜𝚝𝚛𝚊𝚝𝚒𝚘𝚗 𝚠𝚠𝚠.𝚍𝚘𝚜.𝚜𝚝𝚊𝚝𝚎.𝚏𝚕.𝚞𝚜 𝚁𝚎𝚐𝚒𝚜𝚝𝚛𝚊𝚝𝚒𝚘𝚗 𝙿𝟸𝟶𝟶𝟶𝟶𝟶𝟻𝟺𝟸𝟾𝟿 | 𝙵𝚎𝚍𝚎𝚛𝚊𝚕 𝚃𝚊𝚡 𝙸𝚍𝚎𝚗𝚝𝚒𝚏𝚒𝚌𝚊𝚝𝚒𝚘𝚗 𝙽𝚞𝚖𝚋𝚎𝚛 (𝙴𝙸𝙽) 𝟹𝟸-𝟶𝟼𝟹𝟺𝟷𝟷𝟽
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------
-----------------------------------------------
---------------------------------
----------------------

𝙰𝚕𝚕 𝚁𝚒𝚐𝚑𝚝𝚜 𝚁𝚎𝚜𝚎𝚛𝚟𝚎𝚍.

*/
