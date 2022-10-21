pragma solidity ^0.5.2;

contract IERC20Token {
    function balanceOf(address _owner) public view returns (uint);
    function allowance(address _owner, address _spender) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function totalSupply() public view returns (uint);
}

contract IDSWrappedToken is IERC20Token {
    function mint(address _account, uint _value) public;
    function burn(address _account, uint _value) public;
    function wrap(address _dst, uint _amount) public returns (uint);
    function unwrap(address _dst, uint _amount) public returns (uint);
    function changeByMultiple(uint _amount) public view returns (uint);
    function reverseByMultiple(uint _xAmount) public view returns (uint);
    function getSrcERC20() public view returns (address);
}

contract IDFStore {

    function getSectionMinted(uint _position) public view returns (uint);
    function addSectionMinted(uint _amount) public;
    function addSectionMinted(uint _position, uint _amount) public;
    function setSectionMinted(uint _amount) public;
    function setSectionMinted(uint _position, uint _amount) public;

    function getSectionBurned(uint _position) public view returns (uint);
    function addSectionBurned(uint _amount) public;
    function addSectionBurned(uint _position, uint _amount) public;
    function setSectionBurned(uint _amount) public;
    function setSectionBurned(uint _position, uint _amount) public;

    function getSectionToken(uint _position) public view returns (address[] memory);
    function getSectionWeight(uint _position) public view returns (uint[] memory);
    function getSectionData(uint _position) public view returns (uint, uint, uint, address[] memory, uint[] memory);
    function getBackupSectionData(uint _position) public view returns (uint, address[] memory, uint[] memory);
    function getBackupSectionIndex(uint _position) public view returns (uint);
    function setBackupSectionIndex(uint _position, uint _backupIdx) public;

    function setSection(address[] memory _wrappedTokens, uint[] memory _weight) public;
    function setBackupSection(uint _position, address[] memory _tokens, uint[] memory _weight) public;
    function burnSectionMoveon() public;

    function getMintingToken(address _token) public view returns (bool);
    function setMintingToken(address _token, bool _flag) public;
    function getMintedToken(address _token) public view returns (bool);
    function setMintedToken(address _token, bool _flag) public;
    function getBackupToken(address _token) public view returns (address);
    function setBackupToken(address _token, address _backupToken) public;
    function getMintedTokenList() public view returns (address[] memory);

    function getMintPosition() public view returns (uint);
    function getBurnPosition() public view returns (uint);

    function getTotalMinted() public view returns (uint);
    function addTotalMinted(uint _amount) public;
    function setTotalMinted(uint _amount) public;
    function getTotalBurned() public view returns (uint);
    function addTotalBurned(uint _amount) public;
    function setTotalBurned(uint _amount) public;
    function getMinBurnAmount() public view returns (uint);
    function setMinBurnAmount(uint _amount) public;

    function getTokenBalance(address _tokenID) public view returns (uint);
    function setTokenBalance(address _tokenID, uint _amount) public;
    function getResUSDXBalance(address _tokenID) public view returns (uint);
    function setResUSDXBalance(address _tokenID, uint _amount) public;
    function getDepositorBalance(address _depositor, address _tokenID) public view returns (uint);
    function setDepositorBalance(address _depositor, address _tokenID, uint _amount) public;

    function getFeeRate(uint ct) public view returns (uint);
    function setFeeRate(uint ct, uint rate) public;
    function getTypeToken(uint tt) public view returns (address);
    function setTypeToken(uint tt, address _tokenID) public;
    function getTokenMedian(address _tokenID) public view returns (address);
    function setTokenMedian(address _tokenID, address _median) public;

    function setTotalCol(uint _amount) public;
    function getTotalCol() public view returns (uint);

    function setWrappedToken(address _srcToken, address _wrappedToken) public;
    function getWrappedToken(address _srcToken) public view returns (address);
}

contract IMedianizer {
    function read() public view returns (bytes32);
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-overflow");
        z = x / y;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    /**
     * @dev x to the power of y power(base, exponent)
     */
    function pow(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        }
        else if (exponent == 1) {
            return base;
        }
        else if (base == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++)
                z = mul(z, base);
            return z;
        }
    }
}

