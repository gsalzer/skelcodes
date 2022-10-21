interface txtest:
    def balanceOf(_to: address) -> uint256: view

@external
def show(_ct: address, _addy: address) -> uint256:
    b: uint256 = txtest(_ct).balanceOf(_addy)
    return b

@external
def x():
    selfdestruct(msg.sender)
