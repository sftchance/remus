// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @notice Provides a fingerprint system to non-fungible tokens used to enable the secure
///         operation of governance and other token-driven functions.
/// @author Remus (https://github.com/nftchance/remus/blob/main/src/auth/Fingerprint.sol)
contract Fingerprint {
    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev The decay rate of the fingerprints.
    uint256 public immutable fingerprintDecayRate;

    /// @dev The fingerprints that have been recently used.
    mapping(bytes32 => uint256) private fingerprints;

    ////////////////////////////////////////////////////////
    ///                   CONSTRUCTOR                    ///
    ////////////////////////////////////////////////////////

    constructor(uint256 _fingerprintDecayRate) {
        /// @dev Make sure the decay rate is not too high.
        require(
            _fingerprintDecayRate < block.timestamp,
            "Fingerprint: decay rate too high"
        );

        /// @dev Store the decay rate.
        fingerprintDecayRate = _fingerprintDecayRate;
    }

    ////////////////////////////////////////////////////////
    ///                    MODIFIERS                     ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Make sure the fingerprint is available for use.
     * @param _print The fingerprint to check.
     */
    modifier onlyVirgin(bytes32 _print) {
        /// @dev Allow if fingerprint has never been used or if decay has occurred.
        require(
            fingerprints[_print] == 0 || fingerprints[_print] < block.timestamp,
            "Fingerprint: already used"
        );
        _;
    }

    /**
     * @dev Make sure the fingerprint is valid.
     * @param _print The fingerprint to check.
     */
    modifier onlyValid(bytes32 _print) {
        /// @dev Make sure the fingerprint is valid.
        require(fingerprints[_print] > 0, "Fingerprint: invalid");
        _;
    }

    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Get the fingerprint of a source.
     * @param _print The fingerprint to check.
     */
    function fingerprintOf(bytes32 _print)
        external
        view
        onlyValid(_print)
        returns (uint256)
    {
        return fingerprints[_print];
    }

    ////////////////////////////////////////////////////////
    ///                     SETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Fingerprint a source.
     * @notice Math occurs here although called decay rate, as the source
     *         of the fingerprint will pay the increased gas cost
     *         rather than the consuming users and/or protocol.
     * @param _print The fingerprint to use.
     */
    function _fingerprint(bytes32 _print) internal onlyVirgin(_print) {
        /// @dev Set the time of decay for the fingerprint.
        fingerprints[_print] = block.timestamp + fingerprintDecayRate;
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL GETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Get the fingerprint of a source.
     * @param _source The source of the fingerprint.
     * @param _tokenId The token id of the fingerprint.
     */
    function _fingerprint(address _source, uint256 _tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_source, _tokenId));
    }
}
