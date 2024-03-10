//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract LetsgoNFTBase {
    uint256 public mantissa = 10000;

    struct AddreessWithPercent {
        address addr;
        uint256 value;
    }

    function validateCoCreators(AddreessWithPercent[] memory coCreators) external view{
         require(
            coCreators.length <= 10,
            "validateCoCreators: coCreators length should be less or equal to 10"
        );

        uint256 coCreatorsSum = 0;

        for (uint256 i = 0; i < coCreators.length; i++) {
            require(
                coCreators[i].addr != address(0),
                "validateCoCreators: coCreator address address can't be empty"
            );
            require(
                coCreators[i].value > 0,
                "validateCoCreators: coCreator value must be higher than 0"
            );
            coCreatorsSum += coCreators[i].value;
        }
        
        require(
            coCreatorsSum <= mantissa,
            "validateCoCreators: coCreators sum should be less or equal to 100%"
        );
    }

    function validateAffiliates(AddreessWithPercent[] memory affiliates) external view{
        require(
            affiliates.length <= 10,
            "validateAffiliates: affiliates length should be less or equal to 10"
        );

        uint256 affiliatesSum = 0;

        for (uint256 i = 0; i < affiliates.length; i++) {
            require(
                affiliates[i].addr != address(0),
                "validateAffiliates: affiliate address address can't be empty"
            );
            require(
                affiliates[i].value > 0,
                "validateAffiliates: affiliate value must be higher than 0"
            );
            affiliatesSum += affiliates[i].value;
        }

        require(
            affiliatesSum <= mantissa,
            "validateAffiliates: affiliates sum should be less or equal to 100%"
        );
    }
}
