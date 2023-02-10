// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {INBadgeAuthority} from "./interfaces/INBadgeAuthority.sol";

abstract contract NBadgeAuth {
    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev The owner of this local contract.
    address public owner;

    /// @dev The authority contract that contains the application logic.
    INBadgeAuthority public authority;

    ////////////////////////////////////////////////////////
    ///                     EVENTS                       ///
    ////////////////////////////////////////////////////////

    /// @dev Announces when the ownership changes.
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// @dev Announces when the authority changes.
    event AuthorityChanged(
        address indexed user,
        INBadgeAuthority indexed newAuthority
    );

    ////////////////////////////////////////////////////////
    ///                   CONSTRUCTOR                    ///
    ////////////////////////////////////////////////////////

    constructor(address _owner, INBadgeAuthority _authority) {
        /// @dev Initialize the administrator access and authority.
        _setOwner(_owner);
        _setAuthority(_authority);
    }

    ////////////////////////////////////////////////////////
    ///                    MODIFIERS                     ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Restrict a function to only authorized callers.
     * @param _key The key to use for the authorization check.
     */
    modifier requiresAuth(bytes32 _key) {
        /// @dev Determine if this user is authorized to make this call.
        require(
            isAuthorized(msg.sender, msg.sig, _key),
            "BadgeAuth: Not authorized to call this function."
        );
        _;
    }

    ////////////////////////////////////////////////////////
    ///                     SETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the authority of this contract.
     * @param _authority The new authority of this contract.
     * @param _key The key to use for the authorization check.
     */
    function setAuthority(INBadgeAuthority _authority, bytes32 _key)
        public
        virtual
    {
        require(
            msg.sender == owner ||
                authority.canCall(msg.sender, address(this), msg.sig, _key),
            "BadgeAuth: Not authorized to set the authority."
        );

        _setAuthority(_authority);
    }

    /**
     * @dev Set the owner of this contract.
     * @param _owner The new owner of this contract.
     * @param _key The key to use for the authorization check.
     */
    function transferOwnership(address _owner, bytes32 _key)
        public
        virtual
        requiresAuth(_key)
    {
        _setOwner(_owner);
    }

    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

    function isAuthorized(
        address _caller,
        bytes4 _sig,
        bytes32 _key
    ) internal view returns (bool) {
        /// @dev Pull the authority out of storage.
        INBadgeAuthority auth = authority;

        /// @dev Determine if the user has permission to make this call.
        /// @notice Must pass the authority check or be the `owner`.
        return
            (address(auth) != address(0) &&
                auth.canCall(_caller, address(this), _sig, _key)) ||
            _caller == owner;
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL SETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the owner of this contract.
     * @param _owner The new owner of this contract.
     */
    function _setOwner(address _owner) internal {
        owner = _owner;

        emit OwnershipTransferred(msg.sender, _owner);
    }

    /**
     * @dev Set the authority of this contract.
     * @param _authority The new authority of this contract. (0x0 to disable
     *                  authority checks.
     */
    function _setAuthority(INBadgeAuthority _authority) internal {
        authority = _authority;

        emit AuthorityChanged(msg.sender, _authority);
    }
}
