// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import {NBadgeAuthority} from "./NBadgeAuth.sol";

abstract contract NBadgeModule is NBadgeAuthority {
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
     * @param _target The target contract of the function (optional).
     * @param _constitution The key of the permission in the schema (optional).
     * @return can True if the user has permission, false otherwise.
     */
    function canCall(
        address _caller,
        address _sender,
        address _target,
        bytes calldata _constitution
    ) external view override returns (bool) {
        return _canCall(_caller, _sender, _target, _constitution);
    }

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
        bytes calldata _constitution
    ) external view override returns (bool) {
        return _canCall(_caller, msg.sender, _target, _constitution);
    }

    /**
     * @dev The internal logic that determines if a user has permission
     *      to mamke the function call.
     * @param _caller The user who is trying to access the function.
     * @param _sender The source contract of the transaction (optional).
     * @param _target The target contract of the function (optional).
     * @param _constitution The key of the permission in the schema.
     */
    function _canCall(
        address _caller,
        address _sender,
        address _target,
        bytes calldata _constitution
    ) internal view virtual returns (bool);
}
