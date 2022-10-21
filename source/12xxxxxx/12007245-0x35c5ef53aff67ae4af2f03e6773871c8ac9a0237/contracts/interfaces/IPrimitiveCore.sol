// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

import {IOption} from "@primitivefi/contracts/contracts/option/interfaces/IOption.sol";
import {IERC20Permit} from "./IERC20Permit.sol";

interface IPrimitiveCore {
    // ===== External =====

    function safeMintWithETH(IOption optionToken)
        external
        payable
        returns (uint256, uint256);

    function safeMintWithPermit(
        IOption optionToken,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256, uint256);

    function safeExerciseWithETH(IOption optionToken)
        external
        payable
        returns (uint256, uint256);

    function safeExerciseForETH(IOption optionToken, uint256 exerciseQuantity)
        external
        returns (uint256, uint256);

    function safeRedeemForETH(IOption optionToken, uint256 redeemQuantity)
        external
        returns (uint256);

    function safeCloseForETH(IOption optionToken, uint256 closeQuantity)
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

