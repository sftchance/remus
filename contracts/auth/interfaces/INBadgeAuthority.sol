// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import {INBadgeFramework} from "./INBadgeFramework.sol";

interface INBadgeAuthority is INBadgeFramework {
    function canCall(
        address _caller,
        address _sender,
        address _target,
        bytes4 _sig,
        bytes32 _key
    ) external view returns (bool);

    function canCall(
        address _caller,
        address _target,
        bytes4 _sig,
        bytes32 _key
    ) external view returns (bool);
}
