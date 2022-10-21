pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract DateTime {
        using SafeMath for uint256;
        using SafeMath for uint16;
        using SafeMath for uint8;
        using SafeMath for uint;

        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year.mod(4) != 0) {
                        return false;
                }
                if (year.mod(100) != 0) {
                        return true;
                }
                if (year.mod(400) != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                uint y = year.sub(1);
                return (y.div(4)).sub(y.div(100)).add(y.div(400));
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year).sub(leapYearsBefore(ORIGIN_YEAR));

                secondsAccountedFor = secondsAccountedFor.add(LEAP_YEAR_IN_SECONDS.mul(buf));
                secondsAccountedFor = secondsAccountedFor.add(YEAR_IN_SECONDS.mul(dt.year.sub(ORIGIN_YEAR.sub(buf))));

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS.mul(getDaysInMonth(i, dt.year));
                        if (secondsInMonth.add(secondsAccountedFor) > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor = secondsAccountedFor.add(secondsInMonth);
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS.add(secondsAccountedFor) > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor = secondsAccountedFor.add(DAY_IN_SECONDS);
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR.add(timestamp.div(YEAR_IN_SECONDS)));
                numLeapYears = leapYearsBefore(year).sub(leapYearsBefore(ORIGIN_YEAR));

                secondsAccountedFor = secondsAccountedFor.add(LEAP_YEAR_IN_SECONDS.mul(numLeapYears));
                secondsAccountedFor = secondsAccountedFor.add(YEAR_IN_SECONDS.mul(year.sub(ORIGIN_YEAR.sub(numLeapYears))));

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year.add(1)))) {
                                secondsAccountedFor = secondsAccountedFor.sub(LEAP_YEAR_IN_SECONDS);
                        }
                        else {
                                secondsAccountedFor = secondsAccountedFor.sub(YEAR_IN_SECONDS);
                        }
                        year = year - 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp.div(60).div(60)).mod(24));
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp.div(60)).mod(60));
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp.mod(60));
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp.div(DAY_IN_SECONDS).add(4)).mod(7));
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp = timestamp.add(LEAP_YEAR_IN_SECONDS);
                        }
                        else {
                                timestamp = timestamp.add(YEAR_IN_SECONDS);
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp = timestamp.add(DAY_IN_SECONDS.mul(monthDayCounts[i - 1]));
                }

                // Day
                timestamp = timestamp.add(DAY_IN_SECONDS.mul((day.sub(1))));

                // Hour
                timestamp = timestamp.add(HOUR_IN_SECONDS.mul(hour));

                // Minute
                timestamp = timestamp.add(MINUTE_IN_SECONDS.mul(minute));

                // Second
                timestamp = timestamp.add(second);

                return timestamp;
        }
}

