/*

Ñíguez Randomity Engine API

MIT License

Copyright (c) 2019 niguezrandomityengine | Programmed and designed by Scheich R. Ahmed

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

// SPDX-License-Identifier: --🦉--

pragma solidity >= 0.4.0; // Compiler version incompatible error!

abstract contract niguezRandomityEngine {

	function rd() external virtual returns (uint256);
	function rm() external virtual returns (uint256);
	function rv() external virtual returns (uint256);
	function rx() external virtual returns (uint256);
	function rf() external virtual returns (uint256);

}

contract usingNRE {

  niguezRandomityEngine internal nre = niguezRandomityEngine(0x031eaE8a8105217ab64359D4361022d0947f4572);	
	function rd() internal returns (uint256) {
        return nre.rd();
    }

	function rf() internal returns (uint256) {
        return nre.rf();
    }
		
	function rm() internal returns (uint256) {
        return nre.rm();
    }

	function rv() internal returns (uint256) {
        return nre.rv();
    }
	
	function rx() internal returns (uint256) {
        return nre.rx();
    }
}

/*
End of API
*/

