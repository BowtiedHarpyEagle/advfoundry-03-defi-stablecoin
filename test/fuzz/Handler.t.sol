// SPDX-License-Identifier: MIT
// Handler is going to narrow down the way we call functions 

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {

    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc) {
        dsce = _dsce;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

    }

    // redeem collateral only when there is collateral

    // first we need to deposit some collateral

    function depositCollateral(uint256 tokenCollateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(tokenCollateralSeed);
        dsce.depositCollateral(address(collateral), amountCollateral);
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
