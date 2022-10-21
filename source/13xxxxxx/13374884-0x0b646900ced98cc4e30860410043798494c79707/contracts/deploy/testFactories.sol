// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Address} from "contracts/libraries/Imports.sol";
import {TestMetaPoolToken} from "contracts/mapt/TestMetaPoolToken.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";

import {MetaPoolTokenFactory, OracleAdapterFactory} from "./factories.sol";

contract TestMetaPoolTokenFactory is MetaPoolTokenFactory {
    using Address for address;

    function _deployLogic(bytes memory initData)
        internal
        override
        returns (address)
    {
        TestMetaPoolToken logic = new TestMetaPoolToken();
        address _logic = address(logic);
        _logic.functionCall(initData);
        return _logic;
    }
}

contract TestOracleAdapterFactory is OracleAdapterFactory {
    address public oracleAdapter;

    function preCreate(
        address addressRegistry,
        address tvlSource,
        address[] memory assets,
        address[] memory sources,
        uint256 aggStalePeriod,
        uint256 defaultLockPeriod
    ) external returns (address) {
        oracleAdapter = super.create(
            addressRegistry,
            tvlSource,
            assets,
            sources,
            aggStalePeriod,
            defaultLockPeriod
        );
    }

    function create(
        address,
        address,
        address[] memory,
        address[] memory,
        uint256,
        uint256
    ) public override returns (address) {
        require(oracleAdapter != address(0), "USE_PRECREATE_FIRST");
        return oracleAdapter;
    }
}

