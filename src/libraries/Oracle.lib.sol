// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
 * @title OracleLib
 * @author Bowtied HarpyEagle - Based on Updraft Course
 * @notice This library is used to check Chainlink Oracle for state data
 * If a price is stale, the function will revert and render the DSCEngine inoperable
 * this is by design. 
 * 
 * We want DSCEngine to freeze if prices are stale
 * 
 * So if the chainling oracle network goes down, money can be locked in the protocol
 * This is a known issue with Chainlink.
 */

library OracleLib {}