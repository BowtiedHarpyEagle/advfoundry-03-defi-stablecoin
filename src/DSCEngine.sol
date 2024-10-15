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
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
contract DSCEngine is ReentrancyGuard {
    /// Errors ///
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__HealthFactorTooLow(uint256 healthFactor);
    error DSCEngine__MintFailed();

    /// State Variables ///
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    // This means for $100 USD as collateral one can mint $50 DSC
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address pricefeed) s_priceFeeds; // tokenToPriceFeed
    // user address to token to amount, tracking the user's deposit of collateral
    mapping(address user => mapping(address token => uint256)) private s_collateralDeposited;
    mapping(address user => uint256 dscAmountMinted) private s_dscMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc; // DSC instance

    /// Events ///

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

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
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /// External Functions ///

    function depositCollateralAndMintDSC() external {}

    /**
     * @notice follows CEI pattern
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);

        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}
    /**
     * @notice follows CEI pattern
     * @param amountToMint The amount of DSC to mint
     * @notice The amountToMint must be greater than 0
     * and the user must have enough collateral to mint
     */

    function mintDSC(uint256 amountToMint) external moreThanZero(amountToMint) nonReentrant {
        s_dscMinted[msg.sender] += amountToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    /// Private And Internal View Functions ///

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUSD)
    {
        totalDscMinted = s_dscMinted[user];
        collateralValueInUSD = getTotalCollateralValueInUSD(user);
    }

    /**
     *
     * @param user The address of the user
     * @return The health factor of the user, or how close they are to liquidation
     * If the factor is less than 1 then they can be liquidated
     */
    function _healthFactor(address user) private view returns (uint256) {
        // we need total dsc minted by user
        // and we need total collateral value in USD by user
        (uint256 totalDscMinted, uint256 totalCollateralValueInUSD) = _getAccountInformation(user);

        uint256 collateralAdjustedForTreshold =
            totalCollateralValueInUSD * LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISION;

        return (collateralAdjustedForTreshold * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) private view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorTooLow(userHealthFactor);
        }
    }

    /// Public and External View Functions ///

    function getTotalCollateralValueInUSD(address user) public view returns (uint256 totalCollateralValueInUSD) {
        //we need to loop through each collateral token, and get the price
        //from the price feed to calculate the total collateral value in USD
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUSD += getUSDValue(token, amount);
        }
        return totalCollateralValueInUSD;
    }

    function getUSDValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData(); // get latest price, ignore other data

        return ((uint256(price) * ADDITIONAL_FEED_PRECISION * amount) / PRECISION);
    }
}
