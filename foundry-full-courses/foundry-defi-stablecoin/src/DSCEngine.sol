// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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
    error DSCEngine__BreakHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    /////////////////////
    // State Variables //
    /////////////////////
    uint256 private constant ADDTIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10; // this means a 10% bonus

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
    event CollateralRedeemed(
        address indexed redeemedFrom,
        address indexed redeemedTo,
        address indexed tokenAddress,
        uint256 amount
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

    /**
     * @param tokenCollateralAddress 抵押物的 token 地址
     * @param amountCollateral 抵押物的数量
     * @param amountDscToMint 要铸造的 DSC 的数量
     * @notice this function will deposit your collateral and mint DSC in one transaction
     */
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

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
        public
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

    /**
     * @param tokenCollateralAddress 要赎回的 token 地址
     * @param amountCollateral 要赎回的 token 的数量
     * @param amountDscToBurn 要销毁的 DSC 的数量
     * @notice This function burns DSC and redeems underlying collateral in one transaction.
     */
    function redeemCollateralForDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToBurn
    ) external {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        // redeemCollateral already checks health factor
    }

    // health factor must be over 1 after collateral pulled
    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) public moreThanZero(amountCollateral) nonReentrant {
        _redeemCollateral(
            tokenCollateralAddress,
            amountCollateral,
            msg.sender,
            msg.sender
        );
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function mintDsc(
        uint256 amountDscToMint
    ) public moreThanZero(amountDscToMint) nonReentrant {
        // check if the collateral value > DSC amount
        s_DscMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) nonReentrant {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     *
     * @param collateral The erc20 collateral address to liquidate from the user.
     * @param user user The user who has broken the health factor. Their _healthFactor should be below MIN_HEALTH_FACTOR.
     * @param debtToCover The amount of DSC you can burn to improve the users health factor
     * @notice You can partially liquidate a user. You will get a liquidation bonus for taking the users finds
     */
    function liquidate(
        address collateral,
        address user,
        uint256 debtToCover
    ) external moreThanZero(debtToCover) nonReentrant {
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }

        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(
            collateral,
            debtToCover
        );
        // 给予清算者奖励 0.05 * 0.1 = 0.005, 会获得 0.055 的 ETH 奖励
        uint256 bonusCollateral = (tokenAmountFromDebtCovered *
            LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered +
            bonusCollateral;
        _redeemCollateral(
            collateral,
            totalCollateralToRedeem,
            user,
            msg.sender
        );
        // need to burn the DSC
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getHealthFactor() external view {}

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

    function getTokenAmountFromUsd(
        address token,
        uint256 usdAmountInWei
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeeds[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // TODO: (, int256 price, , , ) = priceFeed.staleCheckLatestRoundData();

        return ((usdAmountInWei * PRECISION) /
            (uint256(price) * ADDTIONAL_FEED_PRECISION));
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
    function _healthFactor(address user) private view returns (uint256) {
        // total Dsc minted
        // total collateral value
        // 获取抵押物和所发行的 Dsc 的比值，来衡量抵押物的价值
        // Dsc 是稳定币，波动不大，所以这里就需要检测抵押物在市场上的价值变化
        (
            uint256 totalDscMinted,
            uint256 collateralValueInUsd
        ) = _getAccountInfomation(user);

        uint256 collateralAdjustedForThreshold = (collateralValueInUsd *
            LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        // 这里设定一个比值，从而判定抵押物是否还能够被抵押
        // 比如 (CollateralValue / Dsc) = (150 / 100)
        // 也就是至少需要 150 的抵押物才可以获取到 100 的 Dsc

        // $1000 ETH and 100 DSC
        // 1000 * 50 = 50000 / 100 = 500% = 5
        // 所以如果账户抵押了价值 $1000 的 ETH，并且其获取了价值 100 的 DSC
        // 那么该账户的健康因子就是 5
        // 如果健康因子小于 1，则需要清算抵押物，也就是没收抵押物

        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // Check health factor (Do they have enought collateral)
        // revert if they don't
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreakHealthFactor(userHealthFactor);
        }
    }

    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address from,
        address to
    ) private {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;

        emit CollateralRedeemed(
            from,
            to,
            tokenCollateralAddress,
            amountCollateral
        );

        bool success = IERC20(tokenCollateralAddress).transfer(
            to,
            amountCollateral
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function _burnDsc(
        uint256 amountDscToBurn,
        address onBehalfOf,
        address dscFrom
    ) private {
        s_DscMinted[onBehalfOf] -= amountDscToBurn;
        // 这里可以选择直接转入到 address(0)，但是 DSC 合约继承了 ERC20Burnable
        // 它拥有自己销毁代币的能力，所以这里是将其转入合约中，再由合约进行销毁操作
        bool success = i_dsc.transferFrom(
            dscFrom,
            address(this),
            amountDscToBurn
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        // 就是这里，由代笔合约进行销毁操作
        i_dsc.burn(amountDscToBurn);
    }
}
