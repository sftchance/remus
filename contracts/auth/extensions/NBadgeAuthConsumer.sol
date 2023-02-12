// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {NBadgeAuth, NBadgeAuthority} from "../NBadgeAuth.sol";

/// @notice Smart contract extension that enables a set of smart contracts to utilize inherited
///         network permission configuration from a Governor.
/// @dev This extension is intended to be used by smart contracts that operate within a localized, but living
///      network. Instead of setting the permissions on every contract, the network governor can set the
///      permissions on the network governor contract and all other contracts will inherit the permissions.
/// @author Remus (https://github.com/nftchance/remus/blob/main/src/auth/extensions/NBadgeAuthConsumer.sol)
abstract contract NBadgeAuthConsumer is NBadgeAuth {
    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev Save the network governor address.
    address public networkGovernor;

    ////////////////////////////////////////////////////////
    ///                     EVENTS                       ///
    ////////////////////////////////////////////////////////

    /// @dev Announces the network governor change.
    event NetworkGovernorChanged(
        address indexed user,
        address indexed networkGovernor
    );

    ////////////////////////////////////////////////////////
    ///                   CONSTRUCTOR                    ///
    ////////////////////////////////////////////////////////

    constructor(
        address _owner,
        address _networkGovernor,
        address _authority
    )
        /// @dev Initialize the NBadgeAuth contract.
        NBadgeAuth(_owner, NBadgeAuthority(_authority))
    {
        /// @dev Make the connection to the governors network.
        _setNetworkGovernor(_networkGovernor);
    }

    ////////////////////////////////////////////////////////
    ///                     SETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the network governor.
     * @param _networkGovernor The new network governor.
     */
    function setNetworkGovernor(address _networkGovernor)
        external
        requiresAdmin
    {
        /// @dev Update the address that has managed the constitutional amendments.
        _setNetworkGovernor(_networkGovernor);
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL SETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the network governor.
     * @param _networkGovernor The new network governor.
     */
    function _setNetworkGovernor(address _networkGovernor) internal {
        /// @dev Save the new network governor.
        networkGovernor = _networkGovernor;

        /// @dev Announce the network governor change.
        emit NetworkGovernorChanged(msg.sender, _networkGovernor);
    }

    /**
     * @dev Set the constitution for a permission key.
     * @notice This function is not available when using the network governor.
     * @param _key The key to set the constitution for.
     * @param _constitution The constitution to set for the key.
     */
    function _setConstitution(bytes32 _key, bytes calldata _constitution)
        internal
        override
    {
        revert(
            "NBadgeAuthNetworkEndpoint: Cannot set constitutions when using the network governor."
        );
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL GETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Get the permission look-up address of this contract.
     * @return The address of the contract being used as a governor.
     */
    function _getAddress() internal view override returns (address) {
        return networkGovernor;
    }

    /**
     * @dev Get the constitution for a permission key.
     * @param _key The key to get the constitution for.
     * @return The constitution for the key.
     */
    function _getConstitution(bytes32 _key)
        internal
        view
        override
        returns (bytes memory)
    {
        return NBadgeAuth(networkGovernor).constitutions(_key);
    }
}
