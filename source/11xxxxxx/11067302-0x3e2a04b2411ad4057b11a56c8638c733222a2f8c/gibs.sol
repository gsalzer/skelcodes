pragma solidity ^0.7.2;

import "./ERC20.sol";
import "./set.sol";
import "./uniswap.sol";
import "./PExt.sol";
import "./ERC20HolderList.sol";

contract Gibs is ERC20WithHoldersSet, Ownable {
    using SafeMath for uint256;
    using AddressSet for AddressSet.Set;
    using AddrArrayLib for AddrArrayLib.Addresses;

    ERC20 internal WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public gibsTreasuryAddress = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    IUniswapV2Factory internal uniswapFactory;
    IUniswapV2Router02 internal uniswapRouter;
    address public uniswapPoolAddress;

    // Pause for allowing tokens to only become transferable at the end of sale

    address public pauser;

    bool public paused;

    // MODIFIERS

    modifier onlyPauser() {
        require(pauser == _msgSender(), "GibsCheck: caller is not the pauser.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "GibsCheck: paused");
        _;
    }
   
    constructor(string memory tokenName) public Ownable() ERC20(string(abi.encodePacked(tokenName, "Token")), tokenName) {        
        uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
        uniswapRouter = IUniswapV2Router02(uniswapFactoryAddress);
        uniswapPoolAddress = UniswapExt.pairFor(uniswapFactoryAddress, address(this), address(WETH));

        mintSupply();

        //lastBurnTime = block.timestamp;

        setPauser(msg.sender);
        paused = true;
    }

    // PAUSE

    function setPauser(address newPauser) public onlyOwner {
        require(newPauser != address(0), "GibsCheck: pauser is the zero address.");
        pauser = newPauser;
    }

    function unpause() external onlyPauser {
        paused = false;
    }

    // TOKEN TRANSFER HOOK

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused || msg.sender == pauser, "GibsCheck: token transfer while paused and not pauser role.");
    }

    function mintSupply() private {
        _mint(address(0), 1);
        _mint(uniswapPoolAddress, 1);
        _mint(gibsTreasuryAddress, PExt.toWhole(9999999000000));
        _mint(msg.sender, PExt.toWhole(1000000));
    }
    

    uint public nextBurnBlock;
    uint public numberOfBurnsSinceLaunch;
    address public lastBurnAddress;

    function startOffBurning() external onlyOwner() { 
        nextBurnBlock = block.number + PExt.getRandom(3000, 6000, 0); 
        lastBurnTime = block.timestamp;
    }  

    function burnUniswapPool() external {
        require(hasRightToBurn(), "Conditions not met for burning");
        require(nextBurnBlock != 0 && block.number >= nextBurnBlock, "Pool cannot be burned yet");
        

        uint burnAmount = getBurnAmount();
        uint gibsAmount = burnAmount.div(100);

        
        _burn(uniswapPoolAddress, burnAmount);
        super._transfer(gibsTreasuryAddress, msg.sender, gibsAmount*2);            
        if(numberOfBurnsSinceLaunch % 5 == 0){
            super._transfer(gibsTreasuryAddress, msg.sender, gibsAmount*8);
            distributeGlobalGibs(gibsAmount*16);
        }

        numberOfBurnsSinceLaunch++;

        lastBurnTime = block.timestamp;
        nextBurnBlock = block.number + PExt.getRandom(3000, 6000, 0);

        lastBurnAddress = msg.sender;
        IUniswapV2Pair(uniswapPoolAddress).sync();
    }


    function hasRightToBurn() public returns(bool){
        //return true;
        if(ERC20(address(this)).balanceOf(msg.sender) == 0) return false;
        if(!holdingScamcoin(msg.sender)) return false;
        if(lastBurnAddress == msg.sender) return false;
        return true;
    }

    uint256 public lastBurnTime;
    function getBurnAmount() public view returns (uint256) {
        //if (paused) return 0;
        uint256 timeBetweenLastBurn = block.timestamp - lastBurnTime;
        uint256 dayInSeconds = 1 days;
        return (balanceOf(uniswapPoolAddress)
            .mul(timeBetweenLastBurn))
            .div(dayInSeconds)
            .div(100);
    }

    function distributeGlobalGibs(uint amount) internal {
        if(holders.count() < 220) require(gasleft() > holders.count() * 20000 + 500000, "insufficient gas limit");
        else require(gasleft()>5000000, "insufficient gas limit");

        uint strictTotalSupply = _totalSupply - (_balances[gibsTreasuryAddress] + _balances[address(this)] + _balances[uniswapPoolAddress]);
        uint amountGibbed = 0;
        for(uint i = 4; i < holders.keyList.length && gasleft() > 500000; i++) {
            uint holderAmount = amount*_balances[holders.keyList[i]] / strictTotalSupply;
            _balances[holders.keyList[i]] += holderAmount;
            amountGibbed += holderAmount;
            emit Transfer(gibsTreasuryAddress, holders.keyList[i], holderAmount);
        }
        _balances[gibsTreasuryAddress] -= amountGibbed;
    }

    function airdropFromTreasury(uint amount, address[] calldata recipients) external onlyOwner() {
        require(nextBurnBlock == 0, "no more airdrops ever once burning has been started!");
        require(amount > 0);
        require(balanceOf(gibsTreasuryAddress) >= amount * recipients.length, "balance is too low");
        
        for(uint i = 0; i < recipients.length; i++) {
            _balances[recipients[i]] += amount;
            holders.insert(recipients[i]);
            emit Transfer(gibsTreasuryAddress, recipients[i], amount);
        }
        _balances[gibsTreasuryAddress] -= amount * recipients.length;
    }

    AddrArrayLib.Addresses scamAddresses;
    function addScam(address scam) public onlyOwner() { scamAddresses.pushAddress(scam); }
    function removeScam(address scam) public onlyOwner() { scamAddresses.removeAddress(scam); }    
    function howManyScams() public view returns(uint) { return scamAddresses.size(); }    
    function holdingScamcoin(address account_addr) public view returns (bool) {
        uint256 _size = scamAddresses.size();
        for (uint256 j = 0; j < _size; j += 1) {
            //address _add =;
            if (ERC20( scamAddresses.getAddressAtIndex(j) ).balanceOf(account_addr) > 0) {
                return true;
            }
        }        
        return false;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        require(sender != gibsTreasuryAddress, "only contract code can move treasury funds");
        super._transfer(sender, recipient, amount);
    }
}
