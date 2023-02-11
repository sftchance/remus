// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {Badge} from "../NBadgeAuth.sol";
import {NBadgeModule} from "./NBadgeModule.sol";

/// @notice Drives an authentication framework on a single collection with multiple token ids.
/// @author Remus (https://github.com/nftchance/remus/blob/main/src/auth/extensions/NBadgeIdPacked.sol)
contract NBadgeIdPacked is NBadgeModule {
    ////////////////////////////////////////////////////////
    ///                      SCHEMA                      ///
    ////////////////////////////////////////////////////////

    // struct Node {
    //     Badge badge;
    //     uint256 a -> nodeIds;
    //     uint256 b -> nodeSize;
    //     uint256 c -> nodeMask;
    // }

    ////////////////////////////////////////////////////////
    ///                INTERNAL GETTERS                  ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Decode the constitution.
     * @param _constitution The encoded schema of the permission definition.
     * @return node The authority node being enforced.
     */
    function _decode(bytes calldata _constitution)
        internal
        pure
        returns (Node memory)
    {
        /// @dev Decode the constitution.
        return abi.decode(_constitution, (Node));
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
        (Node memory node) = _decode(_constitution); 

        /// @dev Load the stack.
        uint256 i = node.a;

        /// @dev Iterate through the node ids.
        for (i; i != 0; i >>= node.b) {
            /// @dev Check if the user has the required badge.
            if (node.badge.balanceOf(_user, i & node.c) == 0) return false;
        }

        /// @dev The user has the required credentials.
        return true;
    }
}
