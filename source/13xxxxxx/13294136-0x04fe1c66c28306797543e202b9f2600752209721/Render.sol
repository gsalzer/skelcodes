// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
library Render {
  function getCardImage(uint8 cardNumber, uint8 suitIndex, uint8 handIndex) internal pure returns (bytes memory) {
      string[4] memory suits = ["&#9829;","&#9824;","&#9827;","&#9830;"];
      string memory card;
      string memory suit = suits[suitIndex];

      if (cardNumber == 0) { card = 'A'; }
      else if (cardNumber == 12) { card = 'K'; }
      else if (cardNumber == 11) { card = 'Q'; }
      else if (cardNumber == 10) { card = 'J'; }
      else { card = toString(cardNumber+1); }

      string memory cardTransform;
      if (handIndex == 1) {
        cardTransform = '<g transform="matrix(0.642788, -0.766044, 0.766044, 0.642788, -221.12108, 343.312748)"> <rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" style="fill: rgb(0, 0, 0); stroke: rgb(235, 217, 13);"/> <text style="fill: rgb(235, 217, 13); text-anchor: end; white-space: pre;" x="290" y="181">';
      }
      else if (handIndex == 2) {
        cardTransform = '</text></g><g transform="matrix(0.906308, -0.422618, 0.422618, 0.906308, -148.356529, 147.110082)"> <rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" style="fill: rgb(0, 0, 0); stroke: rgb(235, 217, 13);"/> <text style="fill: rgb(235, 217, 13); text-anchor: end; white-space: pre;" x="290" y="181">';
      }
      else if (handIndex == 3) {
        cardTransform = '</text></g><g> <rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" style="fill: rgb(0, 0, 0); stroke: rgb(235, 217, 13);"/> <text style="fill: rgb(235, 217, 13); text-anchor: end; white-space: pre;" x="290" y="181">';
      }
      else if (handIndex == 4) {
        cardTransform = '</text></g><g transform="matrix(0.906308, 0.422618, -0.422618, 0.906308, 195.202635, -64.199049)"> <rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" style="stroke: rgb(236, 217, 13); fill: rgb(0, 0, 0);"/> <text style="fill: rgb(235, 217, 13); text-anchor: end; white-space: pre;" x="290" y="181">';
      }
      else if (handIndex == 5) {
        cardTransform = '</text></g><g transform="matrix(0.642788, 0.766044, -0.766044, 0.642788, 399.727275, -39.709473)"> <rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" style="fill: rgb(0, 0, 0); stroke: rgb(235, 217, 13);"/> <text style="fill: rgb(235, 217, 13); text-anchor: end; white-space: pre;" x="290" y="181">';
      }

      return abi.encodePacked(
        cardTransform,
        card,
        '</text> <text class="king" style="fill: rgb(235, 217, 13); stroke: rgb(235, 217, 13); text-anchor: middle; white-space: pre; alignment-baseline: middle;" x="250" y="227.5">',
        suit,
        '</text><text transform="rotate(180 280 288)" style="fill: rgb(235, 217, 13); text-anchor: end; white-space: pre;" x="350" y="297">',
        card);
  }

  function getBrandImage(uint256 tokenId,uint8[14] memory hand) internal pure returns (bytes memory) {
      string[10] memory A = ["&#9760;","&#9772;","&#9770;","&#9774;","&#9768;","&#9775;","&#9784;","&#9793;","&#9798;","&#9791;"];
      string[10] memory B = ["&#9812;","&#9813;","&#9814;","&#9815;","&#9816;","&#9817;","&#9834;","&#9835;","&#9841;","&#9842;"];
      string[10] memory C = ["&#9876;","&#9874;","&#9880;","&#9881;","&#9883;","&#9884;","&#9885;","&#9904;","&#9988;","&#9999;"];
      string[10] memory D = ["&#10070;","&#10086;","&#10056;","&#10052;","&#9992;","&#9996;","&#9918;","&#9832;","&#9786;","&#9785;"];
      
    return abi.encodePacked(
      '</text></g><text style="fill: rgb(235, 217, 13); font-size: 28.7px; font-style: italic; text-anchor: middle; white-space: pre;" x="247.891" y="367.545">#',
      toString(tokenId),
      '</text><text style="fill: rgb(255, 255, 255); font-family: Arial, Helvetica, sans-serif; font-size: 17.2px; font-weight: 700; letter-spacing: 1.6px; text-transform: uppercase; white-space: pre;" x="134.115" y="434.364">The Beginning Series</text><text style="fill: rgb(235, 217, 13); font-family: Arial, Helvetica, sans-serif; font-size: 23.6px; font-weight: 700; white-space: pre;" x="145.795" y="87.598">POKER NFT CLUB</text><text class="king" transform="matrix(1, 0, 0, 1, 256.173024, 26.031341)" style="fill: rgba(235, 216, 13, 0); stroke: rgb(235, 217, 13); text-anchor: middle; white-space: pre; alignment-baseline: middle;" x="250" y="227.5" dx="-470.259" dy="-207.071">',A[hand[10]],'</text><text class="king" transform="matrix(1, 0, 0, 1, 726.438649, 226.858648)" style="fill: rgba(235, 216, 13, 0); stroke: rgb(235, 217, 13); text-anchor: middle; white-space: pre; alignment-baseline: middle;" x="250" y="227.5" dx="-518.519" dy="-407.887">',B[hand[11]],'</text><text class="king" transform="matrix(1, 0, 0, 1, 726.438649, 233.093841)" style="fill: rgba(235, 216, 13, 0); stroke: rgb(235, 217, 13); text-anchor: middle; white-space: pre; alignment-baseline: middle;" x="250" y="227.5" dx="-938.116" dy="4.776">',C[hand[12]],'</text><text class="king" transform="matrix(1, 0, 0, 1, 651.242213, 394.990646)" style="fill: rgba(235, 216, 13, 0); stroke: rgb(235, 217, 13); text-anchor: middle; white-space: pre; alignment-baseline: middle;" x="250" y="227.5" dx="-442.762" dy="-157.688">',D[hand[13]],'</text></svg>'
      );
  }

  function getHeader() internal pure returns (bytes memory) {
    return '<svg viewBox="0 0 500 500" style="font:300 1.8em sans-serif" xmlns="http://www.w3.org/2000/svg"> <defs> <radialGradient gradientUnits="userSpaceOnUse" cx="250" cy="250" r="250" id="gradient-0"> <stop offset="0" style="stop-color: rgba(16, 82, 50, 1)"/> <stop offset="1" style="stop-color: rgba(0, 0, 0, 1)"/> </radialGradient> <style type="text/css">.ace{stroke:#C2BD88;stroke-width:2.25;fill:#034C29}.king{fill:#C2BD88;font-size:1.5em;stroke:#C2BD88;stroke-width:3}</style> </defs> <path id="pokey" d="M38,18 h424 a20,20 0 0 1 20,20 v424 a20,20 0 0 1 -20,20 h-424 a20,20 0 0 1 -20,-20 v-424 a20,20 0 0 1 20,-20 z"/> <rect width="500" height="500" style="fill: url(#gradient-0);"/>';
  }

  function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
