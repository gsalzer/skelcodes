// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {DerivedRunner, DerivedRunnerConfig} from "./shared/DerivedRunner.sol";
import {CreatorConfig} from "./shared/Creator.sol";
import {FeeableConfig} from "./shared/Feeable.sol";

contract SyntheticRunners is DerivedRunner {
    constructor(
        DerivedRunnerConfig memory derivedRunnerConfig,
        CreatorConfig memory creatorConfig,
        FeeableConfig memory feeableConfig
    ) ERC721("Synthetic Runners", "SYNTHRUN") {
        initialize(derivedRunnerConfig, creatorConfig, feeableConfig);
    }
}

