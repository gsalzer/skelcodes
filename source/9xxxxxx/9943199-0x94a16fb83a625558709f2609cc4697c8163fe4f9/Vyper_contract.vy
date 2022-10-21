###############load interface#####################
from vyper.interfaces import ERC20
implements: ERC20
#################staking structure################
struct staking:
    holder : address
    value : uint256
    setDate : timestamp

struct hold:
    seller : address
    buyer : address
    value : uint256
    netValue: uint256
    setDate : timestamp
    subDate : timestamp
    declined : bool

################Event log###########################
Transfer: event({_from: indexed(address), _to: indexed(address), _value: uint256})
Approval: event({_owner: indexed(address), _spender: indexed(address), _value: uint256})
Pay : event({_from : indexed(address),_to : indexed(address), _value : uint256})
Stake: event({_owner:indexed(address),_value:uint256})
#############variables#############################
name:public(string[50])
symbol:public(string[10])
total_supply: uint256
_netValue : uint256

decimals: public(uint256)
burnStatus:bool

balanceOf:public(map(address, uint256))
allowances: map(address, map(address, uint256))
holdOf: public(map(address,uint256))
stakeOf:public(map(address,map(uint256,staking)))
dueTransferOf : public(map(address,map(uint256,hold)))
#############StakingRates#######################
StakingRate1:constant(uint256) = 1/100
StakingRate2:constant(uint256) = 2/100
StakingRate3:constant(uint256) = 3/100
###############Addresses#########################
burnAddress:address
liquidityAddress:address
resolutionAddress: address
creatorAddress : address
contractAddress:address
###################initialization#################
@public
def __init__(namear : string[50], symbolar : string[10], burnAddressar : address, resolutionAddressar : address, liquidityAddressar : address, decimalsar : uint256, initialar : uint256, burnar : uint256, liquidityar : uint256, burnStatusar : bool):
    self.name = namear
    self.symbol = symbolar
    self.creatorAddress = msg.sender
    self.contractAddress = self
    self.burnAddress = burnAddressar
    self.resolutionAddress = resolutionAddressar
    self.liquidityAddress = liquidityAddressar
    self.decimals = decimalsar
    init_supply: uint256 = initialar*10**self.decimals
    burnAmount : uint256 = burnar*10**self.decimals
    liquidityAmount : uint256 = liquidityar*10**self.decimals
    self.balanceOf[msg.sender] += init_supply - burnAmount - liquidityAmount
    self.balanceOf[self.burnAddress] += burnAmount
    self.balanceOf[self.liquidityAddress] += liquidityAmount
    self.total_supply = init_supply
    self.burnStatus = burnStatusar
    log.Transfer(ZERO_ADDRESS, msg.sender, init_supply-burnAmount-liquidityAmount)
    log.Transfer(ZERO_ADDRESS,self.burnAddress,burnAmount)
    log.Transfer(ZERO_ADDRESS,self.liquidityAddress,liquidityAmount)

#################get total supply#################
@public
@constant
def totalSupply()-> uint256:
    return self.total_supply
##################update token value############
@public
def update(tokenValue:uint256,etherValue:uint256,USDValue:uint256)-> bool:
    assert msg.sender == self.resolutionAddress     ,'Not the correct Address'                                            #Values in USDT tokens
    self._netValue = tokenValue
    return True

######################set burn status###########
@public
def setBurnStatus(status : bool) -> bool:
    assert msg.sender == self.creatorAddress,'Not the correct Address'
    self.burnStatus = status
    return True
##################check burn status#############
@public
@constant
def checkBurnStatus() -> bool:
    return self.burnStatus
#####################burnfunction################
@private
def _burn(_value: uint256):
    if self.burnStatus == True:
        assert self.burnAddress != ZERO_ADDRESS
        self.balanceOf[self.burnAddress] -= _value
        log.Transfer(self.burnAddress, ZERO_ADDRESS, _value)
######################burn####################
@private
def burn(_value: uint256):
    self._burn(_value)

####################allowances##################
@public
@constant
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]
#########################staking##################
@public
def stake(_value : uint256, stakeId : uint256) -> bool:
    assert self.balanceOf[msg.sender]>=_value
    self.stakeOf[msg.sender][stakeId]=staking({holder : msg.sender, value : _value, setDate : block.timestamp})
    self.holdOf[msg.sender] +=_value
    return True
