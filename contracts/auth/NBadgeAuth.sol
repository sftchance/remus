// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

abstract contract NBadgeAuth {
    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev The default permission key.
    bytes32 public constant ADMIN = 0x00;

    /// @dev The owner of this local contract.
    address public owner;

    /// @dev The `NBadgeAuthority` used to manage the access to this contract.
    NBadgeAuthority public authority;

    /// @dev Establish the constitutional permissions at the key-level.
    /// @notice The `constitution` is a still-encoded representation of the
    ///         configured permissions so that the consuming module can decode
    ///         it appropriately without standardizing on a single encoding.
    mapping(bytes32 => bytes) public constitutions;

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

    /// @dev Announces when the schema changes.
    event SchemaChanged(
        address indexed user,
        bytes32 indexed key,
        bytes schema
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
     * @dev Restrict a function to only admins.
     */
    modifier requiresAdmin() {
        /// @dev Determine if this user is authorized to make this call.
        /// @notice We check the owner first in case the authority is not set,
        ///         using an exceptional amount of gas or is reverting to enable
        ///         overriding even in the case of a bad authority.
        require(
            msg.sender == owner ||
                authority.canCall(msg.sender, address(this), constitutions[ADMIN]),
            "BadgeAuth: Not authorized to call this function."
        );
        _;
    }

    /**
     * @dev Restrict a function to only authorized callers.
     * @param _key The key to use for the authorization check.
     */
    modifier requiresAuth(bytes32 _key) {
        /// @dev Determine if this user is authorized to make this call.
        require(
            _isAuthorized(msg.sender, _key),
            "BadgeAuth: Not authorized to call this function."
        );
        _;
    }

    ////////////////////////////////////////////////////////
    ///                     SETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the NBadgeAuthority contract used for enforcement.
     * @param _authority The new authority of this contract.
     */
    function setAuthority(NBadgeAuthority _authority)
        public
        virtual
        requiresAdmin
    {
        _setAuthority(_authority);
    }

    /**
     * @dev Set the constitution for a permission key.
     * @param _key The key to set the constitution for.
     * @param _constitution The constitution to set for the key.
     */
    function setConstitution(bytes32 _key, bytes calldata _constitution)
        public
        virtual
        requiresAdmin
    {
        _setConstitution(_key, _constitution);
    }

    /**
     * @dev Set the owner of this contract.
     * @param _owner The new owner of this contract.
     */
    function transferOwnership(address _owner) public virtual requiresAdmin {
        _setOwner(_owner);
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL SETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the owner of this contract.
     * @param _owner The new owner of this contract.
     */
    function _setOwner(address _owner) internal {
        /// @dev Set the new owner of the contract.
        owner = _owner;

        /// @dev Announce the ownership change.
        emit OwnershipTransferred(msg.sender, _owner);
    }

    /**
     * @dev Set the authority of this contract.
     * @param _authority The new authority of this contract. (0x0 to disable
     *                  authority checks.
     */
    function _setAuthority(NBadgeAuthority _authority) internal {
        /// @dev Set the new authority of the contract.
        authority = _authority;

        /// @dev Announce the authority change.
        emit AuthorityChanged(msg.sender, _authority);
    }

    /**
     * @dev Set the constitution for a permission key.
     * @param _key The key to set the constitution for.
     * @param _constitution The constitution to set for the key.
     */
    function _setConstitution(bytes32 _key, bytes calldata _constitution)
        internal
    {
        /// @dev Set the new schema for the key.
        constitutions[_key] = _constitution;

        /// @dev Announce the schema change.
        emit SchemaChanged(msg.sender, _key, _constitution);
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL GETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Determine if the user is authorized to make this call.
     * @param _caller The user making the call.
     * @param _key The key to use for the authorization check.
     * @return True if the user is authorized to make this call, false otherwise.
     */
    function _isAuthorized(address _caller, bytes32 _key)
        internal
        view
        returns (bool)
    {
        /// @dev Pull the authority out of storage.
        NBadgeAuthority auth = authority;

        /// @dev Determine if the user has permission to make this call.
        /// @notice Must pass the authority check or be the `owner`.
        return
            (address(auth) != address(0) &&
                auth.canCall(_caller, address(this), constitutions[_key])) ||
            _caller == owner;
    }
}

interface Badge {
    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Get the balance of a token for a user.
     * @param _owner The user to get the balance for.
     * @param _id The token to get the balance for.
     * @return The balance of the token for the user.
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);
}

interface NBadgeAuthority {
    ////////////////////////////////////////////////////////
    ///                     SCHEMA                       ///
    ////////////////////////////////////////////////////////

    /// @dev A node in the authority graph.
    struct Node { 
        Badge badge;
        uint256 a;
        uint256 b;
        uint256 c;
    }

    /// @dev A permission to access a function.
    struct Permission {
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

    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Determine if a user has permission to access a function.
     * @notice This function includes user-defined `_sender` to enable
     *         cross-protocol and cross-network permissions. This means,
     *         that if an organization already has a permission policy
     *         deployed there is no need to duplicate that configuration.
     * @param _caller The user who is trying to access the function.
     * @param _sender The source contract of the transaction.
     * @param _target The target contract of the function (optional).
     * @param _constitution The key of the permission in the schema (optional).
     * @return can True if the user has permission, false otherwise.
     */
    function canCall(
        address _caller,
        address _sender,
        address _target,
        bytes memory _constitution
    ) external view returns (bool);

    /**
     * @dev Determine if a user has permission to access a function.
     * @param _caller The user who is trying to access the function.
     * @param _target The target contract of the function (optional).
     * @param _constitution The key of the permission in the schema (optional).
     * @return can True if the user has permission, false otherwise.
     */
    function canCall(
        address _caller,
        address _target,
        bytes memory _constitution
    ) external view returns (bool);
}
