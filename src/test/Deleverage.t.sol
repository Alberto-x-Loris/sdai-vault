pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "./utils/Setup.sol";

import {StrategyAprOracle} from "../periphery/StrategyAprOracle.sol";
import {DullahanPodManager} from "src/interfaces/IPodManager.sol";
import "./utils/VaultSetup.sol";
import {console2} from "forge-std/console2.sol";


contract FlashLoanTest is VaultSetup {
    address alice = makeAddr("alice");

    function setUp() override public {
        super.setUp();

        // Deposit into strategy
        uint256 amount = 100e18;
        mintAndDepositIntoStrategy(IStrategyInterface(address(strategy)), alice, amount);
    }

    function test_deleverage() public{
        uint256 amount = strategy.balanceOf(alice);

        vm.startPrank(alice);
        uint256 received = IStrategyInterface(address(strategy)).redeem(amount, address(this), alice);
        vm.stopPrank();


        uint256 DAIBalanceReedemed = ERC20(DAI).balanceOf(address(this));

        console2.log("redeemed %e", DAIBalanceReedemed);
    }
}