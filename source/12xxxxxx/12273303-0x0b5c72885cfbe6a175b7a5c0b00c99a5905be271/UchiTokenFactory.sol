/// SPDX-License-Identifier: GPL-3.0-or-later
/*
 ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌
▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌ ▀▀▀▀█░█▀▀▀▀ 
▐░▌       ▐░▌▐░▌          ▐░▌       ▐░▌     ▐░▌     
▐░▌       ▐░▌▐░▌          ▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     
▐░▌       ▐░▌▐░▌          ▐░░░░░░░░░░░▌     ▐░▌     
▐░▌       ▐░▌▐░▌          ▐░█▀▀▀▀▀▀▀█░▌     ▐░▌     
▐░▌       ▐░▌▐░▌          ▐░▌       ▐░▌     ▐░▌     
▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌ ▄▄▄▄█░█▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀ */
pragma solidity 0.8.3;

/// @notice Interface for SushiSwap pair creation and ETH liquidity provision.
interface ISushiSwapLaunch {
    function approve(address to, uint amount) external returns (bool); 
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

/// @notice Whitelist ERC20 token with SushiSwap launch.
contract UchiToken {
    ISushiSwapLaunch constant sushiSwapFactory=ISushiSwapLaunch(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    address constant sushiSwapRouter=0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant wETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address public governance;
    string public name;
    string public symbol;
    uint8 constant public decimals=18;
    uint public totalSupply;
    uint immutable public totalSupplyCap;
    bool public uchiRestricted;
    
    mapping(address=>mapping(address=>uint)) public allowance;
    mapping(address=>uint) public balanceOf;
    mapping(address=>bool) public uchi;
    
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
    event UpdateUchi(address indexed account, bool approved);
    
    constructor(
        address[] memory _uchi, // initial whitelist array of accounts
        string memory _name, // erc20-formatted UchiToken 'name'
        string memory _symbol, // erc20-formatted UchiToken 'symbol'
        uint _totalSupplyCap, // supply cap for UchiToken mint
        uint pairDistro, // UchiToken amount minted for `sushiPair`
        uint[] memory uchiDistro, // UchiToken amount minted to `uchi`
        bool market // if 'true', launch pair and add ETH liquidity on SushiSwap via 'Factory'
    ){
        for(uint i=0;i<_uchi.length;i++){
            balanceOf[_uchi[i]]=uchiDistro[i];
            totalSupply+=uchiDistro[i];
            uchi[_uchi[i]]=true;
            emit Transfer(address(0), _uchi[i], uchiDistro[i]);}
        if(market){
            address sushiPair=sushiSwapFactory.createPair(address(this), wETH);
            uchi[msg.sender]=true;
            uchi[sushiSwapRouter]=true;
            uchi[sushiPair]=true;
            balanceOf[msg.sender]=pairDistro;
            totalSupply+=pairDistro;
            emit Transfer(address(0), msg.sender, pairDistro);}
        require(totalSupply<=_totalSupplyCap,'capped'); 
        governance=_uchi[0]; // first `uchi` is `governance`
        name=_name;
        symbol=_symbol;
        totalSupplyCap=_totalSupplyCap;
        uchiRestricted=true;
        balanceOf[address(this)]=type(uint).max; // max local balance blocks sends to UchiToken via overflow check (+saves gas)
    }

    /// - RESTRICTED ERC20 - ///
    function approve(address to, uint amount) external returns (bool) {
        allowance[msg.sender][to]=amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }
    
    function transfer(address to, uint amount) external returns (bool) {
        if(uchiRestricted){require(uchi[msg.sender]&&uchi[to],'!uchi');}
        balanceOf[msg.sender]-=amount;
        balanceOf[to]+=amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint amount) external returns (bool) {
        if(uchiRestricted){require(uchi[from]&&uchi[to],'!uchi');}
        allowance[from][msg.sender]-=amount;
        balanceOf[from]-=amount;
        balanceOf[to]+=amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    /// - GOVERNANCE - ///
    modifier onlyGovernance {
        require(msg.sender==governance,'!governance');
        _;
    }
    
    function mint(address to, uint amount) external onlyGovernance {
        require(totalSupply+amount<=totalSupplyCap,'capped'); 
        balanceOf[to]+=amount; 
        totalSupply+=amount; 
        emit Transfer(address(0), to, amount); 
    }
    
    function transferGovernance(address _governance) external onlyGovernance {
        governance=_governance;
    }

    function updateUchi(address[] calldata account, bool[] calldata approved) external onlyGovernance {
        for(uint i=0;i<account.length;i++){
            uchi[account[i]]=approved[i];
            emit UpdateUchi(account[i], approved[i]);
        }
    }

    function updateUchiRestriction(bool _uchiRestricted) external onlyGovernance {
        uchiRestricted=_uchiRestricted;
    }
}

/// @notice Factory for UchiToken deployment.
contract UchiTokenFactory {
    ISushiSwapLaunch constant sushiSwapRouter=ISushiSwapLaunch(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    address public uchiDAO=msg.sender;

    mapping(address=>uint) public uchiList;
    
    event DeployUchiToken(address indexed uchiToken);
    event UpdateUchiList(address indexed account, uint indexed list, string details);
    
    function deployUchiToken(
        address[] calldata _uchi, // initial whitelist array of accounts
        string calldata _name, // erc20-formatted UchiToken 'name'
        string calldata _symbol, // erc20-formatted UchiToken 'symbol'
        uint _totalSupplyCap, // supply cap for UchiToken mint
        uint pairDistro, // UchiToken amount minted for `sushiPair`
        uint[] calldata uchiDistro, // UchiToken amount minted to `uchi`
        uint list, // if not '0', add check to `uchi` against given `uchiList`
        bool market // if 'true', launch pair and add ETH liquidity on SushiSwap
    ) external payable returns (UchiToken uchiToken) {
        if(list!=0){checkList(_uchi, list);}
        uchiToken=new UchiToken(
            _uchi,
            _name, 
            _symbol,
            _totalSupplyCap,
            pairDistro,
            uchiDistro,
            market);
        if(market){
            uchiToken.approve(address(sushiSwapRouter), pairDistro);
            initMarket(_uchi[0], address(uchiToken), pairDistro);}
        emit DeployUchiToken(address(uchiToken));
    }
    
    function checkList(address[] calldata _uchi, uint list) private view { // deployment helper to avoid 'stack too deep' error
        for(uint i=0;i<_uchi.length;i++){require(uchiList[_uchi[i]]==list,'!listed');}
    }
    
    function initMarket(address governance, address uchiToken, uint pairDistro) private { // deployment helper to avoid 'stack too deep' error
        sushiSwapRouter.addLiquidityETH{value: msg.value}(uchiToken, pairDistro, 0, 0, governance, 2533930386);
    }
    
    /// - GOVERNANCE - ///
    function transferGovernance(address _uchiDAO) external {
        require(msg.sender==uchiDAO,'!uchiDAO');
        uchiDAO=_uchiDAO;
    }
    
    function updateUchiList(address[] calldata account, uint[] calldata list, string calldata details) external { // `0` is default and delisting action
        require(msg.sender==uchiDAO,'!uchiDAO');
        for(uint i=0;i<account.length;i++){
            uchiList[account[i]]=list[i]; 
            emit UpdateUchiList(account[i], list[i], details);
        }
    }
}
