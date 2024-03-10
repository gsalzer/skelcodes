pragma solidity ^0.5.10;

import "./ICompliance.sol";
import "./AgentRole.sol";
import "./IIdentityRegistry.sol";
import "./Ownable.sol";

contract TransferRestrictions is ICompliance, Ownable {

	struct Counter {
		mapping (uint256 => uint256) count;
		mapping (uint256 => uint256) startTime;
		bool exists;
	}

	IIdentityRegistry public identityRegistry;
	mapping (uint16 => bool) public restricted;
	mapping (address => Counter) public counters;
	mapping (uint256 => uint256) public limit;
	mapping (uint256 => uint256) public timespan;
	uint256 index = 0;

	event Restricted(uint16 _country);
	event Unrestricted(uint16 _country);
	event RestrictionAdded(uint256 _limit, uint256 _timespan);
	event RestrictionUpdated(uint256 _limit, uint256 _timespan, uint _index);
	event RestrictionRemoved(uint256 _index);

	constructor (address _identityRegistry) public {
		identityRegistry = IIdentityRegistry(_identityRegistry);
	}

    function restrictCountry(uint16 _country) public onlyOwner {
		restricted[_country] = true;
		emit Restricted(_country);
	}

	function unrestrictCountry(uint16  _country) public onlyOwner {
		restricted[_country] = false;
		emit Unrestricted(_country);
	}

	function restrictCountriesInBulk(uint16[] memory _country) public onlyOwner {
		for(uint i = 0 ; i < _country.length ; i++ ) {
			restricted[_country[i]] = true;
			emit Restricted(_country[i]);
		}
	}

	function unrestrictCountriesInBulk(uint16[] memory _country) public onlyOwner {
		for(uint i = 0 ; i < _country.length ; i++ ) {
			restricted[_country[i]] = false;
			emit Unrestricted(_country[i]);
		}
	}

	function isFromUnresrictedCountry(address _to) public view returns (bool) {
		uint16 country = identityRegistry.investorCountry(_to);
		if(!restricted[country]) {
			return true;
		}
		return false;
	}

	function getStartTime(address _user, uint256 _index) public view returns(uint256) {
		Counter storage counter = counters[_user];
		return counter.startTime[_index];
	}

	function setStartTime(address _user, uint256 _index, uint256 _time) internal {
		Counter storage counter = counters[_user];
		counter.startTime[_index] = _time;
	}

	function getCount(address _user, uint256 _index) public view returns(uint256) {
        Counter storage counter = counters[_user];
        if(counter.exists) {
            return counter.count[_index];
        }
        return 0;
    }

    function setCount(address _user, uint256 _count) internal {
        Counter storage counter = counters[_user];
		for(uint256 _index = 0; _index < index; _index++) {
			counter.count[_index] += _count;
		}
    }

	function addRestrictions(uint256 _limit, uint256 _timespan) public onlyOwner {
		require(_timespan > 0, "Invalid time interval");
		limit[index] = _limit;
		timespan[index] = _timespan;
		index++;
		emit RestrictionAdded(_limit, _timespan);
	}

	function updateRestrictions(uint256 _limit, uint256 _timespan, uint256 _index) public onlyOwner {
		require(_timespan > 0, "Invalid time interval");
		limit[_index] = _limit;
		timespan[_index] = _timespan;
		emit RestrictionUpdated(_limit, _timespan, _index);
	}

	function removeRestrictions(uint256 _index) public onlyOwner {
		require(_index >= 0, "Invalid index");
		require(limit[_index] != 0 && timespan[_index] != 0, "No restriction exist");

		delete limit[_index];
		delete timespan[_index];
		limit[_index] = limit[index-1];
		timespan[_index] = timespan[index-1];
		delete limit[index-1];
		delete timespan[index-1];
		index--;
		emit RestrictionRemoved(_index);
	}

	function resetStartTime(address _user, uint _index) internal {
		uint256 period = (block.timestamp - getStartTime(_user,_index)) / timespan[_index];
		uint256 time = getStartTime(_user, _index) + period * timespan[_index];
		setStartTime(_user, _index, time);
	}

	function canTransfer(address _from, address _to, uint256 _value) public returns (bool) {
		Counter storage counter = counters[_from];
		require(isFromUnresrictedCountry(_to),"Country is Restricted");
		uint256 flag = index;
		for(uint256 i = 0; i < index; i++) {
			if(!counter.exists) {
			    setStartTime(_from, i, now);
				if(i == index - 1){
				    counter.exists = true;
				}
			}
			if(getStartTime(_from, i) + timespan[i] < now) {
				require(_value <= limit[i], "Transfer limit exceeded");
				resetStartTime(_from, i);
				counter.count[i] = 0;
				flag--;
			}
			else if(getStartTime(_from, i) + timespan[i] >= now && counter.count[i] + _value <= limit[i]) {
				flag--;
			}
		}
		if( flag == 0) {
			setCount(_from, _value);
			return true;
		}
		return false;
	}
}
