pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "./utils/Setup.sol";

import {StrategyAprOracle} from "../periphery/StrategyAprOracle.sol";

contract InitTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_defaultBehavior() public {
        Strategy(address(strategy)).init();
    }
}
