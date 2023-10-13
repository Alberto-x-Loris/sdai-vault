// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {BaseTokenizedStrategy} from "@tokenized-strategy/BaseTokenizedStrategy.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DullahanPodManager} from "src/interfaces/IPodManager.sol";
import {IFlashLoanRecipient} from "src/interfaces/IFlashLoanRecipient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPod} from "src/interfaces/IPod.sol";
import {SavingsDai} from "src/interfaces/IsDAI.sol";
import {console2} from "forge-std/console2.sol";
import {AUniswap} from "src/periphery/AUniswap.sol";

// Import interfaces for many popular DeFi projects, or add your own!
//import "../interfaces/<protocol>/<Interface>.sol";

/**
 * The `TokenizedStrategy` variable can be used to retrieve the strategies
 * specifc storage data your contract.
 *
 *       i.e. uint256 totalAssets = TokenizedStrategy.totalAssets()
 *
 * This can not be used for write functions. Any TokenizedStrategy
 * variables that need to be udpated post deployement will need to
 * come from an external call from the strategies specific `management`.
 */

// NOTE: To implement permissioned functions you can use the onlyManagement and onlyKeepers modifiers

contract Strategy is BaseTokenizedStrategy, IFlashLoanRecipient, AUniswap {
    using SafeERC20 for ERC20;

    address public sDAI;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
    address public podManager;
    address public pod;
    address public balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    

    enum FlashLoanOperation {LEVERAGE, DELEVERAGE}

    constructor(address _asset, string memory _name, address _sDAI, address _podManager)
        BaseTokenizedStrategy(_asset, _name)
    {
        sDAI = _sDAI;
        podManager = _podManager;
    }

    /*//////////////////////////////////////////////////////////////
                NEEDED TO BE OVERRIDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external{
        (FlashLoanOperation operation) = abi.decode(userData, (FlashLoanOperation));
        if(operation == FlashLoanOperation.LEVERAGE){
            _leverageAfterFlashLoan(amounts[0]);
        }
    }

    function  _leverage(uint256 _amount, uint8 leverageFactor, uint8 maxLTV) internal {
        if(leverageFactor >= 10) revert("Leverage factor must be less than 10");
        //Will deposit leveragedsDaiAmount of DAI in pod as collateral
        console2.log("DAI Balance: ", _amount);

        
        uint256 leveragedDaiAmount = _amount * (100**(leverageFactor+1)- uint256(maxLTV)**(leverageFactor+1))/((100**leverageFactor) * (100-maxLTV));
        console2.log("leveraged DAI Balance: ", leveragedDaiAmount);


        //Will need to borrow leveragedGHOAmount from POD to reimburse flashloan
        uint256 leveragedGHOAmount = _amount * (100**(leverageFactor+1)- uint256(maxLTV)**(leverageFactor+1))/((100**leverageFactor) * (100-maxLTV));

        
        address[] memory daiSingleton = new address[](1);
        daiSingleton[0] = DAI;
        uint256[] memory DAIamountSingleton = new uint256[](1);
        DAIamountSingleton[0] = leveragedDaiAmount;

        bytes memory leverageData = abi.encode(FlashLoanOperation.LEVERAGE);

        IVault(balancerVault).flashLoan(address(this), daiSingleton, DAIamountSingleton, leverageData);
    }

    function _leverageAfterFlashLoan(uint256 amount) internal {
        // gho depeg factor to multiply by amount to reimburse flashloan (= 1 / ghoPrice)
        uint256 ghoDepegFactor = 103;
        //get DAI balance from flashloan
        uint256 DAIBalance = ERC20(DAI).balanceOf(address(this));
        console2.log("DAI Balance: ", DAIBalance);

        ERC20(DAI).approve(sDAI, DAIBalance);
        uint256 sDAIBalance = SavingsDai(sDAI).deposit(DAIBalance, address(this));

        ERC20(sDAI).approve(pod, sDAIBalance);

        //deposit sDAI in pod as collateral
        IPod(pod).depositCollateral(sDAIBalance);

        //Borrow GHO from pod
        uint256 mintedGho = IPod(pod).mintGho((amount * ghoDepegFactor)/100 , address(this));

        //swap GHO for DAI
        uint256 daiReceived = _swapToGho(GHO, mintedGho, amount);

        //return flashloan
        ERC20(DAI).approve(balancerVault, daiReceived);
        ERC20(DAI).transfer(balancerVault, daiReceived);

        
    }

    
    /**
     * @dev Should deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permsionless and thus can be sandwhiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should attemppt
     * to deposit in the yield source.
     */
    function _deployFunds(uint256 _amount) internal override {
        _leverage(_amount, 9, 77);
        

    }

    function init() external {
        pod = DullahanPodManager(podManager).createPod(sDAI);
    }

    /**
     * @dev Will attempt to free the '_amount' of 'asset'.
     *
     * The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called during {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permsionless and thus can be sandwhiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting puroposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal override {
        // TODO: implement withdraw logic EX:
        //
        //      lendingPool.withdraw(asset, _amount);
    }

    /**
     * @dev Internal function to harvest all rewards, redeploy any idle
     * funds and return an accurate accounting of all funds currently
     * held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * redepositing etc. to get the most accurate view of current assets.
     *
     * NOTE: All applicable assets including loose assets should be
     * accounted for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `TokenizedStrategy.isShutdown()` to decide if funds should be
     * redeployed or simply realize any profits/losses.
     *
     * @return _totalAssets A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds including idle funds.
     */
    function _harvestAndReport() internal override returns (uint256 _totalAssets) {
        // TODO: Implement harvesting logic and accurate accounting EX:
        //
        //      _claminAndSellRewards();
        //      _totalAssets = aToken.balanceof(address(this)) + ERC20(asset).balanceOf(address(this));
        _totalAssets = ERC20(asset).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Optional function for strategist to override that can
     *  be called in between reports.
     *
     * If '_tend' is used tendTrigger() will also need to be overridden.
     *
     * This call can only be called by a persionned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed poisition maintence or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwhiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * The TokenizedStrategy contract will do all needed debt and idle updates
     * after this has finished and will have no effect on PPS of the strategy
     * till report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to deploy.
     *
     * function _tend(uint256 _totalIdle) internal override {}
     */

    /**
     * @notice Returns wether or not tend() should be called by a keeper.
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     *
     * function tendTrigger() public view override returns (bool) {}
     */

    /**
     * @notice Gets the max amount of `asset` that an adress can deposit.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any deposit or mints to enforce
     * any limits desired by the strategist. This can be used for either a
     * traditional deposit limit or for implementing a whitelist etc.
     *
     *   EX:
     *      if(isAllowed[_owner]) return super.availableDepositLimit(_owner);
     *
     * This does not need to take into account any conversion rates
     * from shares to assets. But should know that any non max uint256
     * amounts may be converted to shares. So it is recommended to keep
     * custom amounts low enough as not to cause overflow when multiplied
     * by `totalSupply`.
     *
     * @param . The address that is depositing into the strategy.
     * @return . The avialable amount the `_owner` can deposit in terms of `asset`
     *
     * function availableDepositLimit(
     *     address _owner
     * ) public view override returns (uint256) {
     *     TODO: If desired Implement deposit limit logic and any needed state variables .
     *     
     *     EX:    
     *         uint256 totalAssets = TokenizedStrategy.totalAssets();
     *         return totalAssets >= depositLimit ? 0 : depositLimit - totalAssets;
     * }
     */

    /**
     * @notice Gets the max amount of `asset` that can be withdrawn.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any withdraw or redeem to enforce
     * any limits desired by the strategist. This can be used for illiquid
     * or sandwhichable strategies. It should never be lower than `totalIdle`.
     *
     *   EX:
     *       return TokenIzedStrategy.totalIdle();
     *
     * This does not need to take into account the `_owner`'s share balance
     * or conversion rates from shares to assets.
     *
     * @param . The address that is withdrawing from the strategy.
     * @return . The avialable amount that can be withdrawn in terms of `asset`
     *
     * function availableWithdrawLimit(
     *     address _owner
     * ) public view override returns (uint256) {
     *     TODO: If desired Implement withdraw limit logic and any needed state variables.
     *     
     *     EX:    
     *         return TokenizedStrategy.totalIdle();
     * }
     */

    /**
     * @dev Optional function for a strategist to override that will
     * allow management to manually withdraw deployed funds from the
     * yield source if a strategy is shutdown.
     *
     * This should attempt to free `_amount`, noting that `_amount` may
     * be more than is currently deployed.
     *
     * NOTE: This will not realize any profits or losses. A seperate
     * {report} will be needed in order to record any profit/loss. If
     * a report may need to be called after a shutdown it is important
     * to check if the strategy is shutdown during {_harvestAndReport}
     * so that it does not simply re-deploy all funds that had been freed.
     *
     * EX:
     *   if(freeAsset > 0 && !TokenizedStrategy.isShutdown()) {
     *       depositFunds...
     *    }
     *
     * @param _amount The amount of asset to attempt to free.
     *
     * function _emergencyWithdraw(uint256 _amount) internal override {
     *     TODO: If desired implement simple logic to free deployed funds.
     * 
     *     EX:
     *         _amount = min(_amount, atoken.balanceOf(address(this)));
     *         lendingPool.withdraw(asset, _amount);
     * }
     */
}
