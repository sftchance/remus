// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {Badge} from "../NBadgeAuth.sol";
import {NBadgeModule} from "./NBadgeModule.sol";

/// @notice Drives an authentication framework on a single collection with multiple token ids.
/// @author Remus (https://github.com/nftchance/remus/blob/main/src/auth/extensions/NBadgeIdPacked.sol)
contract NBadgeIdPacked is NBadgeModule {
    ////////////////////////////////////////////////////////
    ///                INTERNAL GETTERS                  ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Decode the constitution.
     * @param _constitution The encoded schema of the permission definition.
     * @return badge The badge contract.
     * @return nodeIds The node ids.
     * @return nodeSize The node size.
     * @return nodeMask The node mask.
     */
    function _decode(bytes calldata _constitution)
        internal
        pure
        returns (
            Badge badge,
            uint256 nodeIds,
            uint256 nodeSize,
            uint256 nodeMask
        )
    {
        /// @dev Decode the constitution.
        return abi.decode(_constitution, (Badge, uint256, uint256, uint256));
    }

    /**
     * @dev Determines if a user has the required credentials to call a function.
     * @param _user The user who is trying to access the function.
     * @param _constitution The encoded schema of the permission definition.
     * @return True if the user has the required credentials, false otherwise.
     */
    function _canCall(
        address _user,
        address,
        address,
        bytes calldata _constitution
    ) internal view override returns (bool) {
        /// @dev Decode the constitution.
        (
            Badge badge,
            uint256 nodeIds,
            uint256 nodeSize,
            uint256 nodeMask
        ) = _decode(_constitution);

        /// @dev Load the stack.
        uint256 i = nodeIds;

        /// @dev Iterate through the node ids.
        for (i; i != 0; i >>= nodeSize) {
            /// @dev Check if the user has the required badge.
            if (badge.balanceOf(_user, i & nodeMask) == 0) return false;
        }

        /// @dev The user has the required credentials.
        return true;
    }
}