#######################remove staking#############
@public
def removeStake(stakeId : uint256) -> bool:
    assert self.stakeOf[msg.sender][stakeId].value>0
    _value : uint256 = self.stakeOf[msg.sender][stakeId].value
    _setDate : timestamp = self.stakeOf[msg.sender][stakeId].setDate
    if (block.timestamp>_setDate+300 and block.timestamp<_setDate+1800):
        _reward : uint256 = _value*StakingRate1
        self.balanceOf[msg.sender] += _reward
        self.balanceOf[self.liquidityAddress] -= _reward
        log.Transfer(self.liquidityAddress,msg.sender,_reward)
        self.stakeOf[msg.sender][stakeId]=staking({holder : msg.sender, value : 0,setDate : 0})
        self.holdOf[msg.sender] -=_value
        return True

    elif(block.timestamp>_setDate+1800 and block.timestamp<_setDate+3600):
        _reward : uint256 = _value*StakingRate2
        self.balanceOf[msg.sender] += _reward
        self.balanceOf[self.liquidityAddress] -= _reward
        log.Transfer(self.liquidityAddress,msg.sender,_reward)
        self.stakeOf[msg.sender][stakeId]=staking({holder : msg.sender, value : 0,setDate : 0})
        self.holdOf[msg.sender] -=_value
        return True

    elif(block.timestamp>_setDate+3600):
        _reward : uint256 = _value*StakingRate3
        self.balanceOf[msg.sender] += _reward
        self.balanceOf[self.liquidityAddress] -= _reward
        log.Transfer(self.liquidityAddress,msg.sender,_reward)
        self.stakeOf[msg.sender][stakeId]=staking({holder : msg.sender, value : 0,setDate : 0 })
        self.holdOf[msg.sender] -=_value
        return True

    else:
        self.stakeOf[msg.sender][stakeId]=staking({holder : msg.sender, value : 0,setDate : 0 })
        self.holdOf[msg.sender] -=_value
        return True
#####################setDueTransfer################
@public
def setDueTransfer(workId : uint256,seller : address,_value : uint256, days : uint256) -> bool:
    assert self.balanceOf[msg.sender]>=_value,'Not enough balance in account'
    assert self.dueTransferOf[msg.sender][workId].value==0,'Already have data in the workId'
    subDate : timestamp = 86400*days + block.timestamp
    self.dueTransferOf[msg.sender][workId]= hold({seller: seller, buyer : msg.sender, value : _value, netValue: self._netValue,setDate : block.timestamp, subDate : subDate, declined : False})
    self.holdOf[msg.sender] += _value
    return True

######################transfer function#########
@public
def transfer(_to : address, _value : uint256) -> bool:
    assert self.holdOf[msg.sender]<=self.balanceOf[msg.sender]-_value,'Not enoough balance in account'
    burnAmount : uint256=_value/100
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log.Transfer(msg.sender, _to, _value)
    self.burn(burnAmount)
    return True
########################transfer from to#############
@public
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:  ###########why this??
    assert self.holdOf[_from]<=self.balanceOf[_from]-_value
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    burnAmount : uint256=_value/100
    self.allowances[_from][msg.sender] -= _value
    log.Transfer(_from, _to, _value)
    self.burn(burnAmount)
    return True

#########################submitTransfer###########
@public
def submitTransfer(workId : uint256) -> bool:
    assert self.dueTransferOf[msg.sender][workId].value>0
    _toAddress : address = self.dueTransferOf[msg.sender][workId].seller
    _value : uint256 = self.dueTransferOf[msg.sender][workId].value
    _pastValue: uint256 = self.dueTransferOf[msg.sender][workId].netValue
    _newValue: uint256 = self._netValue
    if _newValue>_pastValue:
        _liqVal : uint256 = ((_newValue-_pastValue)*_value)/self._netValue
        self.balanceOf[msg.sender] -= _value
        self.balanceOf[self.liquidityAddress] -= _liqVal
        self.balanceOf[_toAddress] += _value*(_newValue/_pastValue)
        log.Pay(msg.sender,_toAddress,_value*(_newValue/_pastValue))
        log.Transfer(self.liquidityAddress,_toAddress,_liqVal)
    elif _newValue<_pastValue:
        _liqVal : uint256 =((_pastValue-_newValue)*_value)/self._netValue
        self.balanceOf[msg.sender] -= _value
        self.balanceOf[self.liquidityAddress] += _liqVal
        self.balanceOf[_toAddress] += _value*(_newValue/_pastValue)
        log.Pay(msg.sender,_toAddress,_value*(_newValue/_pastValue))
        log.Transfer(msg.sender,self.liquidityAddress,_liqVal)
    else:
        self.balanceOf[msg.sender] -= _value
        self.balanceOf[_toAddress] += _value
        log.Pay(msg.sender,_toAddress,_value)
    self.burn(_value)
    self.holdOf[msg.sender] -= _value
    self.dueTransferOf[msg.sender][workId].value = 0
    return True
