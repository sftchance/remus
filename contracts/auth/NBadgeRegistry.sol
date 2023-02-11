// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {NBadgeAuth, NBadgeAuthority} from "./NBadgeAuth.sol";

contract NBadgeRegistry is NBadgeAuth, NBadgeAuthority {
    ////////////////////////////////////////////////////////
    ///                     STATE                        ///
    ////////////////////////////////////////////////////////

    /// @dev The defined module-state active in the registry.
    mapping(bytes32 => NBadgeAuthority) public modules;

    ////////////////////////////////////////////////////////
    ///                     EVENTS                       ///
    ////////////////////////////////////////////////////////

    /// @dev Announces when a module is added or removed.
    event ModuleChanged(
        address indexed user,
        NBadgeAuthority indexed prevModule,
        NBadgeAuthority indexed module
    );

    ////////////////////////////////////////////////////////
    ///                  CONSTRUCTOR                     ///
    ////////////////////////////////////////////////////////

    constructor(address _authority)
        NBadgeAuth(msg.sender, NBadgeAuthority(_authority))
    {}

    ////////////////////////////////////////////////////////
    ///                    SETTERS                       ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the module-state in the registry.
     * @param _key The key of the module in the registry.
     * @param _module The module to set the state of.
     */
    function setModule(bytes32 _key, NBadgeAuthority _module)
        external
        requiresAuth(ADMIN)
    {
        /// @dev Set the module-state in the registry.
        _setModule(_key, _module);
    }

    ////////////////////////////////////////////////////////
    ///                    GETTERS                       ///
    ////////////////////////////////////////////////////////

    /**
     * See {NBadgeAuthority-canCall (full)}.
     */
    function canCall(
        address _caller,
        address _sender,
        address _target,
        bytes calldata _constitution
    ) public view override returns (bool can) {
        (bytes32 moduleKey, bytes memory moduleConstitution) = abi.decode(
            _constitution,
            (bytes32, bytes)
        );

        /// @dev Confirm the permissions through the registry modules.
        can = modules[moduleKey].canCall(
            _caller,
            _sender,
            _target,
            moduleConstitution
        );
    }

    /**
     * See {NBadgeAuthority-canCall (overloaded)}.
     */
    function canCall(
        address _caller,
        address _target,
        bytes calldata _constitution
    ) public view override returns (bool can) {
        /// @dev Call the built overloaded function.
        can = canCall(_caller, msg.sender, _target, _constitution);
    }

    ////////////////////////////////////////////////////////
    ///                INTERNAL SETTERS                  ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Set the module-state in the registry.
     * @param _key The key of the module in the registry.
     * @param _module The module to set the state of.
     */
    function _setModule(bytes32 _key, NBadgeAuthority _module) internal {
        /// @dev Get the previous module-state.
        NBadgeAuthority prevModule = modules[_key];

        /// @dev Set the module-state in the registry.
        modules[_key] = _module;

        /// @dev Emit the module change event.
        emit ModuleChanged(msg.sender, prevModule, _module);
    }
}
