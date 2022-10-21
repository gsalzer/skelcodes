pragma solidity >=0.4.0 <0.7.0;

// time_zone is PRC
contract YearsDataSetOptimized {

    // gap of UTC and PRC time
    uint16 constant time_zone_seconds = 3600*8; // PRC的时区秒数
    uint16 constant start_year = 2020; // 开始年份
    uint16 constant end_year = 2076; // 结束年份
    // uint16[14] LeapYears = [2023,2027,2031,2035,2039,2043,2047,2051,2055,2059,2063,2067,2071,2075];
    uint16[14] LeapYears = [2024,2028,2032,2036,2040,2044,2048,2052,2056,2060,2064,2068,2072,2076]; // 闰年年份

    uint256 constant secondsInDay = 86400; // 一天的秒数
    uint256 constant maxTimestamp = 3383222400; // 最大的时间戳，用来限制输入数据
    uint256 initialDateTimestamp; // 开始发行的时间戳，PRC time zone
    uint256 firstYearSupply;

    // 限制年份
    modifier checkYear(uint256 _year)  {
        require(_year >= 2020 && _year <= 2076, 'Year number must be between 2020 and 2076');
        _;
    }

    // 限制时间戳
    modifier checkTimestamp(uint256 _time) {
        require(_time > 0 && _time <= maxTimestamp, 'Timestamp must not be be between 0 and 3383222400');
        _;
    }

    constructor(uint256 _initialDateTimestamp, uint256 _firstYearSupply) public {
        initialDateTimestamp = _initialDateTimestamp;
        firstYearSupply = _firstYearSupply;

        // for test
/*        if (initialDateTimestamp == 0)
        {
            initialDateTimestamp = 1584460800;
        }

        if (firstYearSupply == 0)
        {
            firstYearSupply = 50000000000000000;
        }
*/
        require(initialDateTimestamp > 0, 'initial DateTime can not be 0.');
        require(firstYearSupply > 0, 'First Year Supply can not be 0.');

        // 设定年度的开始和结束时间戳、一年里面的天数，总发行量，作为数据验证
        //yearsData[2020] = dayInYear(2020,1584460800,1615996800,365,50000000000000000);
        //yearsData[2021] = dayInYear(2021,1615996800,1647532800,365,25000000000000000);
        //yearsData[2022] = dayInYear(2022,1647532800,1679068800,365,12500000000000000);
        //yearsData[2023] = dayInYear(2023,1679068800,1710691200,366,6250000000000000);
        //yearsData[2024] = dayInYear(2024,1710691200,1742227200,365,3125000000000000);
        //yearsData[2025] = dayInYear(2025,1742227200,1773763200,365,1562500000000000);
        //yearsData[2026] = dayInYear(2026,1773763200,1805299200,365,781250000000000);
        //yearsData[2027] = dayInYear(2027,1805299200,1836921600,366,390625000000000);
        //yearsData[2028] = dayInYear(2028,1836921600,1868457600,365,195312500000000);
        //yearsData[2029] = dayInYear(2029,1868457600,1899993600,365,97656250000000);
        //yearsData[2030] = dayInYear(2030,1899993600,1931529600,365,48828125000000);
        //yearsData[2031] = dayInYear(2031,1931529600,1963152000,366,24414062500000);
        //yearsData[2032] = dayInYear(2032,1963152000,1994688000,365,12207031250000);
        //yearsData[2033] = dayInYear(2033,1994688000,2026224000,365,6103515625000);
        //yearsData[2034] = dayInYear(2034,2026224000,2057760000,365,3051757812500);
        //yearsData[2035] = dayInYear(2035,2057760000,2089382400,366,1525878906250);
        //yearsData[2036] = dayInYear(2036,2089382400,2120918400,365,762939453125);
        //yearsData[2037] = dayInYear(2037,2120918400,2152454400,365,381469726562);
        //yearsData[2038] = dayInYear(2038,2152454400,2183990400,365,190734863281);
        //yearsData[2039] = dayInYear(2039,2183990400,2215612800,366,95367431640);
        //yearsData[2040] = dayInYear(2040,2215612800,2247148800,365,47683715820);
        //yearsData[2041] = dayInYear(2041,2247148800,2278684800,365,23841857910);
        //yearsData[2042] = dayInYear(2042,2278684800,2310220800,365,11920928955);
        //yearsData[2043] = dayInYear(2043,2310220800,2341843200,366,5960464477);
        //yearsData[2044] = dayInYear(2044,2341843200,2373379200,365,2980232238);
        //yearsData[2045] = dayInYear(2045,2373379200,2404915200,365,1490116119);
        //yearsData[2046] = dayInYear(2046,2404915200,2436451200,365,745058059);
        //yearsData[2047] = dayInYear(2047,2436451200,2468073600,366,372529029);
        //yearsData[2048] = dayInYear(2048,2468073600,2499609600,365,186264514);
        //yearsData[2049] = dayInYear(2049,2499609600,2531145600,365,93132257);
        //yearsData[2050] = dayInYear(2050,2531145600,2562681600,365,46566128);
        //yearsData[2051] = dayInYear(2051,2562681600,2594304000,366,23283064);
        //yearsData[2052] = dayInYear(2052,2594304000,2625840000,365,11641532);
        //yearsData[2053] = dayInYear(2053,2625840000,2657376000,365,5820766);
        //yearsData[2054] = dayInYear(2054,2657376000,2688912000,365,2910383);
        //yearsData[2055] = dayInYear(2055,2688912000,2720534400,366,1455191);
        //yearsData[2056] = dayInYear(2056,2720534400,2752070400,365,727595);
        //yearsData[2057] = dayInYear(2057,2752070400,2783606400,365,363797);
        //yearsData[2058] = dayInYear(2058,2783606400,2815142400,365,181898);
        //yearsData[2059] = dayInYear(2059,2815142400,2846764800,366,90949);
        //yearsData[2060] = dayInYear(2060,2846764800,2878300800,365,45474);
        //yearsData[2061] = dayInYear(2061,2878300800,2909836800,365,22737);
        //yearsData[2062] = dayInYear(2062,2909836800,2941372800,365,11368);
        //yearsData[2063] = dayInYear(2063,2941372800,2972995200,366,5684);
        //yearsData[2064] = dayInYear(2064,2972995200,3004531200,365,2842);
        //yearsData[2065] = dayInYear(2065,3004531200,3036067200,365,1421);
        //yearsData[2066] = dayInYear(2066,3036067200,3067603200,365,710);
        //yearsData[2067] = dayInYear(2067,3067603200,3099225600,366,355);
        //yearsData[2068] = dayInYear(2068,3099225600,3130761600,365,177);
        //yearsData[2069] = dayInYear(2069,3130761600,3162297600,365,88);
        //yearsData[2070] = dayInYear(2070,3162297600,3193833600,365,44);
        //yearsData[2071] = dayInYear(2071,3193833600,3225456000,366,22);
        //yearsData[2072] = dayInYear(2072,3225456000,3256992000,365,11);
        //yearsData[2073] = dayInYear(2073,3256992000,3288528000,365,5);
        //yearsData[2074] = dayInYear(2074,3288528000,3320064000,365,2);
        //yearsData[2075] = dayInYear(2075,3320064000,3351686400,366,1);
        //yearsData[2076] = dayInYear(2076,3351686400,3383222400,365,0);

    }


    // 获取该年度的数据
    // return (年度, 开始时间戳，结束时间戳，该年度的天数，该年度的总发行量)
    function getYearDataFromYear(uint16 _year) checkYear(_year) public view  returns(uint16 , uint256 , uint256 , uint16, uint256) {

        uint256 issueVolumeOfYear = firstYearSupply; // 首年发行量
        uint256 start_gep_days = 0;
        uint256 last_year;

        uint16[14] memory _leap_years = LeapYears;

        // 算出开始时间距离发行日的天数
        for (uint16 i=start_year; i<=_year; i++)
        {
            last_year = i;
            if (i > start_year)
            {
                issueVolumeOfYear = issueVolumeOfYear / 2;
                start_gep_days += 365;
            }

            for (uint256 ii=0; ii<_leap_years.length; ii++)
            {
                if (last_year == _leap_years[ii])
                {
                    // 闰年加一天
                    start_gep_days++;
                    break;
                }
            }
        }

        uint16 _daysInYear = 365;

        last_year++;

        for (uint256 ii=0; ii<_leap_years.length; ii++)
        {
            if (last_year == _leap_years[ii])
            {
                // 闰年加一天
                _daysInYear++;
                break;
            }
        }

        uint256 start_time = initialDateTimestamp + start_gep_days*1 days; // 开始时间
        uint256 end_time = initialDateTimestamp + (start_gep_days + _daysInYear)*1 days; // 结束时间

        return (_year, start_time, end_time ,_daysInYear, issueVolumeOfYear);
    }

    // 根据时间戳来获取当年度的数据
    // return (年度, 开始时间戳，结束时间戳，该年度的天数，该年度的总发行量)
    function getYearDataFromTimestamp(uint256 _time) checkTimestamp(_time) public view returns(uint16, uint256 , uint256 , uint16 , uint256 ) {
        uint16 year;
        uint256 start_time;
        uint256 end_time;
        uint16 daysInYear;
        uint256 issueVolumeOfYear;

        // 计算_time时间戳落在那个年份内
        for (uint16 i=start_year; i<=end_year; i++)
        {
            (year, start_time, end_time ,daysInYear,issueVolumeOfYear) = getYearDataFromYear(i);

            if (_time >= start_time && _time < end_time)
            {
                break;
            }

        }
        return (year, start_time, end_time ,daysInYear, issueVolumeOfYear);
    }

    // 从时间戳获取日期的时间戳
    function getDayTimestamp(uint256 _time) checkTimestamp(_time) public pure returns (uint256) {
        uint256 mod = (_time + time_zone_seconds) % secondsInDay;

        uint256 dayTimestamp = _time - mod;
        return dayTimestamp;
    }

    // 获取时间区间内的所有日期时间戳
    function getHistoryDaysTimestamp(uint256 _dayTimestamp) checkTimestamp(_dayTimestamp) public view returns(uint256[] memory) {
        uint256 dayTimestamp = getDayTimestamp(_dayTimestamp);
        uint256 dayTimestamp2 = dayTimestamp;
        uint256 _initialDateTimestamp = initialDateTimestamp;
        uint16 count = 0;

        // 因为不支持动态数组，只能先计算数组的大小，然后再赋值过去，我日~~~~
        for (uint16 i=0; i<365; i++)
        {
            if (dayTimestamp <= _initialDateTimestamp)
            {
                break;
            }

            count++;

            dayTimestamp -= secondsInDay;
        }

        uint256[] memory daysTimestamp = new uint256[](count);

        dayTimestamp = dayTimestamp2;

        // 赋值给数组
        daysTimestamp[0] = dayTimestamp;
        for (uint16 i=1; i<count; i++)
        {
            dayTimestamp -= secondsInDay;
            daysTimestamp[i] = dayTimestamp;
        }

        return daysTimestamp;
    }
}

