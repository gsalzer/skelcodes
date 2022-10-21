// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {AlphaDeployment} from "./AlphaDeployment.sol";

contract TestAlphaDeployment is AlphaDeployment {
    constructor(
        address proxyFactory_,
        address addressRegistryV2Factory,
        address mAptFactory_,
        address poolTokenV1Factory_,
        address poolTokenV2Factory_,
        address tvlManagerFactory_,
        address erc20AllocationFactory_,
        address oracleAdapterFactory_,
        address lpAccountFactory_
    )
        public
        AlphaDeployment(
            proxyFactory_,
            addressRegistryV2Factory,
            mAptFactory_,
            poolTokenV1Factory_,
            poolTokenV2Factory_,
            tvlManagerFactory_,
            erc20AllocationFactory_,
            oracleAdapterFactory_,
            lpAccountFactory_
        )
    {} // solhint-disable no-empty-blocks

    function testSetStep(uint256 step_) public {
        step = step_;
    }

    function testSetMapt(address mApt_) public {
        mApt = mApt_;
    }

    function testSetPoolTokenV2(address poolTokenV2_) public {
        poolTokenV2 = poolTokenV2_;
    }

    function testSetTvlManager(address tvlManager_) public {
        tvlManager = tvlManager_;
    }

    function testSetLpAccount(address lpAccount_) public {
        lpAccount = lpAccount_;
    }

    function testSetErc20Allocation(address erc20Allocation_) public {
        erc20Allocation = erc20Allocation_;
    }
}

