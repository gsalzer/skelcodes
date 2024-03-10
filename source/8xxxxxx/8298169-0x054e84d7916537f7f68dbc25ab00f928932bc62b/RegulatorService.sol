pragma solidity 0.5.8;

import "./IRegulatorService.sol";

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int)
    {
      bytes memory h = bytes(_haystack);
      bytes memory n = bytes(_needle);
      if(h.length < 1 || n.length < 1 || (n.length > h.length))
        return -1;
      else if(h.length > (2**128 - 1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
        return -1;
      else
      {
        uint subindex = 0;
        for (uint i = 0; i < h.length; i ++)
        {
          if (h[i] == n[0]) // found the first char of b
          {
            subindex = 1;
            while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
            {
              subindex++;
            }
            if(subindex == n.length)
              return int(i);
          }
        }
        return -1;
      }
    }
}


contract RegulatorService is IRegulatorService {
    using StringUtils for string;

    function canMint(address to, string calldata iso, uint256 value) external view returns(bool) {
    	return true;
    }

    function canTransfer(address from, string calldata isoFrom, address to, string calldata isoTo, uint256 value) external view returns(bool) {
        require (block.timestamp > 1609632000 || isoFrom.equal("saver"));
    	return true;
    }

    function canAddToWhitelist(address account, string calldata iso) external view returns(bool) {
    	return true;
    }

    function canRemoveFromWhitelist(address account, string calldata iso) external view returns(bool) {
    	return true;
    }

    function canRecoveryTokens(address from, address to) external view returns(bool) {
    	return true;
    }
}

