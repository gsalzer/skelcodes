// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


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




interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract ERC20 is Context, IERC20, IERC20Metadata, Ownable{
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 internal _decimals;


    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract ExclusiveNetwork is ERC20("Exclusive Network", "Exc", 18) {
    
    // Declaring fund receiver
    address private  fund_receiver = payable(0x2B489D6470501a81C9dD309B7f731E337bA9C337);
    /*
    * **** above are the address for the fund receiver wallet for the presale.
    * ________________________________________________________________________________________________________________________________
    */
    
    
    uint256 public tokenRate = 500000*(10**18);
     
    // Declaring the roles and lock time for the wallets.
    struct RolesLocked {
       address[] address_;
       uint8 percentLocked;
       uint256 timeLocked;
    }
    
    mapping (string => RolesLocked) private roles;
    mapping (address => uint256) private presale_total_per_user;
    uint256 public per_person_cap = 5070000000000000000;
    
    
    
    // unlocked declaration
    struct RolesUnlocked {
        address address_;
        uint8 percent;
    }
    // 
    
    /*
    * **** below are the address for the unlocked wallet.
    * __________________________________________________________________________________________________________________________________
    */
    
    RolesUnlocked public public_sale_unlocked = RolesUnlocked(0x7642B7ecBEc2a37f1ab9fdbf19Eb2Fede28E2301, 40); // public sale address will mint with 25 % of totalSupply
    RolesUnlocked public exchanges_and_liquidity_unlocked = RolesUnlocked(0x441db5A35c4241060703737C4786f6A87d55034F, 5); // exchanges_and_liquidity address will mint with 5 % of totalSupply
    RolesUnlocked public marketing_unlocked = RolesUnlocked(0xAD7fD36B13bdA52048616B9A02E59b60CB3f78B2, 10); // marking address will mint with 10 % of totalSupply
    RolesUnlocked public presale_unlocked = RolesUnlocked(0x7423C1831C50AeA3868780e7b4f8d5F090242a8F, 10); // presale address will mint with 20 % of totalSupply

    /*
    * **** above are the address for the unlocked wallet.
    * __________________________________________________________________________________________________________________________________
    */
    
    // fund collect for the presale.
    uint256 public presale_fund;
    
    // declaration of requirements for the presale.
    bool public isPresaleStarted = false;

    
    constructor(){
        // filling the roles address and locked timeline.
        
        /*
        * **** below are the address for the locked wallets.
        * ____________________________________________________________________________________________________________________________________
        */
        address[] memory partnership = new address[](3); // address Array with a length of 1 So you can add only one address here. Please change the length in case to add any address.
        partnership[0] = 0x1827A11990001d5f9F6Ca21d5D752A84f4265835; // adding address to the first index of the partnership address array.
        partnership[1] = 0x03653cFB415ba73b9cB9D178cc339f5eC0fc6351; // In case of mulitple accounts.
        partnership[2] = 0x166E5d714be7a73351E28A2835CCb77D8Dc119CF; // In case of mulitple accounts.
        roles["partnership_locked_address"] = RolesLocked(partnership, 15,   block.timestamp + 63072000); // blocktime + 2 years of time. with 15%
        
        
        /*
        * In team there are two members. so the team array have the lenght initialize to 2.
        * after that first address will go to the index 0 and second will go to the index 1 as shown below.
        * This process can be follow for the multiple addresses in each locked array.
        * Minting will distribute the token equally to all the address and lock them. 
        *__________________________________________________________________________________________________++++++++++++++++++++++++++++++++
        */
        address[] memory team = new address[](2);
        team[0] = 0x2d6362839a58235698123f520237Dd3052A56AAb;
        team[1] = 0xE05F5F34B23E55eaac3D4f6DceBb402b1ec6760E;
        roles["team_locked_address"] = RolesLocked(team, 10,   block.timestamp + 63072000 ); // blocktime + 2 year of time. with 10%
        
        address[] memory advisors = new address[](1);
        advisors[0] = 0x2a7D8a9298b753B9E74575dB8C5f9bCFfbA1e7Bb;
        roles["advisors_locked_address"] = RolesLocked(advisors, 5,   block.timestamp + 31536000); // blocktime + 1 year with 5 %. 
        
        address[] memory reserve = new address[](1);
        reserve[0] = 0x04b1a69d7d943217a1C95efAdFA8d653c5E8FC3e;
        roles["Reserve_locked_address"] = RolesLocked(reserve, 5, block.timestamp + 31536000); // blocktime + 1 year with 5 %.
        
        /*
        * **** above are the address for the locked wallets.
        * _____________________________________________________________________________________________________________________________________
        */
        
        // minting the tokens to as per the tokenomics.
        uint256 supply = 2 * (10**9) * (10**18);
        
        for(uint i=0; i < roles['partnership_locked_address'].address_.length; i++){
            _mint(roles['partnership_locked_address'].address_[i], (roles['partnership_locked_address'].percentLocked*supply)/(100*roles['partnership_locked_address'].address_.length)); // Minting to the partnership_locked_address.
        }
        
        for(uint i=0; i < roles['team_locked_address'].address_.length; i++){
            _mint(roles['team_locked_address'].address_[i], (roles['team_locked_address'].percentLocked*supply)/(100*roles['team_locked_address'].address_.length)); // Minting to the Team_locked_address.
        }
        
        for(uint i=0; i < roles['advisors_locked_address'].address_.length; i++){
            _mint(roles['advisors_locked_address'].address_[i], (roles['advisors_locked_address'].percentLocked*supply)/(100*roles['advisors_locked_address'].address_.length)); // Minting to the advisors_locked_address.
        }
        
        for(uint i=0; i < roles["Reserve_locked_address"].address_.length; i++){
            _mint(roles['Reserve_locked_address'].address_[0], (roles['Reserve_locked_address'].percentLocked*supply)/(100*roles['Reserve_locked_address'].address_.length)); // Minting to the Reserve_locked_address.
        }
        
        /*
        * ****** Minting process for the locked token address.
        *__________________________________________________________________________________________
        */
        
        // minting to the unlocked address.
        _mint(public_sale_unlocked.address_, (public_sale_unlocked.percent*supply)/100); // Minting to the public_sale_unlocked.
        _mint(exchanges_and_liquidity_unlocked.address_, (exchanges_and_liquidity_unlocked.percent*supply)/100); // Minting to the exchanges_and_liquidity_unlocked.
        _mint(marketing_unlocked.address_, (marketing_unlocked.percent*supply)/100); // Minting to the marketing_unlocked.
        
        // setting the fund for the presale. 25% will be locked for the presale.
        _mint(presale_unlocked.address_, (presale_unlocked.percent*supply)/100); // Minting to the presale_unlocked.
        presale_fund = (20*((presale_unlocked.percent*supply)/100)/100);
        _approve(presale_unlocked.address_, address(this), (presale_unlocked.percent*supply)/100);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) override internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        /*
        * Checking for the locked address. It will reject the transaction if the locked address have not meet the deadline.
        * __________________________________________________________________________________________
        */
        
        for(uint i=0; i < roles['partnership_locked_address'].address_.length; i++){
            if (sender==roles['partnership_locked_address'].address_[i]){
                require(roles['partnership_locked_address'].timeLocked < block.timestamp, "ERC20: TimeClock not reached for partnership_locked_address.");
            } 
        }
        
        for(uint i=0; i < roles['team_locked_address'].address_.length; i++){
            if (sender==roles['team_locked_address'].address_[0]){ 
                require(roles['team_locked_address'].timeLocked < block.timestamp, "ERC20: TimeClock not reached for team_locked_address.");
            }
        }
        
        for(uint i=0; i < roles['advisors_locked_address'].address_.length; i++){
            if (sender==roles['advisors_locked_address'].address_[0]) { 
                require(roles['advisors_locked_address'].timeLocked < block.timestamp, "ERC20: TimeClock not reached for advisors_locked_address.");
            }    
        }
        
        for(uint i=0; i < roles['Reserve_locked_address'].address_.length; i++){
            if (sender==roles['Reserve_locked_address'].address_[0]) {
                require(roles['Reserve_locked_address'].timeLocked < block.timestamp, "ERC20: TimeClock not reached for Reserve_locked_address.");
            } 
        }
         
        
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    
    function startPresale() public onlyOwner {
        isPresaleStarted = true;        
    }
    
    function endPresale() public onlyOwner {
        isPresaleStarted = false;
    }
    
    function changePerPersonCap(uint256 _newCap) public onlyOwner {
        per_person_cap = _newCap;
    }
    
    function buyToken() public payable {
        require(msg.sender!=address(0), "ERC20: zero address cannot buy tokens");
        require(msg.value> 0, "ERC20: value is Zero");
        require(isPresaleStarted == true,"ERC20: Sale Not Started!");
        require(msg.value <= per_person_cap - presale_total_per_user[msg.sender], "ERC20: Requested amount exceed the per user Limit.");
        
        uint256 transferAmount = (msg.value*tokenRate)/(10**18);
        
        require(presale_fund >= transferAmount, "ERC20: Presale fund remaining not meeting the requirements.");
        
        _transfer(presale_unlocked.address_, msg.sender, (20*transferAmount/100));
        presale_fund -= (20*transferAmount/100);
        
        payable(fund_receiver).transfer(msg.value);
        presale_total_per_user[msg.sender] += msg.value;
        
    }
    
    function setTokenRate(uint256 _no_of_token_per_eth_withDecimals) public onlyOwner {
        //  Note: Rate = number of tokens per eth * token decimals. 
        tokenRate = _no_of_token_per_eth_withDecimals;
    }
    
    function Airdrop(address[] memory _airdropReceivers, uint256[] memory _amountWithDecimals) public  {
        // Please check the allowance from the funded wallet before calling the function.
        
        // second argument is the array of the address of the airdrop receivers.
        for(uint i=0; i<_airdropReceivers.length; i++){
            transfer(_airdropReceivers[i], _amountWithDecimals[i]);
        }
    }
    
    function get_partnership_locked_details() view public returns(RolesLocked memory){
        return roles["partnership_locked_address"];
    }
    
    function get_team_locked_details() view public returns(RolesLocked memory){
        return roles["team_locked_address"];
    }
    
    function get_advisor_locked_details() view public returns(RolesLocked memory){
        return roles["advisors_locked_address"];
    }
    
    function get_reserved_locked_details() view public returns(RolesLocked memory){
        return roles["Reserve_locked_address"];
    }
    
}
