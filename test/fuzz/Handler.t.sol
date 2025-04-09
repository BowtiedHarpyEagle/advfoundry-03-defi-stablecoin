// SPDX-License-Identifier: MIT
// Handler is going to narrow down the way we call functions 

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract Handler is Test {

    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc) {
        dsce = _dsce;
        dsc = _dsc;

    }

    // redeem collateral only when there is collateral

    // first we need to deposit some collateral

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) public {
        dsce.depositCollateral(tokenCollateralAddress, amountCollateral);
    }

}
