// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscengine;
    DecentralizedStableCoin dsc;
    HelperConfig config;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");

    uint256 public constant AMOUNT_COLLATERAL = 10e18;
    uint256 public constant STARTING_ERC20_BALANCE = 10e18;

    uint256 amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;
    address public user = address(1);

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscengine, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
    }

    /// Constructor Tests ///

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokensLengthDoesNotMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeTheSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /// Price Tests ///

    function testGetTokenAmountFromUsdValue() public view {
        // test the simple math, 2400 usd * 10 eth = 24000 eth
        uint256 usdAmount = 24000e18;
        uint256 expectedWeth = 10e18;

        uint256 actualWeth = dscengine.getTokenAmountFromUsdValue(weth, usdAmount);
        assertEq(actualWeth, expectedWeth);
    }

    function testGetUSDValue() public view {
        // test the simple math, 10 eth * 2400 usd = 24000 usd
        uint256 ethAmount = 10e18;
        uint256 expectedUsdValue = 24000e18;

        uint256 actualUsdValue = dscengine.getUSDValue(weth, ethAmount);
        assertEq(actualUsdValue, expectedUsdValue);
    }

    /// Deposit Collateral Tests ///

    function testRevertsIfMintedDscBreaksHealthFactor() public {
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        amountToMint =
            (amountCollateral * (uint256(price) * dscengine.getAdditionalFeedPrecision())) / dscengine.getPrecision();
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscengine), amountCollateral);

        uint256 expectedHealthFactor =
            dscengine.calculateHealthFactor(amountToMint, dscengine.getUsdValue(weth, amountCollateral));

        console.log("User address:", user);
        console.log("User WETH balance:", ERC20Mock(weth).balanceOf(user));
        console.log("Amount collateral:", amountCollateral);
        console.log("Amount to mint:", amountToMint);
        console.log("Expected health factor:", expectedHealthFactor);

        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__HealthFactorTooLow.selector, expectedHealthFactor));
        dscengine.depositCollateralAndMintDSC(weth, amountCollateral, amountToMint);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("ranToken", "RAN", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscengine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscengine), AMOUNT_COLLATERAL);
        dscengine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUSD) = dscengine.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dscengine.getTokenAmountFromUsdValue(weth, collateralValueInUSD);

        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscengine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscengine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}
