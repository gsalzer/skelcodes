pragma solidity >=0.5.16 <0.7.0;

import "./ERC20.sol";
import "./Latency.sol";

contract ConfinaleToken is ERC20 {
    string  public name = "Confinale Token";
    string  public symbol = "CNFI";

    //the Latency Contract is managing the value that one is allowed to withdraw
    mapping(address => Latency) _latencyOf;
    address public owner;

    event TransferWei(
        address indexed _from,
        uint256 _value
    );

    modifier onlyOwner()
    {
        require(msg.sender == owner, "only owner allowed");
        _;
    }

    constructor(uint256  _initialSupply) public
    {
        owner = msg.sender;
        _mint(msg.sender, _initialSupply);
    }

    function etherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function modifyTotalSupply(int256 _value) public onlyOwner returns (uint256 New_totalSupply)
    {
        uint256 absValue;
        if (_value<0)
        {
            absValue = uint256(-_value);
            _burn(msg.sender, absValue);
        }
        else
        {
            absValue = uint256(_value);
            _mint(msg.sender, absValue);
        }
        return totalSupply();
    }

    function initialTransfer(address _to, uint256 _value, uint256 _waitingTime) public onlyOwner returns (bool success) {
        require(_to != msg.sender,'you cant transfer token to yourself');
        require(_value>0,'you have to transfer more than zero');
        require(balanceOf(msg.sender) >= _value, 'You have not sufficent Token in our balance');

         if (balanceOf(_to)==0)
        // if( _latencyOf[_to] == Latency(0))
        {
            // we need to initialize the _latencyOf Contract
            _latencyOf[_to] = new Latency();
        }

        _latencyOf[_to].addValueCustomTime(_value, _waitingTime);
        super.transfer(_to, _value);
        return true;
    }

    //the parameter _waitingTime is only needed for the owner
    // for all others the waiting time is computed as an averaged weight of all future times
     function transfer(address _to, uint256 _value) public returns (bool success)
     {
        require(_to != msg.sender,'you cant transfer token to yourself');
        require(_value>0,'you have to transfer more than zero');
        require(super.balanceOf(msg.sender) >= _value, 'You have not sufficent Token in our balance');

        require(super.balanceOf(_to)!=0,"Use initalTransfer to send Token to new addresses");
        require(msg.sender != owner, "The owner must use the initialTransfer function to send Token");

        uint256 steps = _latencyOf[msg.sender].withdrawSteps(_value);
        uint256 amount = 0;

        if (_to != owner)
        {
                uint256 waitingTime = 0;
                if (steps > 0 ) // first in - first out logic
                {
                    // equivalent to:
                    // amount= _latencyOf[msg.sender].withdrawValue(0);
                    // waitingTime=_latencyOf[msg.sender].withdrawTime(0);
                    (waitingTime,amount) = _latencyOf[msg.sender].withdrawTupel(0);
                    _latencyOf[_to].addValueCustomTime(amount,waitingTime);

                    for (uint i = 1; i<steps; i++)
                    {
                        amount = (_latencyOf[msg.sender].withdrawValue(i)-_latencyOf[msg.sender].withdrawValue(i-1));
                        waitingTime = _latencyOf[msg.sender].withdrawTime(i);
                        _latencyOf[_to].addValueCustomTime(amount,waitingTime);
                    }

                    amount = _value - _latencyOf[msg.sender].withdrawValue(steps-1);
                    waitingTime = _latencyOf[msg.sender].withdrawTime(steps);
                    _latencyOf[_to].addValueCustomTime(amount,waitingTime);
                }
                else //the amount is smaller than the first block
                {
                    amount = _value;
                    waitingTime = _latencyOf[msg.sender].withdrawTime(0);
                    _latencyOf[_to].addValueCustomTime(amount,waitingTime);
                }
        }

        _latencyOf[msg.sender].reduceValue(_value);
        super.transfer(_to, _value);

        return true;
    }


    function withdraw(uint256 _AmountConf) public
    {
        require(_AmountConf <= balanceOf(msg.sender),' not sufficient Confinale token to withdraw');
        if (msg.sender != owner)
        {
            require(_latencyOf[msg.sender].withdrawableAmount() >= _AmountConf,' value cant be withdrawn yet - wait longer');
        }

        uint256 value = SafeMath.div(address(this).balance*_AmountConf, totalSupply());
        msg.sender.transfer(value);
        _burn(msg.sender, _AmountConf);

        if (msg.sender != owner)
        {
            _latencyOf[msg.sender].withdraw(_AmountConf);
        }
    }

    //everyone can deposit ether into the contract
    function deposit() public payable
    {
        // nothing else to do!
       // require(msg.value>0); // value is always unsigned -> if someone sends negative values it will increase the balance
        emit TransferWei(msg.sender, msg.value);
    }

    function valueConfinaleToken(uint256 _amountConf) public view returns (uint256 val)
    {
        return SafeMath.div(address(this).balance * _amountConf, totalSupply());
    }

    // optional functions useful for debugging
    function withdrawableAmount(address _addr) public view returns(uint256 value)
    {
        if (balanceOf(_addr)==0) {
            return 0;
        }
        if (_addr != owner)
        {
            return  _latencyOf[_addr].withdrawableAmount();
        }
        else
        {
            return balanceOf(_addr); // the owner can always access its token
        }
    }

    function withdrawSteps(address _addr, uint256 _amount) public view returns (uint256 steps)
    {
        if (balanceOf(_addr)==0) {
            return 0;
        }
        return _latencyOf[_addr].withdrawSteps(_amount);
    }

    function withdrawTupel(address _addr, uint256 _index) public view returns (uint256 holdingPeriod, uint256 token)
    {

        if(_addr==owner){
            if(_index==0){
                return(0, balanceOf(_addr));
            } else {
                return (0,0);
            }
        }
        else
        {
        if (balanceOf(_addr)==0) {
            return (0, 0);
        }
        return _latencyOf[_addr].withdrawTupel(_index);
        }

    }

    function changeOwner(address _newOwner) public onlyOwner returns (bool success)
    {
        uint256 ownerBalance= balanceOf(owner);
        super.transfer(_newOwner, ownerBalance);
        owner=  _newOwner;

        return true;

    }

    // emergency function
    function fixValueDifference (address _address) public onlyOwner
    {
        uint256 balance = balanceOf(_address);
        uint256 steps = _latencyOf[_address].withdrawSteps(balance);
        uint256 maxValue = _latencyOf[_address].withdrawValue(steps);
        if (maxValue < balance)
        {
            _latencyOf[_address].addValueCustomTime(balance - maxValue, 0);
        }
    }

}