contract DFProtocolView is DSMath {
    IDFStore public dfStore;
    address public dfCol;

    constructor (address _dfStore, address _dfCol)
        public
    {
        dfStore = IDFStore(_dfStore);
        dfCol = _dfCol;
    }

    function getUSDXForDeposit(address _srcToken, uint _srcAmount) public view returns (uint) {
        address _depositor = msg.sender;
        address _tokenID = dfStore.getWrappedToken(_srcToken);
        require(dfStore.getMintingToken(_tokenID), "CalcDepositorMintTotal: asset not allow.");

        uint _amount = IDSWrappedToken(_tokenID).changeByMultiple(_srcAmount);
        uint _depositorMintTotal;
        uint _step = uint(-1);
        address[] memory _tokens;
        uint[] memory _mintCW;
        (, , , _tokens, _mintCW) = dfStore.getSectionData(dfStore.getMintPosition());

        uint[] memory _tokenBalance = new uint[](_tokens.length);
        uint[] memory _depositorBalance = new uint[](_tokens.length);
        uint[] memory _resUSDXBalance = new uint[](_tokens.length);

        for (uint i = 0; i < _tokens.length; i++) {
            _tokenBalance[i] = dfStore.getTokenBalance(_tokens[i]);
            _resUSDXBalance[i] = dfStore.getResUSDXBalance(_tokens[i]);
            _depositorBalance[i] = dfStore.getDepositorBalance(_depositor, _tokens[i]);
            if (_tokenID == _tokens[i]){
                _tokenBalance[i] = add(_tokenBalance[i], _amount);
                _depositorBalance[i] = add(_depositorBalance[i], _amount);
            }
            _step = min(div(_tokenBalance[i], _mintCW[i]), _step);
        }

        for (uint i = 0; i < _tokens.length; i++) {
            _depositorMintTotal = add(_depositorMintTotal,
                                    min(_depositorBalance[i], add(_resUSDXBalance[i], mul(_step, _mintCW[i])))
                                    );
        }

        return _depositorMintTotal;
    }

    function getUserMaxToClaim() public view returns (uint) {
        address _depositor = msg.sender;
        uint _resUSDXBalance;
        uint _depositorBalance;
        uint _depositorClaimAmount;
        uint _claimAmount;
        address[] memory _tokens = dfStore.getMintedTokenList();

        for (uint i = 0; i < _tokens.length; i++) {
            _resUSDXBalance = dfStore.getResUSDXBalance(_tokens[i]);
            _depositorBalance = dfStore.getDepositorBalance(_depositor, _tokens[i]);

            _depositorClaimAmount = min(_resUSDXBalance, _depositorBalance);
            _claimAmount = add(_claimAmount, _depositorClaimAmount);
        }

        return _claimAmount;
    }

    function getColMaxClaim() public view returns (address[] memory, uint[] memory) {
        address[] memory _tokens = dfStore.getMintedTokenList();
        uint[] memory _balance = new uint[](_tokens.length);
        address[] memory _srcTokens = new address[](_tokens.length);

        for (uint i = 0; i < _tokens.length; i++) {
            _balance[i] = dfStore.getResUSDXBalance(_tokens[i]);
            _srcTokens[i] = IDSWrappedToken(_tokens[i]).getSrcERC20();
        }

        return (_srcTokens, _balance);
    }

    function getMintingSection() public view returns(address[] memory, uint[] memory) {
        uint position = dfStore.getMintPosition();
        uint[] memory _weight = dfStore.getSectionWeight(position);
        address[] memory _tokens = dfStore.getSectionToken(position);
        address[] memory _srcTokens = new address[](_tokens.length);

        for (uint i = 0; i < _tokens.length; i++) {
            _srcTokens[i] = IDSWrappedToken(_tokens[i]).getSrcERC20();
        }

        return (_srcTokens, _weight);
    }

    function getBurningSection() public view returns(address[] memory, uint[] memory) {
        uint position = dfStore.getBurnPosition();
        uint[] memory _weight = dfStore.getSectionWeight(position);
        address[] memory _tokens = dfStore.getSectionToken(position);

        address[] memory _srcTokens = new address[](_tokens.length);

        for (uint i = 0; i < _tokens.length; i++) {
            _srcTokens[i] = IDSWrappedToken(_tokens[i]).getSrcERC20();
        }

        return (_srcTokens, _weight);
    }

    function getUserWithdrawBalance() public view returns(address[] memory, uint[] memory) {
        address _depositor = msg.sender;
        address[] memory _tokens = dfStore.getMintedTokenList();
        uint[] memory _withdrawBalances = new uint[](_tokens.length);

        address[] memory _srcTokens = new address[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            _srcTokens[i] = IDSWrappedToken(_tokens[i]).getSrcERC20();
            _withdrawBalances[i] = IDSWrappedToken(_tokens[i]).reverseByMultiple(calcWithdrawAmount(_depositor, _tokens[i]));
        }

        return (_srcTokens, _withdrawBalances);
    }

    function getPrice(uint _tokenIdx) public view returns (uint) {
        address _token = dfStore.getTypeToken(_tokenIdx);
        require(_token != address(0), "_UnifiedCommission: fee token not correct.");
        bytes32 price = IMedianizer(dfStore.getTokenMedian(_token)).read();
        return uint(price);
    }

    function getFeeRate(uint _processIdx) public view returns (uint) {
        return dfStore.getFeeRate(_processIdx);
    }

    function getDestroyThreshold() public view returns (uint) {
        return dfStore.getMinBurnAmount();
    }

    function calcWithdrawAmount(address _depositor, address _tokenID) internal view returns (uint) {
        uint _depositorBalance = dfStore.getDepositorBalance(_depositor, _tokenID);
        uint _tokenBalance = dfStore.getTokenBalance(_tokenID);
        uint _withdrawAmount = min(_tokenBalance, _depositorBalance);

        return _withdrawAmount;
    }

    function getColStatus() public view returns (address[] memory, uint[] memory) {
		address[] memory _tokens = dfStore.getMintedTokenList();
		uint[] memory _srcBalance = new uint[](_tokens.length);
		address[] memory _srcTokens = new address[](_tokens.length);
		uint _xAmount;

		for (uint i = 0; i < _tokens.length; i++) {
			_xAmount = IDSWrappedToken(_tokens[i]).balanceOf(dfCol);
			_srcBalance[i] = IDSWrappedToken(_tokens[i]).reverseByMultiple(_xAmount);
			_srcTokens[i] = IDSWrappedToken(_tokens[i]).getSrcERC20();
		}

		return (_srcTokens, _srcBalance);
    }

    function getPoolStatus() public view returns (address[] memory, uint[] memory) {
		address[] memory _tokens = dfStore.getMintedTokenList();
		uint[] memory _srcBalance = new uint[](_tokens.length);
		address[] memory _srcTokens = new address[](_tokens.length);
        uint _xAmount;

		for (uint i = 0; i < _tokens.length; i++) {
            _xAmount = dfStore.getTokenBalance(_tokens[i]);
			_srcBalance[i] = IDSWrappedToken(_tokens[i]).reverseByMultiple(_xAmount);
			_srcTokens[i] = IDSWrappedToken(_tokens[i]).getSrcERC20();
		}

		return (_srcTokens, _srcBalance);
    }

    function calcMaxMinting() public view returns(uint) {
        address[] memory _tokens;
        uint[] memory _mintCW;
        (, , , _tokens, _mintCW) = dfStore.getSectionData(dfStore.getMintPosition());

        uint _sumMintCW;
        uint _step = uint(-1);
        address _depositor = msg.sender;
        address _srcToken;
        uint _balance;
        for (uint i = 0; i < _tokens.length; i++) {
            _sumMintCW = add(_sumMintCW, _mintCW[i]);
            _srcToken = IDSWrappedToken(_tokens[i]).getSrcERC20();
            _balance = IDSWrappedToken(_srcToken).balanceOf(_depositor);
            _step = min(div(IDSWrappedToken(_tokens[i]).changeByMultiple(_balance), _mintCW[i]), _step);
        }

        return mul(_step, _sumMintCW);
    }

    function getCollateralList() public view returns (address[] memory) {
		address[] memory _tokens = dfStore.getMintedTokenList();
		address[] memory _srcTokens = new address[](_tokens.length);

		for (uint i = 0; i < _tokens.length; i++)
			_srcTokens[i] = IDSWrappedToken(_tokens[i]).getSrcERC20();

		return _srcTokens;
    }

    function getCollateralBalance(address _srcToken) public view returns (uint) {
		address _tokenID = dfStore.getWrappedToken(_srcToken);
        return IDSWrappedToken(_tokenID).reverseByMultiple(IDSWrappedToken(_tokenID).balanceOf(dfCol));
    }
}
