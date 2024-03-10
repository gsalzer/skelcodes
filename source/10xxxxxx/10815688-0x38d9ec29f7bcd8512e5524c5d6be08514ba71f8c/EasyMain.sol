/**
 *Submitted for verification at Etherscan.io on 2020-06-05
*/

// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.5.15;
import "./provableAPI_0.5.sol";

contract ADVTokenAbstract {
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function mint(address account, uint256 amount) public;
    function burn(address account, uint256 amount) public;
}

contract EasyMain is usingProvable {
    
    address draftMainAddr;
    ADVTokenAbstract  public advToken =
        ADVTokenAbstract(0x19EA6aCd7604cF8e1271818143573B6Fc16EFd27);

    address payable public owner;
    
    uint256     public      ethusd = 0;
    uint        public      updatePriceFreq = 30 hours;
    
    event SEND_ADV(address indexed _account, uint _amount, bool _bSuccess);
    event LogPriceUpdated(string price);
    event LogNewProvableQuery(string description);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor(uint256 _ethusd) public {
        require(_ethusd > 0);
        ethusd = _ethusd;
        owner = msg.sender;
    }
    
    function setDraftMainAddr(address _addr) external onlyOwner {
        require(_addr != address(0));
        draftMainAddr = _addr;
    }
    
    function setEthUsd(uint256 _ethusd) public onlyOwner {
        require(_ethusd > 0);
        ethusd = _ethusd;
    }
    
    function deposit() external payable {
        
    }
    
    function () external payable {
        require(ethusd > 0);
        uint256 amount = msg.value * ethusd / 100;
        advToken.mint(msg.sender, amount);
        emit SEND_ADV(msg.sender, amount, true);
    }

    function mintADVToken(address to, uint amount) external {
        require(msg.sender == draftMainAddr);
        advToken.mint(to, amount);
    }
    
    function burnADVToken() external {
        require(msg.sender == draftMainAddr);
        advToken.burn(address(this), advToken.balanceOf(address(this)));
    }
    
    function sendADVToken(uint amount) public payable {
        require(amount > 0);
        advToken.mint(msg.sender, amount);
        emit SEND_ADV(msg.sender, amount, true);
    }
    
    function withdrawBalance(uint amount) public onlyOwner {
        require(amount <= address(this).balance);
        (owner).transfer(amount);
    }
    
   function __callback(bytes32 myid, string memory result) public {
       if (msg.sender != provable_cbAddress()) revert();
       ethusd = parseInt(result, 2);
       emit LogPriceUpdated(result);
       updatePrice();
   }

   function updatePrice() public payable {
       if (provable_getPrice("URL") > address(this).balance) {
           emit LogNewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee");
       } else {
           emit LogNewProvableQuery("Provable query was sent, standing by for the answer..");
           provable_query(updatePriceFreq, "URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
       }
   }
}
