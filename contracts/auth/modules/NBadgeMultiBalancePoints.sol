// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {Badge} from "../NBadgeAuth.sol";
import {NBadgeModule} from "./NBadgeModule.sol";

/// @notice Drives an authentication framework using many collections and optional token ids
///         to create a cumulative points system.
/// @author Remus (https://github.com/nftchance/remus/blob/main/src/auth/modules/NBadgeMultiBalancePoints.sol)
contract NBadgeMultiBalancePoints is NBadgeModule {
    ////////////////////////////////////////////////////////
    ///                      SCHEMA                      ///
    ////////////////////////////////////////////////////////

    // struct Node {
    //     Badge badge;
    //     uint256 a -> id;
    //     uint256 b -> balance;
    //     uint256 c -> points;
    // }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL GETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Decode the constitution.
     * @param _constitution The encoded schema of the permission definition.
     * @return nodes The nodes in the authority graph.
     * @return required The number of nodes required to pass.
     */
    function _decode(bytes calldata _constitution)
        internal
        pure
        returns (Node[] memory nodes, uint256 required)
    {
        /// @dev Decode the constitution.
        return abi.decode(_constitution, (Node[], uint256));
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
        (Node[] memory nodes, uint256 required) = _decode(_constitution);

        /// @dev Load in the stack.
        uint256 points;
        uint256 i;

        /// @dev Get the node at the current index.
        Node memory node = nodes[0];

        /// @dev Determine if the user has met the proper conditions of access.
        for (i; i < nodes.length; i++) {
            /// @dev Step through the nodes until we have enough points or we run out.
            node = nodes[i];

            /// @dev If the user has sufficient balance, account for 1 points.
            if (node.badge.balanceOf(_user, node.a) >= node.b) points += node.c;

            /// @dev If enough points have been accumulated, return true.
            if (points >= required) i = nodes.length;

            /// @dev Keep on swimming.
        }

        /// @dev Final check if no mandatory badges had an insufficient balance.
        return points >= required;
    }
}
