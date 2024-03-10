pragma solidity >=0.4.22 <0.7.0;

//
import "./TokenERC20.sol";
import "./YearsDataSetOptimized.sol";
// import "./Functions.sol";

contract EncropyTokenOptimized is TokenERC20 {

    uint8 public constant decimals = 8;  // 8 is the most common number of decimal places

    uint256 constant initialDate = 1584460800; // 2020-03-18 发行日期 timezone is PRC
    uint256 constant firstYearSupply = 500000000*10**uint256(decimals); // 首年发行量5亿个

    string constant PROFIT_LEDGER = 'PROFIT_LEDGER'; // 盈利总账
    string constant HOLDING_LEDGER = 'HOLDING_LEDGER'; // 持有总账
    string constant PROGRAM_LEDGER = 'PROGRAM_LEDGER'; // 编程总账
    string constant PROPOSAL_LEDGER = 'PROPOSAL_LEDGER'; // 参议总账
    string constant NODE_LEDGER = 'NODE_LEDGER'; // 服务器节点总账
    string constant FUND_LEDGER = 'FUND_LEDGER'; // 基金总账
    string constant DESTROY_LEDGER = 'DESTROY_LEDGER'; // 销毁总账

    string public constant name = 'Encropy';
    string public constant symbol = 'ECP';

    mapping(string => address) ledgers; // 账本
    mapping(string => uint8) allocationRatio; // 分配比例
    mapping(uint256 => uint256) allocatedDates; // 已经分配ECP的日期

    YearsDataSetOptimized yearsData;//  = new YearsDataSetOptimized(initialDate,firstYearSupply); // 分配数据


    event DailyMined(uint256 indexed date, uint256 volume);
    event LedgerChanged(string indexed ledger_name, address new_address);

    modifier checkMined(uint256 _time) {
        require(isAllocated(_time) == false, 'today have been mined!');
        _;
    }
    modifier checkNowMined() {
        uint256 _time = now;
        require(_time <= 3383222400, 'time is exceed the limit');
        require(isAllocated(_time) == false, 'today have been mined!');
        _;
    }

    // event FallbackIsCalled(address caller_address, uint256 _value, bytes data);
    // event ReceiveIsCalled(address caller_address, uint256 _value);

    constructor() public {
        owner = msg.sender;
        yearsData = new YearsDataSetOptimized(initialDate,firstYearSupply); // 分配数据
        setLedgers();
    }

    // receive() external payable {
    //     emit ReceiveIsCalled(msg.sender, msg.value);
    // }

    // fallback() external payable {
    //     emit FallbackIsCalled(msg.sender, msg.value, msg.data);
    // }

    // 设定账本地址和比例
    function setLedgers() private {
        // ledgers['GENERAL_LEDGER'] = 0xc5A2D4ffBb95570602616A7ACAA4904C88A3BE33; // 总账
        ledgers[PROFIT_LEDGER] = 0x775a40c61f2Af5Ae9E7DC6A1f5E022ED9E58455D;
        ledgers[HOLDING_LEDGER] = 0x677d514Fb8D6FCDC2f741575aa8FE506210B5781;
        ledgers[PROGRAM_LEDGER] = 0x948E284E0222b35ca6E5404b0766f933e077b118;
        ledgers[PROPOSAL_LEDGER] = 0x6F7b95C8CEd86D091002A3546f5154256d6c0AA1;
        ledgers[NODE_LEDGER] = 0xC46E4B28703C1dDfA77507B8c6Bc7dC495a3b1de;
        ledgers[FUND_LEDGER] = 0x18731261A0cA711e67877389FBa962021CdfE1BD;
        ledgers[DESTROY_LEDGER] = 0xCEA7B41F90069Cf88F004ee806f88d4840EFc530;

        allocationRatio[PROFIT_LEDGER] = 50;
        allocationRatio[HOLDING_LEDGER] = 20;
        allocationRatio[PROGRAM_LEDGER] = 10;
        allocationRatio[PROPOSAL_LEDGER] = 10;
        allocationRatio[NODE_LEDGER] = 5;
        allocationRatio[FUND_LEDGER] = 5;

        // prevMine();
    }

    // 获取账本地址
    function getLedgerAddress(string memory _name) public view returns (address) {
        return ledgers[_name];
    }

    // 获取账本分成比例
    function getLedgerRadio(string memory _name) public view returns (uint8) {
        return allocationRatio[_name];
    }

    // 获取该年度的数据
    function getYearData(uint16 _year) public view returns(uint16 year, uint256 start_time, uint256 end_time, uint16 daysInYear, uint256 issueVolume) {
        return yearsData.getYearDataFromYear(_year);
    }

    // 从时间戳里面获取日期的时间戳
    function getYearDataFromTimestamp(uint256 _time) public view returns(uint16 year, uint256 start_time, uint256 end_time, uint16 daysInYear, uint256 issueVolume) {
        return yearsData.getYearDataFromTimestamp(_time);
    }

    // 从时间戳里面获取日期的时间戳
    function getDayTimestampFromTimestamp(uint256 _time) public view returns(uint256) {
        return yearsData.getDayTimestamp(_time);
    }

    // 获取从现在到发行日的所有历史的日期时间戳
    function getHistoryDaysTimestamp() public view returns(uint256[] memory){
        uint256 time = now - 3600*24;
        return yearsData.getHistoryDaysTimestamp(time);
    }

    // 该日期是否已经挖过了
    function isAllocated(uint256 _dayTimestamp) public view returns(bool) {
        if (allocatedDates[_dayTimestamp] > 0)
        {
            return true;
        }

        _dayTimestamp = getDayTimestampFromTimestamp(_dayTimestamp);

        if (allocatedDates[_dayTimestamp] > 0)
        {
            return true;
        }

        return false;
    }
    // 指定日期的挖矿挖矿
    function mine(uint256 _dayTimestamp) checkMined(_dayTimestamp) private onlyOwner{
        uint256 __dayTimestamp = getDayTimestampFromTimestamp(_dayTimestamp);

        (, , , uint16 daysInYear, uint256 issueVolume) = getYearDataFromTimestamp(__dayTimestamp);

        uint256 dayVolume = issueVolume / daysInYear; // 每日的出矿量

        totalSupply += dayVolume; // 总量增加

        balanceOf[msg.sender] += dayVolume; // 创建人人余额增加

        emit DailyMined(__dayTimestamp, dayVolume);

        allocatedDates[__dayTimestamp] = dayVolume; // 记录已挖的日期

        allocatingMine(dayVolume); // 按规则分配矿池

    }

    // 挖今天的矿
    function mine() checkNowMined public onlyOwner {
        uint256 _now = now;

        mine(_now);
    }

    // 按规则分配矿池
    function allocatingMine(uint256 _dayVolume) internal onlyOwner{
        uint256 value = 0;

        value = (_dayVolume * 50) / 100;
        transfer(ledgers[PROFIT_LEDGER], value);

        value = (_dayVolume * 20) / 100;
        transfer(ledgers[HOLDING_LEDGER], value);

        value = (_dayVolume * 10) / 100;
        transfer(ledgers[PROGRAM_LEDGER], value);

        value = (_dayVolume * 10) / 100;
        transfer(ledgers[PROPOSAL_LEDGER], value);

        value = (_dayVolume * 5) / 100;
        transfer(ledgers[NODE_LEDGER], value);


        // value = (_dayVolume * allocationRatio[FUND_LEDGER]) / 100;
        value = balanceOf[msg.sender]; // 剩下的全给基金会，防止有余数
        transfer(ledgers[FUND_LEDGER], value);
    }
    // 将之前的先挖出来
    function prevMine() public onlyOwner{
        uint256[] memory historyDaysTimestamp = getHistoryDaysTimestamp();

        uint256 max = 5;
        for (uint256 i=0; i<historyDaysTimestamp.length; i++)
        {
            // if (max < 0)
            // {
            //     break;
            // }

            if (!isAllocated(historyDaysTimestamp[i]))
            {
                mine(historyDaysTimestamp[i]);
                max = max-1;
            }
        }
    }

    // 一天的发行量
    function dateOfSupply(uint256 _date) public view returns (uint256) {
        (,,,uint256 daysOfYear, uint256 supplyOfYear) = getYearDataFromTimestamp(_date);

        return supplyOfYear / daysOfYear;
    }

    // 今天的发行量
    function todayOfSupply() public view returns(uint256) {
        return dateOfSupply(now);
    }

    function changeLedgerAddress(string memory _ledger_name, address _new_address) onlyOwner public {
        require(ledgers[_ledger_name] != address(0), 'ledger is not exists.');

        ledgers[_ledger_name] = _new_address;

        emit LedgerChanged(_ledger_name, _new_address);
    }

}

