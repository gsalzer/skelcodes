contract Ophir:
    def mint(_to : address, _value : uint256): modifying

ChangePrice: event({_value: uint256})
TokenPurchase: event({_to: indexed(address), _value: uint256})
TokenUpdate: event({_to: indexed(address)})
UpdateEthUsd: event({_value: uint256})
SaleLock: event({_locked: bool})
    
usdPrice : uint256
ophirAddress: address
ethUsd : uint256

locked : bool
operator : address
        
@public
def __init__(_tokenAddress : address, _salePrice: uint256, _saleDecimal : uint256):
    """
    @dev connect crowdsale contract to eth/usd price and token
    @param _sourceAddress ETH/USD feed source 
    @param _tokenAddress token contract address 
    @param _salePrice initial sales price in USD
    """
    
    assert _saleDecimal <= 18
    
    self.usdPrice = _salePrice * 10 ** (18 - _saleDecimal)
    self.ophirAddress = _tokenAddress
    self.locked = False
    self.operator = msg.sender

@public
@constant
def getRate() -> uint256:
    """
    @dev returns USD sale price, 18 decimals
    """
    return self.usdPrice
    
@private
def _priceDivide(_x : uint256, _y : uint256) -> uint256:

    numerator : uint256 = _x * 10 ** 3
    result : uint256 = ((numerator / _y) + 5) / 10
    
    return result
    
@private
def _priceMultiply(_x : uint256, _y : uint256) -> uint256:
    
    factorX : uint256 = _x
    factorY : uint256 = _y 
    
    result : uint256 = factorX * factorY
    return result

@public
@constant
def lockedContract() -> bool:
    """
    @dev displays if smart contract is locked or otherwise
    """
    return self.locked

@public
def setRate(_price : uint256, _decimals : uint256):
    """
    @dev sets new USD sale price, logs event
    @param _price price in USD, from values $1-$999999
    @param _decimals decimals in the _price param
    """
    
    assert msg.sender == self.operator
    assert _price > 0
    assert _decimals <= 18
    
    self.usdPrice = _price * 10 ** (18 - _decimals)
    log.ChangePrice(self.usdPrice)
    
@public
def setEthUsd(_value: uint256, _decimals : uint256):
    
    assert msg.sender == self.operator
    assert _value > 0 
    assert _decimals <= 18
    
    self.ethUsd = _value * 10 ** (18 - _decimals)
    log.UpdateEthUsd(self.ethUsd)
    
@public
def lockContract() -> bool:
    """
    @dev locks or unlocks the smart contract from new purchases
    """
    assert msg.sender == self.operator
    
    if(self.locked):
        self.locked = False
        log.SaleLock(False)
        return False
    if(self.locked == False):
        self.locked = True
        log.SaleLock(True)
        return True
    return True

@public
def modifyToken(_tokenAddress : address):
    """
    @dev changes token contract address in an event of contract modification
    @param _tokenAddress token contract address 
    """
    
    assert msg.sender == self.operator
    
    self.ophirAddress = _tokenAddress
    log.TokenUpdate(_tokenAddress)

@public
@constant
def getEthUsd() -> uint256:
    return self.ethUsd 

@public
@payable
def tokenPurchase() -> uint256:
    """
    @dev executes the purchase and generation of new ophir tokens 
    1. Reads ETHUSD Oracle
    2. Parse into uint256 
    3. Calculate rate for OPR/ETH 
    4. Calculate token amount rate * amount
    5. Send/Mint Tokens to Buyer
    6. Log Token Purchase
    """
    assert msg.value > 0
    assert self.locked == False
    
    opreth : uint256 = self._priceDivide(self.ethUsd, self.usdPrice)
    received : uint256 = as_unitless_number(msg.value)
    amtTok : uint256 = self._priceMultiply(opreth, received) / (10 ** 18)
    
    assert amtTok >= 1
    
    send(self.operator, msg.value)
    Ophir(self.ophirAddress).mint(msg.sender, amtTok)
    
    return amtTok
    
@public 
def destroy():
    assert msg.sender == self.operator
    selfdestruct(self.operator)
