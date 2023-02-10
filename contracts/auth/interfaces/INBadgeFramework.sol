// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import {INBadgeModule} from "./INBadgeModule.sol";

interface INBadgeFramework {
    struct Permission {
        bool isPublic;
        INBadgeModule module;
        bytes config;
    }

    struct Reference {
        address target;
        bytes4 sig;
        bytes32 key;
        Permission permission;
    }
}
