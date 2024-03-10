interface txtest:
    def balanceOf(_to: address) -> uint256: view

var: public(uint256)

@external
def __init__():
    self.var = 0

@external
def show(_ct: address, _addy: address) -> uint256:
    self.var = txtest(_ct).balanceOf(_addy)
    return self.var

@external
def clearvar() -> bool:
    self.var = 0
    return True

@external
def x():
    selfdestruct(msg.sender)
