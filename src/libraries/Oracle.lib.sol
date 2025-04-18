// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


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

library OracleLib {

    error OracleLib__PriceIsStale();

    uint256 private constant TIMEOUT = 3 hours; // 3 hours in seconds = 10800 seconds
    
    function  staleCheckLatestRoundData(AggregatorV3Interface priceFeed) 
    public view  
    returns (uint80, int256, uint256, uint256, uint80) {

        (uint80 roundId, int256 answer, uint256 startedAt, 
        uint256 updatedAt, uint80 answeredInRound) = 
        priceFeed.latestRoundData();

        uint256 secondsSinceUpdate = block.timestamp - updatedAt;
        if (secondsSinceUpdate > TIMEOUT) {
            revert OracleLib__PriceIsStale();
        }

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
        
    }
}