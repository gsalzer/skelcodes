pragma solidity 0.5.10;

/**
 * @title LibBlob
 * @dev Blob related utility functions
 */
library LibBlob
{
    struct Metadata
    {
        uint partner;
        uint level;
        uint param1;
        uint param2;
        uint param3;
        uint param4;
        uint param5;
        uint param6;
    }

    struct Name
    {
        uint char1;
        uint char2;
        uint char3;
        uint char4;
        uint char5;
        uint char6;
        uint char7;
        uint char8;
    }

    /**
     * @dev Convert metadata to a single integer
     * @param metadata The metadata to be converted
     * @return uint The integer representing the metadata
     */
    function metadataToUint(Metadata memory metadata) internal pure returns (uint)
    {
        uint params = uint(metadata.partner);
        params |= metadata.level<<32;
        params |= metadata.param1<<64;
        params |= metadata.param2<<96;
        params |= metadata.param3<<128;
        params |= metadata.param4<<160;
        params |= metadata.param5<<192;
        params |= metadata.param6<<224;

        return params;
    }

    /**
     * @dev Convert given integer to a metadata object
     * @param params The integer to be converted
     * @return Metadata The metadata represented by the integer
     */
    function uintToMetadata(uint params) internal pure returns (Metadata memory)
    {
        Metadata memory metadata;

        metadata.partner = uint(uint32(params));
        metadata.level = uint(uint32(params>>32));
        metadata.param1 = uint(uint32(params>>64));
        metadata.param2 = uint(uint32(params>>96));
        metadata.param3 = uint(uint32(params>>128));
        metadata.param4 = uint(uint32(params>>160));
        metadata.param5 = uint(uint32(params>>192));
        metadata.param6 = uint(uint32(params>>224));

        return metadata;
    }

    /**
     * @dev Convert name to a single integer
     * @param name The name to be converted
     * @return uint The integer representing the name
     */
    function nameToUint(Name memory name) internal pure returns (uint)
    {
        uint params = uint(name.char1);
        params |= name.char2<<32;
        params |= name.char3<<64;
        params |= name.char4<<96;
        params |= name.char5<<128;
        params |= name.char6<<160;
        params |= name.char7<<192;
        params |= name.char8<<224;

        return params;
    }

    /**
     * @dev Convert given integer to a name object
     * @param params The integer to be converted
     * @return Name The name represented by the integer
     */
    function uintToName(uint params) internal pure returns (Name memory)
    {
        Name memory name;

        name.char1 = uint(uint32(params));
        name.char2 = uint(uint32(params>>32));
        name.char3 = uint(uint32(params>>64));
        name.char4 = uint(uint32(params>>96));
        name.char5 = uint(uint32(params>>128));
        name.char6 = uint(uint32(params>>160));
        name.char7 = uint(uint32(params>>192));
        name.char8 = uint(uint32(params>>224));

        return name;
    }
}

