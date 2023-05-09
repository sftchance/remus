// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

/**
 * @title LibColor
 * @author sftchance.eth
 * @notice This library handles the bitpacking and unpacking of colors to use a
 *         single `uint256` as a colormap with bitpacked domains creating a
 *         native representation with managed stops.
 */
library LibColorRGB {
    // A look-up table to simplify the conversion from number to hexstring.
    bytes32 constant HEXADECIMAL_DIGITS = "0123456789ABCDEF";

    /// @dev The size of color index in each bitpacked value.
    uint24 constant BYTE_SIZE = 8;

    /// @dev The size of color index in each bitpacked value.
    uint24 constant BYTE_MASK = 0xFF;

    /// @dev Mask to extra half a byte from a byte.
    uint24 constant HALF_BYTE_MASK = 0xF;

    /**
    * @notice Pack individual RGB components into a single uint24 value.
    * @param $r The red component, a number between 0 and 255.
    * @param $g The green component, a number between 0 and 255.
    * @param $b The blue component, a number between 0 and 255.
    * @return $color The bitpacked color with the given RGB components.
    */
    function pack(uint8 $r, uint8 $g, uint8 $b) public pure returns (uint24 $color) {
        /// @dev Pack the rgb values into a single uint24.
        $color = uint24($r) << (BYTE_SIZE * 2) | uint24($g) << BYTE_SIZE | uint24($b);
    }

    /**
     * @notice Get the [0-255] value of the blue channel of the color.
     * @param $color The bitpacked color to extract the blue channel from.
     * @return $r The [0-255] value of the blue channel of the color.
     */
    function r(uint24 $color) public pure returns (uint8 $r) {
        /// @dev Extract the rgb values from the bitpacked color.
        $r = uint8(($color >> (BYTE_SIZE * 2)) & BYTE_MASK);
    }

    /**
     * @notice Get the [0-255] value of the green channel of the color.
     * @param $color The bitpacked color to extract the green channel from.
     * @return $g The [0-255] value of the green channel of the color.
     */
    function g(uint24 $color) public pure returns (uint8 $g) {
        /// @dev Extract the rgb values from the bitpacked color.
        $g = uint8(($color >> BYTE_SIZE) & BYTE_MASK);
    }

    /**
     * @notice Get the [0-255] value of the red channel of the color.
     * @param $color The bitpacked color to extract the red channel from.
     * @return $b The [0-255] value of the red channel of the color.
     */
    function b(uint24 $color) public pure returns (uint8 $b) {
        /// @dev Extract the rgb values from the bitpacked color.
        $b = uint8($color & BYTE_MASK);
    }

    /**
     * @notice Get the [0-255] value of the red, green, and blue channels of the
     *        color.
     * @param $color The bitpacked color to extract the rgb channels from.
     * @return $r The [0-255] value of the red channel of the color.
     * @return $g The [0-255] value of the green channel of the color.
     * @return $b The [0-255] value of the blue channel of the color.
     */
    function rgb(
        uint24 $color
    ) public pure returns (uint8 $r, uint8 $g, uint8 $b) {
        /// @dev Extract the rgb values from the bitpacked color.
        $r = r($color);
        $g = g($color);
        $b = b($color);
    }

    /**
     * @notice Convert a hexadecimal string representation of a color to a
     *         bitpacked uint24 value.
     * @param $hex The hexadecimal string representation of the color.
     * @return $color The bitpacked uint24 value of the color.
     */
    function number(bytes memory $hex) public pure returns (uint24 $color) {
        /// @dev Convert the hexadecimal string to a bytes array.
        require($hex.length == 6, "LibColor::number: Invalid hexadecimal color string length");

        /// @dev Parse the bytes array to extract the red, green, and blue components.
        uint8 $r = (hexadecimalByte($hex[0]) << 4) | hexadecimalByte($hex[1]);
        uint8 $g = (hexadecimalByte($hex[2]) << 4) | hexadecimalByte($hex[3]);
        uint8 $b = (hexadecimalByte($hex[4]) << 4) | hexadecimalByte($hex[5]);

        /// @dev Pack the red, green, and blue components into a single uint24 value.
        $color = pack($r, $g, $b);
    }

    /**
     * @notice Get the hexadecimal string representation of the color.
     * @param $color The bitpacked color to convert to a hexadecimal string.
     * @return $hex The hexadecimal string representation of the color.
     */
    function hexadecimal(
        uint24 $color
    ) public pure returns (string memory $hex) {
        /// @dev Extract the rgb values from the bitpacked color.
        (uint8 $r, uint8 $g, uint8 $b) = rgb($color);

        /// @dev Convert the rgb values to a hexadecimal string representation.
        $hex = string(
            abi.encodePacked(
                HEXADECIMAL_DIGITS[$r >> 4],
                HEXADECIMAL_DIGITS[$r & HALF_BYTE_MASK],
                HEXADECIMAL_DIGITS[$g >> 4],
                HEXADECIMAL_DIGITS[$g & HALF_BYTE_MASK],
                HEXADECIMAL_DIGITS[$b >> 4],
                HEXADECIMAL_DIGITS[$b & HALF_BYTE_MASK]
            )
        );
    }

    /**
    * @notice Parse a single byte in hexadecimal notation.
    * @param $byte The byte to parse.
    * @return The parsed value of the byte.
    */
    function hexadecimalByte(bytes1 $byte) internal pure returns (uint8) {
        if ($byte >= 0x30 && $byte <= 0x39) {
            return uint8($byte) - 0x30;
        } else if ($byte >= 0x41 && $byte <= 0x46) {
            return uint8($byte) - 0x37;
        } else if ($byte >= 0x61 && $byte <= 0x66) {
            return uint8($byte) - 0x57;
        }

        revert("LibColor::hexadecimalByte: Invalid hexadecimal character");
    }
}