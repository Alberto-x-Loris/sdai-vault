pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "./utils/Setup.sol";

import {StrategyAprOracle} from "../periphery/StrategyAprOracle.sol";
import {DullahanPodManager} from "src/interfaces/IPodManager.sol";
import "./utils/VaultSetup.sol";

contract FlashLoanTest is VaultSetup {

    address alice = makeAddr("alice");

    function test_leverage() public{
        // Deposit into strategy
        mintAndDepositIntoStrategy(IStrategyInterface(address(strategy)), alice, 100e18);
    }
}