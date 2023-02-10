// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

interface INBadgeModule {
    function canCall(
        address _caller,
        address _target,
        bytes4 _sig,
        bytes32 _key,
        bytes calldata _config
    ) external view returns (bool);
}
