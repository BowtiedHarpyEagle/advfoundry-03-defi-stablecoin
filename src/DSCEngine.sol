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

pragma solidity ^0.8.18;
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";

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
    /// Errors ///
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();
    error DSCEngine__NotAllowedToken();

    /// State Variables ///

    mapping(address token => address pricefeed) s_priceFeeds; // tokenToPriceFeed

    DecentralizedStableCoin private immutable i_dsc; // DSC instance

    /// Modifiers ///

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    /// Functions ///

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress // the DSC contract address
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();
        }
        // Here we set up the mapping of tokenAddresses to priceFeedAddresses
        // For example BTC/USD or ETH/USD etc

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /// External Functions ///

    function depositCollateralAndMintDSC() external {}

    /**
     *
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
    {}

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function mintDSC() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
