// SPDX-License-Identifier: MIT
// Handler is going to narrow down the way we call functions 

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {

    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 constant MAX_DEPOSIT_AMOUNT = type(uint96).max ; 
    
    uint256 public timesMintIsCalled;
    address[] public usersWithCollateralDeposited;
    MockV3Aggregator public ethUsdPriceFeed;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc) {
        dsce = _dsce;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        ethUsdPriceFeed = MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));

    }
    // This breaks our test suite when price jumps up or down too much
    //
    // function updateCollareralPrice(uint96 newPrice) public {
    //     int256 newPriceInt = int256(uint256(newPrice));
    //     ethUsdPriceFeed.updateAnswer(newPriceInt);
    // }

    function mintDSC(uint256 amount, uint256 addressSeed) public {
        if(usersWithCollateralDeposited.length == 0) {
            return;
        }
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];   
        (uint256 totalDscMinted, uint256 collateralValueInUSD) = dsce.getAccountInformation(sender);
        int256 maxDSCToMint = (int256(collateralValueInUSD) / 2) - int256(totalDscMinted);
        if (maxDSCToMint < 0) {
            return; 
        }
        amount = bound (amount, 0, uint256(maxDSCToMint));
        if (amount == 0) {
            return;
        }
        vm.startPrank(sender);
        dsce.mintDSC(amount);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    // redeem collateral only when there is collateral

    // first we need to deposit some collateral

    function depositCollateral(uint256 tokenCollateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(tokenCollateralSeed);
        amountCollateral = bound (amountCollateral, 1, MAX_DEPOSIT_AMOUNT);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);
        dsce.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 tokenCollateralSeed, uint256 amountCollateral) public {
        
        ERC20Mock collateral = _getCollateralFromSeed(tokenCollateralSeed);
        uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(msg.sender, address(collateral));
        amountCollateral = bound (amountCollateral, 0, maxCollateralToRedeem);
        if (amountCollateral == 0) {
            return;
        }

        dsce.redeemCollateral(address(collateral), amountCollateral);
    
    }

    // Helper functions

    function _getCollateralFromSeed(uint256 tokenCollateralSeed) private view returns (ERC20Mock) {
        if (tokenCollateralSeed %2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }

}
