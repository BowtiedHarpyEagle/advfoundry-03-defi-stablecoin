// SPDX-License-Identifier: MIT

// Have our invariants aka properties

// What are our invariants?

// 1. Total supply of DSC must be less than the total value of all collateral in USD

// 2. Getter-view functions should never revert

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract InvariantsTest {}
