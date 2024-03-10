// Verified using https://dapp.tools

// hevm: flattened sources of src/lender/deployer.sol
pragma solidity >=0.5.15 <0.6.0;

////// src/fixed_point.sol
// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.15 <0.6.0; */

contract FixedPoint {
    struct Fixed27 {
        uint value;
    }
}

////// src/lender/fabs/interfaces.sol
// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
/* pragma solidity >=0.5.15 <0.6.0; */

interface ReserveFabLike_1 {
    function newReserve(address) external returns (address);
}

interface AssessorFabLike_2 {
    function newAssessor() external returns (address);
}

interface TrancheFabLike_1 {
    function newTranche(address, address) external returns (address);
}

interface CoordinatorFabLike_2 {
    function newCoordinator(uint) external returns (address);
}

interface OperatorFabLike_1 {
    function newOperator(address) external returns (address);
}

interface MemberlistFabLike_1 {
    function newMemberlist() external returns (address);
}

interface RestrictedTokenFabLike_1 {
    function newRestrictedToken(string calldata, string calldata) external returns (address);
}

interface AssessorAdminFabLike {
    function newAssessorAdmin() external returns (address);
}



////// src/lender/deployer.sol
// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
/* pragma solidity >=0.5.15 <0.6.0; */

/* import { ReserveFabLike, AssessorFabLike, TrancheFabLike, CoordinatorFabLike, OperatorFabLike, MemberlistFabLike, RestrictedTokenFabLike, AssessorAdminFabLike } from "./fabs/interfaces.sol"; */

/* import {FixedPoint}      from "./../fixed_point.sol"; */


interface DependLike_2 {
    function depend(bytes32, address) external;
}

interface AuthLike_2 {
    function rely(address) external;
    function deny(address) external;
}

interface MemberlistLike_1 {
    function updateMember(address, uint) external;
}

interface FileLike_2 {
    function file(bytes32 name, uint value) external;
}

