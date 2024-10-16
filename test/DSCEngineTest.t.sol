// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscengine;
    DecentralizedStableCoin dsc;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscengine) = deployer.run();
    }
}