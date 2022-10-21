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

contract Draft90TokenAbstract {
    function mint(address account, uint256 amount) public;
    function burn(address account, uint256 amount) public;
    function balanceOf(address tokenOwner) public view returns (uint balance);
}

contract Draft180TokenAbstract {
    function mint(address account, uint256 amount) public;
    function burn(address account, uint256 amount) public;
    function balanceOf(address tokenOwner) public view returns (uint balance);
}

contract Draft270TokenAbstract {
    function mint(address account, uint256 amount) public;
    function burn(address account, uint256 amount) public;
    function balanceOf(address tokenOwner) public view returns (uint balance);
}

contract ADVMainAbstract {
    function mintADVToken(address to, uint amount) external;
    function burnADVToken() external;
}

contract IERC20Token {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract DraftMain is usingProvable {
    Draft90TokenAbstract  public d90Token =
        Draft90TokenAbstract(0x50c26bDD0cCB78Ad61c7224b951E8caCCbC40319);
        
    Draft180TokenAbstract  public d180Token =
        Draft180TokenAbstract(0x11D25fd9bD9220564b0C942f950833Dc6ADd2D21);
        
    Draft270TokenAbstract  public d270Token =
        Draft270TokenAbstract(0x8b7A5234CdbB856d0712D4c63cb31a5Ed6f8d3D8);
    
    address public easyMainAddr;
    address public advTokenAddr;
    
    address payable public owner;
    
    struct LockList {
        address account;
        uint256 amount;
        uint256 time;
    }
    
    uint256     public      ethusd = 0;
    uint        public      updatePriceFreq = 30 hours;
    
    uint constant  d90Limit = 256 * 10**18;
    uint constant  d180Limit = 512 * 10**18;
    uint constant  d270Limit = 768 * 10**18;
    
    LockList[]  public  d90LockList;
    LockList[]  public  d180LockList;
    LockList[]  public  d270LockList;
    
    address payable public xi;
    address payable public mariano;
    address payable public marketing;
    address payable public vault;
    
    uint        public d90Index;
    uint        public d180Index;
    uint        public d270Index;
    
    uint        public d90LockedAmount;
    uint        public d180LockedAmount;
    uint        public d270LockedAmount;
    
    event LogPriceUpdated(string price);
    event LogNewProvableQuery(string description);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address payable _xi, address payable _mariano, address payable _marketing, address payable _vault, uint256 _ethusd) public {
        require(_xi != address(0x0));
        require(_mariano != address(0x0));
        require(_marketing != address(0x0));
        require(_vault != address(0x0));
        require(_ethusd > 0);
        
        xi = _xi;
        mariano = _mariano;
        marketing = _marketing;
        vault  = _vault;
        ethusd = _ethusd;   
        owner = msg.sender;
        
        d90Index = 0;
        d180Index = 0;
        d270Index = 0;
        
    }
    
    function setEasymainAddr(address _addr) public onlyOwner {
        require(_addr != address(0));
        easyMainAddr = _addr;
    }
    
    function setAdvTokenAddr(address _addr) public onlyOwner {
        require(_addr != address(0));
        advTokenAddr = _addr;
    }
    
    function buyDraftTokenByADV(uint amount, address payable sponsor) public {
        require(sponsor != address(0x0));
        require(amount > 0);
        uint diffAmount = 0;

        require(IERC20Token(advTokenAddr).allowance(msg.sender, address(this)) >= amount * 15);
        
        IERC20Token(advTokenAddr).transferFrom(msg.sender, easyMainAddr, amount * 15);
        
        d90Token.mint(msg.sender, amount);
        d180Token.mint(msg.sender, amount);
        d270Token.mint(msg.sender, amount);
        
        d90LockList.push(LockList(msg.sender, amount, now));
        d180LockList.push(LockList(msg.sender, amount, now));
        d270LockList.push(LockList(msg.sender, amount, now));
        
        d90LockedAmount = d90LockedAmount + amount;
        d180LockedAmount = d180LockedAmount + amount;
        d270LockedAmount = d270LockedAmount + amount;
        
        while (d90LockedAmount > d90Limit) {
            diffAmount = d90LockedAmount - d90Limit;
            if (d90LockList[d90Index].amount > diffAmount) {
                d90LockList[d90Index].amount = d90LockList[d90Index].amount - diffAmount;
                d90LockedAmount = d90LockedAmount - diffAmount;
            } else {
                d90LockedAmount = d90LockedAmount - d90LockList[d90Index].amount;
                delete d90LockList[d90Index];
                d90Index ++;
            }
        }
        
        while (d180LockedAmount > d180Limit) {
            diffAmount = d180LockedAmount - d180Limit;
            if (d180LockList[d180Index].amount > diffAmount) {
                d180LockList[d180Index].amount = d180LockList[d180Index].amount - diffAmount;
                d180LockedAmount = d180LockedAmount - diffAmount;
            } else {
                d180LockedAmount = d180LockedAmount - d180LockList[d180Index].amount;
                delete d180LockList[d180Index];
                d180Index ++;
            }
        }
        
        while (d270LockedAmount > d270Limit) {
            diffAmount = d270LockedAmount - d270Limit;
            if (d270LockList[d270Index].amount > diffAmount) {
                d270LockList[d270Index].amount = d270LockList[d270Index].amount - diffAmount;
                d270LockedAmount = d270LockedAmount - diffAmount;
            } else {
                d270LockedAmount = d270LockedAmount - d270LockList[d270Index].amount;
                delete d270LockList[d270Index];
                d270Index ++;
            }
        }
        
        ADVMainAbstract(easyMainAddr).burnADVToken();
        
        // uint oneper = amount * 1500 / ethusd / 100;
        uint oneper = amount * 15 / ethusd;
        address(xi).transfer(oneper);
        address(mariano).transfer(oneper);
        address(marketing).transfer(oneper * 8);
        address(sponsor).transfer(oneper * 10);
        address(vault).transfer(oneper * 50);
    }
    
    function buyDraftTokenByETH(uint amount, address payable sponsor) public payable {
        require(sponsor != address(0x0));
        require(amount > 0);
        uint diffAmount = 0;
        // for(uint i = 0; i < amount; i ++) {
            
        // d90LockList[d90Index + i].account = msg.sender;
        // d90LockList[d90Index + i].time = now;
        
        // d180LockList[d180Index + i].account = msg.sender;
        // d180LockList[d180Index + i].time = now;
        
        // d270LockList[d270Index + i].account = msg.sender;
        // d270LockList[d270Index + i].time = now;
        
        require(msg.value >= amount * 1500 / ethusd);
        
        d90Token.mint(msg.sender, amount);
        d180Token.mint(msg.sender, amount);
        d270Token.mint(msg.sender, amount);
        
        d90LockList.push(LockList(msg.sender, amount, now));
        d180LockList.push(LockList(msg.sender, amount, now));
        d270LockList.push(LockList(msg.sender, amount, now));
        
        d90LockedAmount = d90LockedAmount + amount;
        d180LockedAmount = d180LockedAmount + amount;
        d270LockedAmount = d270LockedAmount + amount;
        
        while (d90LockedAmount > d90Limit) {
            diffAmount = d90LockedAmount - d90Limit;
            if (d90LockList[d90Index].amount > diffAmount) {
                d90LockList[d90Index].amount = d90LockList[d90Index].amount - diffAmount;
                d90LockedAmount = d90LockedAmount - diffAmount;
            } else {
                d90LockedAmount = d90LockedAmount - d90LockList[d90Index].amount;
                delete d90LockList[d90Index];
                d90Index ++;
            }
        }
        
        while (d180LockedAmount > d180Limit) {
            diffAmount = d180LockedAmount - d180Limit;
            if (d180LockList[d180Index].amount > diffAmount) {
                d180LockList[d180Index].amount = d180LockList[d180Index].amount - diffAmount;
                d180LockedAmount = d180LockedAmount - diffAmount;
            } else {
                d180LockedAmount = d180LockedAmount - d180LockList[d180Index].amount;
                delete d180LockList[d180Index];
                d180Index ++;
            }
        }
        
        while (d270LockedAmount > d270Limit) {
            diffAmount = d270LockedAmount - d270Limit;
            if (d270LockList[d270Index].amount > diffAmount) {
                d270LockList[d270Index].amount = d270LockList[d270Index].amount - diffAmount;
                d270LockedAmount = d270LockedAmount - diffAmount;
            } else {
                d270LockedAmount = d270LockedAmount - d270LockList[d270Index].amount;
                delete d270LockList[d270Index];
                d270Index ++;
            }
        }
        
        uint oneper = msg.value / 100;
        address(xi).transfer(oneper);
        address(mariano).transfer(oneper);
        address(marketing).transfer(oneper * 8);
        address(sponsor).transfer(oneper * 10);
        address(vault).transfer(oneper * 50);
    }
    
    function getD90LockedAmount(address account) public view returns (uint) {
        uint res = 0;
        for (uint i = d90Index; i < d90LockList.length; i ++) {
            if (d90LockList[i].account == account) {
                    res = res + d90LockList[i].amount;
            }
        }
        return res;
    }
    
    function getD180LockedAmount(address account) public view returns (uint) {
        uint res = 0;
        for (uint i = d180Index; i < d180LockList.length; i ++) {
            if (d180LockList[i].account == account) {
                    res = res + d180LockList[i].amount;
            }
        }
        return res;
    }
    
    function getD270LockedAmount(address account) public view returns (uint) {
        uint res = 0;
        for (uint i = d270Index; i < d270LockList.length; i ++) {
            if (d270LockList[i].account == account) {
                    res = res + d270LockList[i].amount;
            }
        }
        return res;
    }
    
    function getD90AvailableAmount(address account) public view returns(uint) {
        uint lockedAmount = getD90LockedAmount(account);
        uint balance = d90Token.balanceOf(account);
        uint res = 0;
        if (balance >= lockedAmount)
            res = balance - lockedAmount;
        return res;
    }
    
    function getD180AvailableAmount(address account) public view returns(uint) {
        uint lockedAmount = getD180LockedAmount(account);
        uint balance = d180Token.balanceOf(account);
        uint res = 0;
        if (balance >= lockedAmount)
            res = balance - lockedAmount;
        return res;
    }
    
    function getD270AvailableAmount(address account) public view returns(uint) {
        uint lockedAmount = getD270LockedAmount(account);
        uint balance = d270Token.balanceOf(account);
        uint res = 0;
        if (balance >= lockedAmount)
            res = balance - lockedAmount;
        return res;
    }
    
    function () external payable {

    }
    
    function claimD90Token(uint amount) public {
        uint availableAmount = getD90AvailableAmount(msg.sender);
        require(availableAmount >= amount);
        d90Token.burn(msg.sender, amount);
        address(msg.sender).transfer(amount * 750 / ethusd);
    }
    
    function claimD180Token(uint amount) public {
        require(getD180AvailableAmount(msg.sender) >= amount);
        d180Token.burn(msg.sender, amount);
        address(msg.sender).transfer(amount * 750 / ethusd);
    }
    
    function claimD270Token(uint amount) public {
        require(getD270AvailableAmount(msg.sender) >= amount);
        d270Token.burn(msg.sender, amount);
        address(msg.sender).transfer(amount * 750 / ethusd);
    }
    
    function updateETHPrice(uint price) public onlyOwner {
        require(price > 0);
        ethusd = price;
    }
    
    function unlockTimedToken() public onlyOwner {
        while (now - d90LockList[d90Index].time >= 90 days) {
            d90LockedAmount = d90LockedAmount - d90LockList[d90Index].amount;
            delete d90LockList[d90Index];
            d90Index ++;
        }
        
        while (now - d180LockList[d180Index].time >= 180 days) {
            d180LockedAmount = d180LockedAmount - d180LockList[d180Index].amount;
            delete d180LockList[d180Index];
            d180Index ++;
        }
        
        while (now - d270LockList[d270Index].time >= 270 days) {
            d270LockedAmount = d270LockedAmount - d270LockList[d270Index].amount;
            delete d270LockList[d270Index];
            d270Index ++;
        }
    }

    function sendEth(address payable to, uint amount) public onlyOwner {
        require(to != address(0));
        require(address(this).balance >= amount);
        to.transfer(amount);
    }
    
    function setEthUsd(uint256 _ethusd) public onlyOwner {
        require(_ethusd > 0);
        ethusd = _ethusd;
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
    
    function withdrawBalance(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        (owner).transfer(amount);
    }
}

