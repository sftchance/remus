// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {Badge} from "../NBadgeAuth.sol";
import {NBadgeModule} from "./NBadgeModule.sol";

/// @notice Drives an authentication framework using many collections, many token ids, required balances
///         while having the ability to make some badges mandatory.
/// @author Remus (https://github.com/nftchance/remus/blob/main/src/auth/modules/NBadgeMultiBalance.sol)
contract NBadgeMultiBalance is NBadgeModule {
    ////////////////////////////////////////////////////////
    ///                      SCHEMA                      ///
    ////////////////////////////////////////////////////////

    // struct Node {
    //     Badge badge;
    //     uint256 a -> mandatory;
    //     uint256 b -> id;
    //     uint256 c -> balance;
    // }

    ////////////////////////////////////////////////////////
    ///                INTERNAL GETTERS                  ///
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
        uint256 carried;
        uint256 i;

        /// @dev Get the node at the current index.
        Node memory node = nodes[carried];

        /// @dev Determine if the user has met the proper conditions of access.
        for (i; i < nodes.length; i++) {
            /// @dev Step through the nodes until we have enough carried or we run out.
            node = nodes[i];

            /// @dev If the user has sufficient balance, account for 1 carried.
            if (node.badge.balanceOf(_user, node.b) >= node.c)
                carried++;
                /// @dev If the node is required and balance is insufficient, we can't continue.
            else if (node.a == 1) return false;

            /// @dev Keep on swimming.
        }

        /// @dev Final check if no mandatory badges had an insufficient balance.
        return carried >= required;
    }
}
