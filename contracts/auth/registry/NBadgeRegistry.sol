// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/** 
    contract JourneyFactory is NBadgeAuth {
        bytes32 public constant PIN_KEY = keccak256("pin");
        bytes32 public constant WITHDRAW_KEY = keccak256("withdraw");

        constructor(Permission[] memory permissions) NBadgeAuth(msg.sender, BadgeAuthority(0x.00)) {
            for (uint256 i = 0; i < permissions.length; i++) {
                _setPermission(permission);
            }
        }

        function pinJourney(Journey memory journey) external requiresAuth(PIN_KEY) { 
            /// ...
        }

        function withdrawFunds() external requiresAuth(WITHDRAW_KEY) { 
            /// ...
        }
    }
*/

import {NBadgeAuth, NBadgeAuthority} from "../NBadgeAuth.sol";

contract NBadgeRegistry is NBadgeAuthority {
    ////////////////////////////////////////////////////////
    ///                     STATE                        ///
    ////////////////////////////////////////////////////////

    /// @dev Save the permission references for each contract.
    mapping(address => mapping(bytes32 => Reference)) public references;

    ////////////////////////////////////////////////////////
    ///                    SETTERS                       ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set a function as permission-gated.
     * @param _reference The reference to the function.
     */
    function setPermission(Reference memory _reference) external {
        /// @dev Build the reference key of the function.
        bytes32 referenceKey = _referenceKey(_reference);

        /// @dev Save the function as permission-gated.
        references[msg.sender][referenceKey] = _reference;
    }

    /**
     * @dev Set a function as public and not gated by any measure.
     * @param _reference The reference to the function.
     * @param _public True if the function is public, false otherwise.
     */
    function setPublicPermission(Reference memory _reference, bool _public)
        external
    {
        /// @dev Build the reference key of the function.
        bytes32 referenceKey = _referenceKey(_reference);

        /// @dev Save the function as public.
        references[msg.sender][referenceKey].permission.isPublic = _public;
    }

    ////////////////////////////////////////////////////////
    ///                    GETTERS                       ///
    ////////////////////////////////////////////////////////

    /**
     * See {INBadgeAuthority-canCall (full)}.
     */
    function canCall(
        address _caller,
        address _sender,
        address _target,
        bytes4 _sig,
        bytes32 _key
    ) public view override returns (bool can) {
        /// @dev Get the reference key of the permission used.
        bytes32 referenceKey = _keyReference(_sender, _target, _sig, _key);

        /// @dev Retrieve the reference out of storage.
        Reference memory permissionReference = references[_sender][
            referenceKey
        ];

        /// @dev Confirm the permissions through the registry modules.
        can = (permissionReference.permission.isPublic ||
            permissionReference.permission.module.canCall(
                _caller,
                _target,
                _sig,
                _key,
                permissionReference.permission.config
            ));
    }

    /**
     * See {INBadgeAuthority-canCall (overloaded)}.
     */
    function canCall(
        address _caller,
        address _target,
        bytes4 _sig,
        bytes32 _key
    ) public view override returns (bool can) {
        /// @dev Call the built overloaded function.
        can = canCall(_caller, address(this), _target, _sig, _key);
    }

    ////////////////////////////////////////////////////////
    ///                INTERNAL GETTERS                  ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Build the reference key of a permission.
     * @param _sender The sender (the contract of the policy) of the permission.
     * @param _target The target contract of the permission.
     * @param _sig The signature of the permission.
     * @param _key The key of the permission in the schema.
     * @return key The reference key of the permission.
     */
    function _keyReference(
        address _sender,
        address _target,
        bytes4 _sig,
        bytes32 _key
    ) internal pure returns (bytes32) {
        /// @dev Build the hash that is used to store the reference.
        return keccak256(abi.encode(_sender, _target, _sig, _key));
    }

    /**
     * @dev Build the reference key of a permission.
     * @param _reference The reference to the permission.
     * @return key The reference key of the permission.
     */
    function _referenceKey(Reference memory _reference)
        internal
        view
        returns (bytes32)
    {
        /// @dev Determine what the key for the refernece is.
        return
            _keyReference(
                msg.sender,
                _reference.target,
                _reference.sig,
                _reference.key
            );
    }
}
