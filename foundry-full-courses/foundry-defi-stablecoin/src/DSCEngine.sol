// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
 * @title DSCEngine
 * @author NextEcho
 *
 * The System is designed to be as minimal as possible, and have
 * the tokens maintain a 1 token == $1 peg.
 * This stablecoin has the properties
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral <= the $ backend value of all the DSC.
 *
 * @notice This contract is the core of the DSC System, It handles all the logic for mining
 * and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.
 */
contract DSCEngine is ReentrancyGuard {
    ////////////////
    // Errors //////
    ////////////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();

    /////////////////////
    // State Variables //
    /////////////////////
    uint256 private constant ADDTIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = i00;

    mapping(address token => address priceFeed) private s_priceFeeds; // 映射货币对应的 priceFeed 地址
    mapping(address user => mapping(address token => uint256 amount)) // 映射用户所存储的货币以及货币数量
        private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) s_DscMinted; // 映射用户所获取到的 Usc 的数量
    address[] private s_collateralTokens; // 存储每个用户所兑换过的货币类型，作为一个数组来与用户一一对应

    DecentralizedStableCoin private immutable i_dsc;

    ////////////////
    // Events //////
    ////////////////
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

    ////////////////
    // Modifiers ///
    ////////////////
    /**
     * moreThanZero 确保转入的数量大于 0
     */
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

    ////////////////
    // Functions ///
    ////////////////
    /**
     * @param tokenAddresses 该合约所允许抵押的货币
     * @param priceFeedAddresses 该合约所对应的可抵押货币的对应 priceFeed 地址
     * @param dscAddress 该合约部署后获取 Usc 货币的地址
     */
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /////////////////////////
    // External Functions ///
    /////////////////////////
    function depositCollateralAndMintDsc() external {}

    /**
     * depositCollateral
     * 往系统中存入押金，也就是抵押品
     * @param tokenCollateralAddress 抵押品的来源地址
     * @param amountCollateral 抵押品的数量
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;
        emit CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc(
        uint256 amountDscToMint
    ) external moreThanZero(amountDscToMint) nonReentrant {
        // check if the collateral value > DSC amount
        s_DscMinted[msg.sender] += amountDscToMint;
        _revertIfHealthRefactorIsBroken(msg.sender);
    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    ///////////////////////////////////
    // Public & External Functions ////
    ///////////////////////////////////
    function getAccountCollateralValue(
        address user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
    }

    // price 为抵押物所对应的 USD 的价值
    // 然后乘以 ADDTIONAL_FEED_PRECISION, 该值可以文档查询，为 1e8
    // 最后乘以抵押的货币数量，也就是 amount
    // 此时获取到了最终的价值，但是单位仍然很大，所以最后要除以 1e18, 将单位换算成 Usd
    function getUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeeds[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // If 1 ETH = $1000
        // According to offical docs, returned value from CL will be 1000 * 1e8
        return
            ((uint256(price) * ADDTIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    ///////////////////////////////////
    // Private & Internal Functions ///
    ///////////////////////////////////

    function _getAccountInfomation(
        address user
    )
        private
        view
        returns (uint256 totalUscMinted, uint256 collateralValueInUsd)
    {
        totalUscMinted = s_DscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /**
     * Return how close to liquidate a user is
     * If a user goes below, then they can get liquidation
     * @param user User who send collateral
     */
    function _healthRefactor(address user) private view returns (uint256) {
        // total Usc minted
        // total collateral value
        (
            uint256 totalUscMinted,
            uint256 collateralValueInUsd
        ) = _getAccountInfomation(user);

        uint256 collateralAdjusted = (collateralValueInUsd *
            LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
    }

    function _revertIfHealthRefactorIsBroken(address user) internal view {
        // Check health refactor (Do they have enought collateral)
        // revert if they don't
    }
}
