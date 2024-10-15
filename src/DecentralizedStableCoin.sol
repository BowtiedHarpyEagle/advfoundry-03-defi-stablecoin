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

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title DecentralizedStableCoin
 * @author Bowtied HarpyEagle 
 * Collateral: Exogenous (wETH and wBTC)
 * Minting: Algorithmic
 * Relative stability: Pegged to USD
 * 
 * This contract is meant to be governed by DSCEngine. This contract is just the 
 */

contract DecentralizedStableCoin  {
    constructor() {
        
    }
}