########################declineTransfer#########
@public
def declineTransfer(workId : uint256) -> bool:
    assert self.dueTransferOf[msg.sender][workId].value>0
    _toAddress : address = self.resolutionAddress
    _value : uint256 = self.dueTransferOf[msg.sender][workId].value
    _seller : address = self.dueTransferOf[msg.sender][workId].seller
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_toAddress] += _value
    self.holdOf[msg.sender] -= _value
    self.dueTransferOf[msg.sender][workId].declined=True
    log.Transfer(msg.sender,_toAddress,_value)
    return True
#######################approval of allowances####################
@public
def approve(_spender : address, _value : uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log.Approval(msg.sender, _spender, _value)
    return True
#######################resolve##################
@public
def resolve(workId : uint256, buyer : address, ret : bool) -> bool:        #ret==True ->send money to buyer
    assert msg.sender == self.resolutionAddress
    _value : uint256 = self.dueTransferOf[buyer][workId].value
    _toAddress : address = self.dueTransferOf[buyer][workId].seller
    _pastValue: uint256 = self.dueTransferOf[buyer][workId].netValue
    _newValue: uint256 = self._netValue

    if ret==True:
        if _newValue>_pastValue:
            _liqVal : uint256 = ((_newValue-_pastValue)*_value)/self._netValue
            self.balanceOf[self.liquidityAddress] -= _liqVal
            self.balanceOf[_toAddress] += _value*(_newValue/_pastValue)
            log.Pay(buyer,_toAddress,_value*(_newValue/_pastValue))
            log.Transfer(self.liquidityAddress,_toAddress,_liqVal)
        elif _newValue<_pastValue:
            _liqVal : uint256 =((_pastValue-_newValue)*_value)/self._netValue
            self.balanceOf[msg.sender] -= _value
            self.balanceOf[self.liquidityAddress] += _liqVal
            self.balanceOf[_toAddress] += _value*(_newValue/_pastValue)
            log.Pay(msg.sender,_toAddress,_value*(_newValue/_pastValue))
            log.Transfer(buyer,self.liquidityAddress,_liqVal)

        else:
            self.balanceOf[msg.sender] -= _value
            self.balanceOf[_toAddress] -= _value
            log.Pay(buyer,_toAddress,_value)
    if ret==False:
        self.balanceOf[self.liquidityAddress]-=_value
        self.balanceOf[buyer]+=_value
    self.burn(_value)
    return True
######################request###########################        #################?
@public
def request(buyer : address,workId : uint256) -> bool:
    assert self.dueTransferOf[buyer][workId].subDate+259200<=block.timestamp
    assert self.dueTransferOf[buyer][workId].declined == False
    assert self.dueTransferOf[buyer][workId].value>0
    _toAddress : address = self.dueTransferOf[buyer][workId].seller
    _value : uint256 = self.dueTransferOf[buyer][workId].value
    _pastValue: uint256 = self.dueTransferOf[buyer][workId].netValue
    _newValue: uint256 = self._netValue
    if _newValue>_pastValue:
        _liqVal : uint256 = ((_newValue-_pastValue)*_value)/self._netValue
        self.balanceOf[buyer] -= _value
        self.balanceOf[self.liquidityAddress] -= _liqVal
        self.balanceOf[_toAddress] += _value*(_newValue/_pastValue)
        log.Pay(buyer,_toAddress,_value*(_newValue/_pastValue))
        log.Transfer(self.liquidityAddress,_toAddress,_liqVal)
    elif _newValue<_pastValue:
        _liqVal : uint256 =((_pastValue-_newValue)*_value)/self._netValue
        self.balanceOf[buyer] -= _value
        self.balanceOf[self.liquidityAddress] += _liqVal
        self.balanceOf[_toAddress] += _value*(_newValue/_pastValue)
        log.Pay(buyer,_toAddress,_value*(_newValue/_pastValue))
        log.Transfer(buyer,self.liquidityAddress,_liqVal)

    else:
        self.balanceOf[buyer] -= _value
        self.balanceOf[_toAddress] += _value
        log.Pay(buyer,_toAddress,_value)

    self.burn(_value)
    self.holdOf[buyer] -= _value
    self.dueTransferOf[buyer][workId].value = 0
    return True
###################################################
