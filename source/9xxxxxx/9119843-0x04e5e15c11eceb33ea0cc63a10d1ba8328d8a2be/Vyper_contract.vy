EtherReceived: event({amount: uint256(wei), sender: indexed(address)})

recipient: public(address)
deposits: public(map(address, uint256(wei)))

@public
@payable
def __default__():
    self.deposits[msg.sender] += msg.value
    log.EtherReceived(msg.value, msg.sender)

@public
def __init__():
    self.recipient = msg.sender

@public
@nonreentrant('lock')
def release() -> bool:
    self.deposits[msg.sender] = 0
    send(self.recipient, self.deposits[msg.sender])
    return True
