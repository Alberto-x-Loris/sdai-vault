pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "./utils/Setup.sol";

import {StrategyAprOracle} from "../periphery/StrategyAprOracle.sol";
import {DullahanPodManager} from "src/interfaces/IPodManager.sol";

contract InitTest is Setup {
    address public asDAI = 0x4C612E3B15b96Ff9A6faED838F8d07d479a8dD4c;
    address public podManager = 0xf3dEcC68c4FF828456696287B12e5AC0fa62fE56;

    function setUp() public override {
        super.setUp();
        vm.startPrank(DullahanPodManager(podManager).owner());
        DullahanPodManager(address(podManager)).addCollateral(Strategy(address(strategy)).sDAI(), asDAI);
        vm.stopPrank();
    }

    function test_defaultBehavior() public {
        Strategy(address(strategy)).init();
    }
}
