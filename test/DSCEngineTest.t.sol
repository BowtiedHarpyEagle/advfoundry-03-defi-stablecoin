// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscengine;
    DecentralizedStableCoin dsc;
    HelperConfig config;

    address ethUsdPriceFeed;
    address weth;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscengine, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();
    }

    /// Price Tests ///

    function testGetUSDValue() public view {
        // test the simple math, 10 eth * 2400 usd = 24000 usd
        uint256 ethAmount = 10e18;
        uint256 expectedUsdValue = 24000e18;

        uint256 actualUsdValue = dscengine.getUSDValue(weth, ethAmount);
        assertEq(actualUsdValue, expectedUsdValue);
    }
}
