// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Module that allows children to implement access control based on ERC1155 badges.
/// @author Remus (https://github.com/nftchance/remus/blob/main/src/auth/BadgeAccessControl.sol)
abstract contract BadgeAccessControl {
    ////////////////////////////////////////////////////////
    ///                     SCHEMA                       ///
    ////////////////////////////////////////////////////////

    /// @dev Schema for a badge token.
    struct BadgeData {
        Badge token;
        uint256 tokenId;
        uint256 balance;
    }

    /// @dev Access schema inheriting from OpenZeppelin's AccessControl.
    struct RoleData {
        BadgeData badge;
        bytes32 adminRole;
    }

    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev Tracking the single-depth role configuration.
    mapping(bytes32 => RoleData) private _roles;

    /// @dev Default admin permission powering admin-only functions.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    ////////////////////////////////////////////////////////
    ///                      EVENTS                      ///
    ////////////////////////////////////////////////////////

    /// @dev Announces a role's badge has been changed.
    event RoleBadgeChanged(
        bytes32 indexed role,
        BadgeData indexed previousBadge,
        BadgeData indexed newBadge
    );

    /// @dev Announces a role's admin role has been changed.
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    ////////////////////////////////////////////////////////
    ///                    MODIFIERS                     ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Restrict access to a function to a specific role.
     * @param _role The role access is restricted to.
     */
    modifier onlyRole(bytes32 _role) {
        _checkRole(_role);
        _;
    }

    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Check if an account has a specific role.
     * @param _role The role to check.
     * @param _account The account to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 _role, address _account)
        public
        view
        virtual
        returns (bool)
    {
        /// @dev Pull the badge out of storage.
        BadgeData memory badge = _roles[_role].badge;

        /// @dev Determine if the balance has been satisfied.
        return badge.token.balanceOf(_account, badge.tokenId) > badge.balance;
    }

    /**
     * @dev Get the admin role of a specific role.
     * @param _role The role to check.
     * @return The admin role of the role.
     * @dev If the role has no admin role, the default admin role is returned.
     */
    function getRoleAdmin(bytes32 _role) public view virtual returns (bytes32) {
        return _roles[_role].adminRole;
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL SETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Setup the configuration of a specific role.
     * @param _role The role to set up.
     * @param _badge The badge to set as the role's badge.
     */
    function _setupRole(bytes32 _role, BadgeData memory _badge)
        internal
        virtual
    {
        /// @dev Pull the role out of storage.
        RoleData storage role = _roles[_role];

        /// @dev Determine if the badge being used has changed.
        if (!_equals(role.badge, _badge)) {
            /// @dev Set the role's badge.
            _roles[_role].badge = _badge;

            /// @dev Announce the badge change.
            emit RoleBadgeChanged(_role, role.badge, _badge);
        }
    }

    /**
     * @dev Set a role's admin role.
     * @param _role The role to set the admin role of.
     * @param _adminRole The role to set as the admin role.
     * @dev If the role has no admin role, the default admin role is returned.
     */
    function _setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal virtual {
        /// @dev Get the current role admin.
        bytes32 adminRole = getRoleAdmin(_role);

        /// @dev Set the new role admin.
        _roles[_role].adminRole = _adminRole;

        /// @dev Announce the admin change.
        emit RoleAdminChanged(_role, adminRole, _adminRole);
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL GETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Check if two badge data structures are equal.
     * @param _a The first badge data structure.
     * @param _b The second badge data structure.
     * @return True if the badge data structures are equal, false otherwise.
     */
    function _equals(BadgeData memory _a, BadgeData memory _b)
        internal
        pure
        returns (bool)
    {
        /// @dev Check if the badge data structures are equal.
        return
            _a.token == _b.token &&
            _a.tokenId == _b.tokenId &&
            _a.balance == _b.balance;
    }

    /**
     * @dev Check if an account has a specific role.
     * @notice Overloaded function to use `msg.sender` as the account.
     * @param _role The role to check.
     * @dev If the account does not have the role, the function reverts.
     */
    function _checkRole(bytes32 _role) internal view virtual {
        _checkRole(_role, msg.sender);
    }

    /**
     * @dev Check if an account has a specific role.
     * @param _role The role to check.
     * @param _account The account to check.
     * @dev If the account does not have the role, the function reverts.
     */
    function _checkRole(bytes32 _role, address _account) internal view virtual {
        if (!hasRole(_role, _account)) {
            revert(
                string(
                    abi.encodePacked(
                        "BadgeAccessControl: account ",
                        Strings.toHexString(uint160(_account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
    }
}

interface Badge {
    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Returns the amount of tokens owned by `_account`.
     * @param _account The address to query the balance of.
     * @param _tokenId The token ID to query the balance of.
     * @return The amount of tokens owned by `_account`.
     */
    function balanceOf(address _account, uint256 _tokenId)
        external
        view
        returns (uint256);
}