contract LenderDeployer is FixedPoint {
    address public root;
    address public currency;

    // factory contracts
    TrancheFabLike_1          public trancheFab;
    ReserveFabLike_1          public reserveFab;
    AssessorFabLike_2         public assessorFab;
    CoordinatorFabLike_2      public coordinatorFab;
    OperatorFabLike_1         public operatorFab;
    MemberlistFabLike_1       public memberlistFab;
    RestrictedTokenFabLike_1  public restrictedTokenFab;
    AssessorAdminFabLike    public assessorAdminFab;

    // lender state variables
    Fixed27             public minSeniorRatio;
    Fixed27             public maxSeniorRatio;
    uint                public maxReserve;
    uint                public challengeTime;
    Fixed27             public seniorInterestRate;


    // contract addresses
    address             public assessor;
    address             public assessorAdmin;
    address             public seniorTranche;
    address             public juniorTranche;
    address             public seniorOperator;
    address             public juniorOperator;
    address             public reserve;
    address             public coordinator;

    address             public seniorToken;
    address             public juniorToken;

    // token names
    string              public seniorName;
    string              public seniorSymbol;
    string              public juniorName;
    string              public juniorSymbol;
    // restricted token member list
    address             public seniorMemberlist;
    address             public juniorMemberlist;

    address             public deployer;

    constructor(address root_, address currency_, address trancheFab_, address memberlistFab_, address restrictedtokenFab_, address reserveFab_, address assessorFab_, address coordinatorFab_, address operatorFab_, address assessorAdminFab_) public {

        deployer = msg.sender;
        root = root_;
        currency = currency_;

        trancheFab = TrancheFabLike_1(trancheFab_);
        memberlistFab = MemberlistFabLike_1(memberlistFab_);
        restrictedTokenFab = RestrictedTokenFabLike_1(restrictedtokenFab_);
        reserveFab = ReserveFabLike_1(reserveFab_);
        assessorFab = AssessorFabLike_2(assessorFab_);
        assessorAdminFab = AssessorAdminFabLike(assessorAdminFab_);
        coordinatorFab = CoordinatorFabLike_2(coordinatorFab_);
        operatorFab = OperatorFabLike_1(operatorFab_);
    }

    function init(uint minSeniorRatio_, uint maxSeniorRatio_, uint maxReserve_, uint challengeTime_, uint seniorInterestRate_, string memory seniorName_, string memory seniorSymbol_, string memory juniorName_, string memory juniorSymbol_) public {
        require(msg.sender == deployer);
        challengeTime = challengeTime_;
        minSeniorRatio = Fixed27(minSeniorRatio_);
        maxSeniorRatio = Fixed27(maxSeniorRatio_);
        maxReserve = maxReserve_;
        seniorInterestRate = Fixed27(seniorInterestRate_);

        // token names
        seniorName = seniorName_;
        seniorSymbol = seniorSymbol_;
        juniorName = juniorName_;
        juniorSymbol = juniorSymbol_;

        deployer = address(1);
    }

    function deployJunior() public {
        require(juniorTranche == address(0) && deployer == address(1));
        juniorToken = restrictedTokenFab.newRestrictedToken(juniorName, juniorSymbol);
        juniorTranche = trancheFab.newTranche(currency, juniorToken);
        juniorMemberlist = memberlistFab.newMemberlist();
        juniorOperator = operatorFab.newOperator(juniorTranche);
        AuthLike_2(juniorMemberlist).rely(root);
        AuthLike_2(juniorToken).rely(root);
        AuthLike_2(juniorToken).rely(juniorTranche);
        AuthLike_2(juniorOperator).rely(root);
        AuthLike_2(juniorTranche).rely(root);
    }

    function deploySenior() public {
        require(seniorTranche == address(0) && deployer == address(1));
        seniorToken = restrictedTokenFab.newRestrictedToken(seniorName, seniorSymbol);
        seniorTranche = trancheFab.newTranche(currency, seniorToken);
        seniorMemberlist = memberlistFab.newMemberlist();
        seniorOperator = operatorFab.newOperator(seniorTranche);
        AuthLike_2(seniorMemberlist).rely(root);
        AuthLike_2(seniorToken).rely(root);
        AuthLike_2(seniorToken).rely(seniorTranche);
        AuthLike_2(seniorOperator).rely(root);
        AuthLike_2(seniorTranche).rely(root);

    }

    function deployReserve() public {
        require(reserve == address(0) && deployer == address(1));
        reserve = reserveFab.newReserve(currency);
        AuthLike_2(reserve).rely(root);
    }

    function deployAssessor() public {
        require(assessor == address(0) && deployer == address(1));
        assessor = assessorFab.newAssessor();
        AuthLike_2(assessor).rely(root);
    }

    function deployAssessorAdmin() public {
        require(assessorAdmin == address(0) && deployer == address(1));
        assessorAdmin = assessorAdminFab.newAssessorAdmin();
        AuthLike_2(assessorAdmin).rely(root);
    }

    function deployCoordinator() public {
        require(coordinator == address(0) && deployer == address(1));
        coordinator = coordinatorFab.newCoordinator(challengeTime);
        AuthLike_2(coordinator).rely(root);
    }

    function deploy() public {
        require(coordinator != address(0) && assessor != address(0) &&
                reserve != address(0) && seniorTranche != address(0));

        // required depends
        // reserve
        DependLike_2(reserve).depend("assessor", assessor);
        AuthLike_2(reserve).rely(seniorTranche);
        AuthLike_2(reserve).rely(juniorTranche);
        AuthLike_2(reserve).rely(coordinator);
        AuthLike_2(reserve).rely(assessor);


        // tranches
        DependLike_2(seniorTranche).depend("reserve",reserve);
        DependLike_2(juniorTranche).depend("reserve",reserve);
        AuthLike_2(seniorTranche).rely(coordinator);
        AuthLike_2(juniorTranche).rely(coordinator);
        AuthLike_2(seniorTranche).rely(seniorOperator);
        AuthLike_2(juniorTranche).rely(juniorOperator);

        // coordinator implements epoch ticker interface
        DependLike_2(seniorTranche).depend("epochTicker", coordinator);
        DependLike_2(juniorTranche).depend("epochTicker", coordinator);

        //restricted token
        DependLike_2(seniorToken).depend("memberlist", seniorMemberlist);
        DependLike_2(juniorToken).depend("memberlist", juniorMemberlist);

        //allow tinlake contracts to hold drop/tin tokens
        MemberlistLike_1(juniorMemberlist).updateMember(juniorTranche, uint(-1));
        MemberlistLike_1(seniorMemberlist).updateMember(seniorTranche, uint(-1));

        // operator
        DependLike_2(seniorOperator).depend("tranche", seniorTranche);
        DependLike_2(juniorOperator).depend("tranche", juniorTranche);
        DependLike_2(seniorOperator).depend("token", seniorToken);
        DependLike_2(juniorOperator).depend("token", juniorToken);


        // coordinator
        DependLike_2(coordinator).depend("reserve", reserve);
        DependLike_2(coordinator).depend("seniorTranche", seniorTranche);
        DependLike_2(coordinator).depend("juniorTranche", juniorTranche);
        DependLike_2(coordinator).depend("assessor", assessor);

        // assessor
        DependLike_2(assessor).depend("seniorTranche", seniorTranche);
        DependLike_2(assessor).depend("juniorTranche", juniorTranche);
        DependLike_2(assessor).depend("reserve", reserve);

        AuthLike_2(assessor).rely(coordinator);
        AuthLike_2(assessor).rely(reserve);
        AuthLike_2(assessor).rely(assessorAdmin);

        // assessorAdmin
        DependLike_2(assessorAdmin).depend("assessor", assessor);

        FileLike_2(assessor).file("seniorInterestRate", seniorInterestRate.value);
        FileLike_2(assessor).file("maxReserve", maxReserve);
        FileLike_2(assessor).file("maxSeniorRatio", maxSeniorRatio.value);
        FileLike_2(assessor).file("minSeniorRatio", minSeniorRatio.value);
    }
}

