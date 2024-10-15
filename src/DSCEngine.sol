// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18 ;

/**
 * @title DSCEngine
 * @author Bowtied HarpyEagle
 * The system is designed to be as minimal as possible, and have the tokens maintain
 * a 1 token = 1 USD peg. 
 * 
 * The stablecoin has the properties: 
 * -Exogenous Collateral
 * -Dollar Pegged
 * -Algorithmically Stable 
 * It is similar to DAI if DAI had no governence, no fees, and was only backed by WETH and WBTC
 * 
 * Our DSC system should always be overcollateralized. At no point, should the value of all collateral be less than the USD value of all the DSC. 
 * 
 * @notice This contract is the core of the DSC system. It handles all the logid of mining and redeeming DSC as well as depositing and withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system. 
 */

contract DSCEngine {

    function depositCollateralAndMintDSC() external {}

    function depositCollateral() external{}

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function mintDSC() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

}