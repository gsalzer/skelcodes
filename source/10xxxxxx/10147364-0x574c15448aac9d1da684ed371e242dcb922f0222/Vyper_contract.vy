Transfer: event({_from: indexed(address), _to: indexed(address), _value: uint256})
Approval: event({_owner: indexed(address), _spender: indexed(address), _value: uint256})

name: public(string[64])                                 # AppToken - #{app name}
symbol: public(string[32])                                # APP-#{app-symbol}
decimals: public(uint256)                                # 18
totalSupply: public(uint256)                             # total number of contract tokens in existence
balanceOf: public(map(address, uint256))                 # balance of an address
allowance: public(map(address, map(address, uint256)))   # allowance of one address on another

@public
def __init__(_name: string[64], _symbol: string[32], _decimals: uint256, _supply: uint256):
  self.name = _name
  self.symbol = _symbol
  self.decimals = _decimals
  self.balanceOf[msg.sender] = _supply
  self.totalSupply = _supply
  log.Transfer(ZERO_ADDRESS, msg.sender, _supply)

@public
def transfer(_to: address, _value: uint256) -> bool:
  self.balanceOf[msg.sender] -= _value
  self.balanceOf[_to] += _value
  log.Transfer(msg.sender, _to, _value)
  return True

@public
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
  self.balanceOf[_from] -= _value
  self.balanceOf[_to] += _value
  self.allowance[_from][msg.sender] -= _value
  log.Transfer(_from, _to, _value)
  return True

@public
def approve(_spender: address, _value: uint256) -> bool:
  self.allowance[msg.sender][_spender] = _value
  log.Approval(msg.sender, msg.sender, _value)
  return True
