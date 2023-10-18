pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "./utils/Setup.sol";

import {StrategyAprOracle} from "../periphery/StrategyAprOracle.sol";
import {DullahanPodManager} from "src/interfaces/IPodManager.sol";
import "./utils/VaultSetup.sol";
import {console2} from "forge-std/console2.sol";


contract FlashLoanTest is VaultSetup {
    address alice = makeAddr("alice");

    function test_leverage() public {
        // Deposit into strategy
        mintAndDepositIntoStrategy(IStrategyInterface(address(strategy)), alice, 100e18);
    }

    function test_deleverage() public{
        // Deposit into strategy
        uint256 amount = 100e18;
        uint256 DAIBalanceBefore = ERC20(DAI).balanceOf(address(this));
        console2.log("DAIBalanceBefore %e", DAIBalanceBefore);

        mintAndDepositIntoStrategy(IStrategyInterface(address(strategy)), alice, amount);
        uint256 DAIBalanceAfterMint = ERC20(DAI).balanceOf(address(this));
        console2.log("DAIBalanceAfterMint %e", DAIBalanceAfterMint);
        //_freeFunds(amount);
        //IStrategyInterface(address(strategy)).redeem(10, address(this), address(this));
        //IStrategyInterface(address(strategy)).freeFunds(amount);
        uint256 received = IStrategyInterface(address(strategy)).redeem(amount, address(this), address(this));


        uint256 DAIBalanceReedemed = ERC20(DAI).balanceOf(address(this));

        console2.log("redeemed %e", DAIBalanceReedemed);
    }
}