// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

abstract contract NBadgeAuth {
    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev The owner of this local contract.
    address public owner;

    /// @dev The authority contract that contains the application logic.
    NBadgeAuthority public authority;

    ////////////////////////////////////////////////////////
    ///                     EVENTS                       ///
    ////////////////////////////////////////////////////////

    /// @dev Announces when the ownership changes.
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// @dev Announces when the authority changes.
    event AuthorityChanged(
        address indexed user,
        NBadgeAuthority indexed newAuthority
    );

    ////////////////////////////////////////////////////////
    ///                   CONSTRUCTOR                    ///
    ////////////////////////////////////////////////////////

    constructor(address _owner, NBadgeAuthority _authority) {
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
    function setAuthority(NBadgeAuthority _authority, bytes32 _key)
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
        NBadgeAuthority auth = authority;

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
    function _setAuthority(NBadgeAuthority _authority) internal {
        authority = _authority;

        emit AuthorityChanged(msg.sender, _authority);
    }
}

interface NBadgeAuthority {
    /// @dev A permission to access a function.
    struct Permission {
        bool isPublic;
        NBadgeAuthority module;
        bytes config;
    }

    /// @dev A usage reference to a permission.
    struct Reference {
        address target;
        bytes4 sig;
        bytes32 key;
        Permission permission;
    }

    /**
     * @dev Determine if a user has permission to access a function.
     * @notice This function includes user-defined `_sender` to enable
     *         cross-protocol and cross-network permissions. This means,
     *         that if an organization already has a permission policy
     *         deployed there is no need to duplicate that configuration.
     * @param _caller The user who is trying to access the function.
     * @param _sender The source contract of the transaction.
     * @param _target The target contract of the function (optional).
     * @param _sig The signature of the function (optional).
     * @param _key The key of the permission in the schema (optional).
     * @return can True if the user has permission, false otherwise.
     */
    function canCall(
        address _caller,
        address _sender,
        address _target,
        bytes4 _sig,
        bytes32 _key
    ) external view returns (bool);

    /**
     * @dev Determine if a user has permission to access a function.
     * @param _caller The user who is trying to access the function.
     * @param _target The target contract of the function (optional).
     * @param _sig The signature of the function (optional).
     * @param _key The key of the permission in the schema (optional).
     * @return can True if the user has permission, false otherwise.
     */
    function canCall(
        address _caller,
        address _target,
        bytes4 _sig,
        bytes32 _key
    ) external view returns (bool);
}
