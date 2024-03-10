pragma solidity ^0.5.8;

import "./IERC20.sol";
import "./TransferHelper.sol";
import "./ReentrancyGuard.sol";
import "./IPledgeMining.sol";
import "./SafeMath.sol";

//质押挖矿合约逻辑
//ADAO质押币
//WDAO收益币
//一．质押erc20代币ADAO：质押时间为30/60/90/120/150/180天，到期才能赎回，未到时间不予赎回，且按质押数量定挖。
//质押币本位精算到天结算：30天为总挖矿5/千，60天为总挖矿12/千，90天总挖矿21/千，120天总挖矿32/千，150天为总挖矿45/千，180天为总挖矿60/千。
//二．质押币ADAO为整数，数量1个起步
//例如：A质押ADAO54个，质押时间为60天，A最终收益为：54ADAO*12/1000=0.648WDAO，平均每天收益为0.648/60=0.0108WDAO。


//PLEDGE:AMOUNT_ERROR 输入金额不足1个ADAO
//PLEDGE:TYPE_ERROR   输入类型合约不支持
//PLEDGE:SAFE_TRANSFER_FROM_ERROR 转账到智能合约失败
//PLEDGE:RECORD_OVER  质押记录已结束
//PLEDGE:SAFE_TRANSFER_ERROR  智能合约转出失败
//PLEDGE:NO_EXTRA_INCOME  没有多余的收益
//PLEDGE:NOT_EXPIRED  未到期
//PLEDGE:STOP_MINING  停止挖矿
//PLEDGE:UNABLE_TO_CLOSE_RENEWAL  无法关闭续约
//PLEDGE:UNABLE_TO_OPEN_RENEWAL  无法开启续约

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract PledgeMining is IPledgeMining, ReentrancyGuard, Owned {

    IERC20  _tokenA;
    IERC20  _tokenB;
    using TransferHelper for address;
    using SafeMath for uint;
    uint256 periodUnit = 1 days;
    bool public mining_state;

    struct Record {
        uint256 id;
        uint256 createTime;
        uint256 stopTime;
        uint256 heaven;
        uint256 scale;
        uint256 pledgeAmount;
        uint256 releaseAmount;
        uint256 over; // 1 processing 2 over
    }

    mapping(address => Record []) miningRecords;
    mapping(uint256 => uint256) public typeConfig;


    constructor(address tokenA, address tokenB) public {
        _tokenA = IERC20(tokenA);
        _tokenB = IERC20(tokenB);

        // pledge type config init
        typeConfig[uint256(30)] = uint256(5);
        typeConfig[uint256(60)] = uint256(12);
        typeConfig[uint256(90)] = uint256(21);
        typeConfig[uint256(120)] = uint256(32);
        typeConfig[uint256(150)] = uint256(45);
        typeConfig[uint256(180)] = uint256(60);
        mining_state = true;
        owner = msg.sender;
    }


    // Does not accept ETH
    function() external payable {
        revert();
    }

    modifier mining {
        require(mining_state, "PLEDGE:STOP_MINING");
        _;
    }


    // 停止挖矿,并从资金池提取WDAO
    function stop_mining(uint256 tokenAAmount, uint256 tokenBAmount) public nonReentrant onlyOwner {
        if (tokenAAmount > 0) {
            require(address(_tokenA).safeTransfer(msg.sender, tokenAAmount), "PLEDGE:SAFE_TRANSFER_ERROR");
        }
        if (tokenBAmount > 0) {
            require(address(_tokenB).safeTransfer(msg.sender, tokenBAmount), "PLEDGE:SAFE_TRANSFER_ERROR");
        }
        mining_state = false;
    }


    // 质押
    function pledge(uint256 _amount, uint256 _type) public mining nonReentrant returns (uint256){
        require(_amount >= (10 ** uint(18)), "PLEDGE:AMOUNT_ERROR");
        require(typeConfig[_type] != uint256(0), "PLEDGE:TYPE_ERROR");
        require(address(_tokenA).safeTransferFrom(msg.sender, address(this), _amount), "PLEDGE:SAFE_TRANSFER_FROM_ERROR");

        uint256 scale = typeConfig[_type];
        Record [] storage records = miningRecords[msg.sender];
        uint256 _id = records.length;
        records.push(Record(_id, block.timestamp, 0, _type, scale, _amount, 0, 1));
        emit PledgeEvent(msg.sender, _amount, _type);
        return _id;
    }


    //领取收益
    function receiveIncomeInternal(uint256 _index) internal returns (uint256){
        uint256 income = calcReceiveIncome(msg.sender, _index);
        if (income > 0) {
            Record storage r = miningRecords[msg.sender][_index];
            r.releaseAmount = r.releaseAmount.add(income);
            require(address(_tokenB).safeTransfer(msg.sender, income), "PLEDGE:SAFE_TRANSFER_ERROR");
            emit ReceiveIncomeEvent(msg.sender, income, _index);
        }
        return (income);
    }

    // 关闭续约
    function closeRenewal(uint256 _index) public nonReentrant {
        Record storage r = miningRecords[msg.sender][_index];
        require(r.over == uint256(1) && r.stopTime == uint256(0), "PLEDGE:UNABLE_TO_CLOSE_RENEWAL");
        // 周期 =（ （（当前时间-开始时间）/ 周期时间） + 1） * 周期时间
        r.stopTime = block.timestamp.sub(r.createTime)
        .div(r.heaven.mul(periodUnit)).add(1)
        .mul(r.heaven.mul(periodUnit)).add(r.createTime);
    }

    // 开启续约
    function openRenewal(uint256 _index) public nonReentrant {
        Record storage r = miningRecords[msg.sender][_index];
        require(r.over == uint256(1) && r.stopTime > 0 && block.timestamp < r.stopTime, "PLEDGE:UNABLE_TO_OPEN_RENEWAL");
        r.stopTime = uint256(0);
    }


    // 领取收益
    function receiveIncome(uint256 _index) public nonReentrant returns (uint256){
        uint256 income = receiveIncomeInternal(_index);
        require(income > 0, "PLEDGE:NO_EXTRA_INCOME");
        return (income);
    }

    // 移除质押
    function removePledge(uint256 _index) public nonReentrant returns (uint256){
        Record storage r = miningRecords[msg.sender][_index];
        require(r.over == uint256(1) && r.stopTime > 0 && block.timestamp >= r.stopTime, "PLEDGE:NOT_EXPIRED");
        uint256 income = receiveIncomeInternal(_index);
        require(address(_tokenA).safeTransfer(msg.sender, r.pledgeAmount), "PLEDGE:SAFE_TRANSFER_ERROR");
        r.over = uint256(2);
        emit RemovePledgeEvent(msg.sender, r.pledgeAmount, _index);
        return (income);
    }


    // 计算收益
    function calcReceiveIncome(address addr, uint256 _index) public view returns (uint256){
        Record storage r = miningRecords[addr][_index];
        require(r.over == uint256(1), "PLEDGE:RECORD_OVER");

        uint256 oneTotal = r.pledgeAmount.mul(r.scale).div(uint256(1000));
        // current income = total * (block time - create time) / (heaven * 1 day)
        uint256 _income = oneTotal.mul(block.timestamp.sub(r.createTime)).div(r.heaven.mul(periodUnit));
        //Cannot exceed total revenue
        if (r.stopTime > 0) {
            // total income  =  54ADAO * 12 / 1000 * 周期时间
            // total = amount * scale / 1000 * 周期时间
            uint256 _total = oneTotal
            .mul(r.stopTime.sub(r.createTime).div(r.heaven.mul(periodUnit)));
            if (_income > _total) {
                _income = _total;
            }
        }
        _income = _income.sub(r.releaseAmount);


        // 如果收益大于了平台余额，那么就不给币了
        uint256 _balance = _tokenB.balanceOf(address(this));
        if (_income > 0 && _income > _balance) {
            _income = _balance;
        }

        return (_income);
    }



    // 获取token 地址
    function getTokens() public view returns (address, address){
        return (address(_tokenA), address(_tokenB));
    }


    // 通过分页的方式获取用户质押记录
    function getUserRecords(address addr, uint256 offset, uint256 size) public view returns (
        uint256 [4] memory page,
        uint256 [] memory data
    ){
        require(offset >= 0);
        require(size > 0);
        Record [] storage records = miningRecords[addr];
        uint256 lrSize = records.length;
        uint256 len = 0;
        uint256 prop_count = 8;
        if (size > lrSize) {
            size = lrSize;
        }
        data = new uint256[](size * prop_count);
        if (lrSize == 0 || offset > (lrSize - 1)) {
            return ([len, block.timestamp, lrSize, prop_count], data);
        }
        uint256 i = lrSize - 1 - offset;
        uint256 iMax = 0;
        if (offset <= (lrSize - size)) {
            iMax = lrSize - size - offset;
        }
        while (i >= 0 && i >= iMax) {
            Record memory r = records[i];
            data[len * prop_count + 0] = r.id;
            data[len * prop_count + 1] = r.createTime;
            data[len * prop_count + 2] = r.stopTime;
            data[len * prop_count + 3] = r.heaven;
            data[len * prop_count + 4] = r.scale;
            data[len * prop_count + 5] = r.pledgeAmount;
            data[len * prop_count + 6] = r.releaseAmount;
            data[len * prop_count + 7] = r.over;
            len = len + 1;
            if (i == 0) {
                break;
            }
            i--;
        }
        return ([len, block.timestamp, lrSize, prop_count], data);
    }


}
