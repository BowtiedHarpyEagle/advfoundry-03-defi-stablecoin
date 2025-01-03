pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/DSCEngine.sol";
import "../src/DecentralizedStableCoin.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DSCEngine dscengine;
    DecentralizedStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;
    address USER = address(1);
    uint256 AMOUNT_COLLATERAL = 10 ether;
    uint256 AMOUNT_DSC_TO_MINT = 5 ether;

    function setUp() public {
        weth = new ERC20Mock("Wrapped Ether", "WETH", USER, 100 ether);
        wbtc = new ERC20Mock("Wrapped Bitcoin", "WBTC", USER, 100 ether);
        dsc = new DecentralizedStableCoin();
        address[] memory tokenAddresses = new address[](2);
        address[] memory priceFeedAddresses = new address[](2);
        tokenAddresses[0] = address(weth);
        tokenAddresses[1] = address(wbtc);
        priceFeedAddresses[0] = address(0x123); // Mock price feed address
        priceFeedAddresses[1] = address(0x456); // Mock price feed address
        dscengine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    function testDepositCollateral() public {
        vm.startPrank(USER);
        weth.approve(address(dscengine), AMOUNT_COLLATERAL);
        dscengine.depositCollateral(address(weth), AMOUNT_COLLATERAL);
        (uint256 totalDscMinted, uint256 collateralValueInUSD) = dscengine.getAccountInformation(USER);
        assertEq(totalDscMinted, 0);
        assertEq(collateralValueInUSD, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testMintDSC() public {
        vm.startPrank(USER);
        weth.approve(address(dscengine), AMOUNT_COLLATERAL);
        dscengine.depositCollateral(address(weth), AMOUNT_COLLATERAL);
        dscengine.mintDSC(AMOUNT_DSC_TO_MINT);
        (uint256 totalDscMinted, uint256 collateralValueInUSD) = dscengine.getAccountInformation(USER);
        assertEq(totalDscMinted, AMOUNT_DSC_TO_MINT);
        assertEq(collateralValueInUSD, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testRedeemCollateral() public {
        vm.startPrank(USER);
        weth.approve(address(dscengine), AMOUNT_COLLATERAL);
        dscengine.depositCollateral(address(weth), AMOUNT_COLLATERAL);
        dscengine.mintDSC(AMOUNT_DSC_TO_MINT);
        dscengine.redeemCollateral(address(weth), AMOUNT_COLLATERAL / 2);
        (uint256 totalDscMinted, uint256 collateralValueInUSD) = dscengine.getAccountInformation(USER);
        assertEq(totalDscMinted, AMOUNT_DSC_TO_MINT);
        assertEq(collateralValueInUSD, AMOUNT_COLLATERAL / 2);
        vm.stopPrank();
    }

    function testHealthFactor() public {
        vm.startPrank(USER);
        weth.approve(address(dscengine), AMOUNT_COLLATERAL);
        dscengine.depositCollateral(address(weth), AMOUNT_COLLATERAL);
        dscengine.mintDSC(AMOUNT_DSC_TO_MINT);
        uint256 healthFactor = dscengine.getHealthFactor(USER);
        assert(healthFactor >= 1);
        vm.stopPrank();
    }

    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(USER);
        weth.approve(address(dscengine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscengine.depositCollateral(address(weth), 0);
        vm.stopPrank();
    }

    function testRevertsIfMintAmountIsZero() public {
        vm.startPrank(USER);
        weth.approve(address(dscengine), AMOUNT_COLLATERAL);
        dscengine.depositCollateral(address(weth), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscengine.mintDSC(0);
        vm.stopPrank();
    }

    function testRevertsIfNotAllowedToken() public {
        ERC20Mock fakeToken = new ERC20Mock("Fake Token", "FAKE", USER, 100 ether);
        vm.startPrank(USER);
        fakeToken.approve(address(dscengine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscengine.depositCollateral(address(fakeToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }
}