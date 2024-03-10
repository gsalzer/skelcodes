pragma solidity >=0.5.16 <0.7.0;

contract Latency {
  

    struct LatencyPoint
    {
        uint256 time;
        uint256 value;
    }

    LatencyPoint[] public _latencyArray;
    address owner;
     
    constructor ( ) public
    {
        owner = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "only latency owner allowed");
        _;
    }

    // the value which is incremeted in the struct after the waitingTime
    function addValueCustomTime(uint256 _transferedValue, uint256 _waitingTime)   public onlyOwner
    {
       if(_transferedValue > 0 ) // otherwise there is no need to add a value in the array
        {
            uint256 unlockTime = block.timestamp + _waitingTime;
            bool found = false;
            uint256 index;

            for(uint i = 0; i<_latencyArray.length; i++)
            {
                if (_latencyArray[i].time > unlockTime)
                {
                    index = i;
                    found = true;
                    break;
                }
            }

            if (found)
            {  // we need to shift all the indices
            _latencyArray.push(LatencyPoint(_latencyArray[_latencyArray.length-1].time, _latencyArray[_latencyArray.length-1].value + _transferedValue));

                 for(uint i = _latencyArray.length - 2; i>index; i--)
                 {
                     _latencyArray[i].time = _latencyArray[i-1].time;
                     _latencyArray[i].value = _latencyArray[i-1].value + _transferedValue;
                 }

                 _latencyArray[index].time = unlockTime;

                 if (index>0){
                    _latencyArray[index].value = _latencyArray[index-1].value + _transferedValue;
                 }else
                 {
                    _latencyArray[index].value = _transferedValue;
                 }
            }else
            { // the timestamp is after all the others
                 if (_latencyArray.length>0){
                    _latencyArray.push(LatencyPoint(unlockTime,_latencyArray[_latencyArray.length-1].value + _transferedValue));
                 }
                 else
                 {
                    _latencyArray.push(LatencyPoint(unlockTime, _transferedValue));
                 }
            }
        }
    }

    function withdrawableAmount() public view returns(uint256 value)
    {
        uint i = 0;
        if (_latencyArray.length==0)
        {
            return 0;
        }

        while (i < _latencyArray.length && _latencyArray[i].time < block.timestamp)
        {
          i++;
        }

        if (i==0) // nothing can be taken out
        {
            return 0;
        }
        else
        {
          return _latencyArray[i-1].value;
        }
    }

    function currentTime() public view returns(uint256 time) {
        return block.timestamp;
    }

    function removePoint(uint i) private
    {
        while (i<_latencyArray.length-1)
        {
            _latencyArray[i] = _latencyArray[i+1];
            i++;
        }
        _latencyArray.length--;
    }

    // you need to keep at least the last one such that you know how much you can withdraw
    function removePastPoints() private
    {
        uint i = 0;
        while (i < _latencyArray.length && _latencyArray[i].time < block.timestamp)
        {
            i++;
        }
        if (i==0) // everything is still in the future
        {
            //_latencyArray.length=0;
        }
        else if (i == _latencyArray.length) // then we need to keep the last entry
        {
          _latencyArray[0] = _latencyArray[i-1];
          _latencyArray.length = 1;
        }
        else // i is the first item that is bigger -> so we need to keep all the coming ones
        {
            i--; // you need to keep the last entry of the past if its not zero
            uint j = 0;
            while (j<_latencyArray.length-i)
            {
              _latencyArray[j] = _latencyArray[j+i];
              j++;
            }
            _latencyArray.length = _latencyArray.length-i;
        }
    }

    // you need to keep at least the last one such that you know how much you can withdraw
    function removeZeroValues() private
    {
        uint i = 0;
        while (i < _latencyArray.length && _latencyArray[i].value == 0)
        {
            i++;
        }
        if (i==0) // everything is still in the future
        {
            //_latencyArray.length=0;
        }
        else if (i == _latencyArray.length) // then we need to keep the last entry
        {
          _latencyArray[0] = _latencyArray[i-1];
          _latencyArray.length = 1;
        }
        else // i is the first item that is not zero -> so we need to keep from i on all values  all the coming ones
        {
            //i--; // you need to keep the last entry of the past if its not zero
            uint j=0;
            while (j<_latencyArray.length-i)
            {
                _latencyArray[j] = _latencyArray[j+i];
                j++;
            }
            _latencyArray.length = _latencyArray.length-i;
        }
    }

    function withdraw(uint256 _value) public onlyOwner
    {
        require (withdrawableAmount() >= _value,'you cant withdraw that amount at this moment');
        removePastPoints();
        removeZeroValues();
        for(uint i=0; i<_latencyArray.length; i++)
        {
            _latencyArray[i].value -= _value;
        }
    }

    //if you transfer token from one address to the other you reduce the total amount
    function reduceValue(uint256 _value) public onlyOwner
    {
        removePastPoints();

        for(uint i=0; i<_latencyArray.length; i++)
        {
            if(_latencyArray[i].value<_value)
            {
                _latencyArray[i].value = 0;
            }
            else
            {
                _latencyArray[i].value -= _value;
            }
        }
        removeZeroValues(); //removes zero values form the array
    }

    // returns the first point that is strictly larger than the amount
    function withdrawSteps(uint256 _amount) public view returns (uint256 Steps)
    {
        uint256 steps = 0;
        // we need the first index, that is larger or euqal to the amount
        for(uint i = 0;i<_latencyArray.length;i++)
        {
            steps = i;
            if(_latencyArray[i].value > _amount)
            {
                break;
            }

        }
        return steps;
    }

    function withdrawTupel(uint256 _index) public view returns (uint256 Time, uint256 Val)
    {
        if(_index < _latencyArray.length)
        {
            if (_latencyArray[_index].time>block.timestamp)
            {
                return (_latencyArray[_index].time-block.timestamp, _latencyArray[_index].value) ;
            }
            else // time is already in the past
            {
                return (0,_latencyArray[_index].value) ;
            }
        } else //index out of range
        {
            return (0,0);
        }
    }


    function withdrawTime(uint256 _index) public view returns (uint256 Time)
    {
        if(_index < _latencyArray.length)
        {
            if (_latencyArray[_index].time>block.timestamp)
            {
                return _latencyArray[_index].time-block.timestamp;
            }
            else // time is already in the past
            {
                return 0;
            }
        }
        else //index out of range 
        {
            return 0;
        }
    }

    function withdrawValue(uint256 _index) public view returns (uint256 Value){
        if(_index < _latencyArray.length)
        {
            return _latencyArray[_index].value;
        }
        else
        {
            return 0;
        }
    }

}
