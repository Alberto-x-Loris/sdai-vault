pragma solidity ^0.8.18;

import "./Setup.sol";
import {DullahanPodManager} from "../../interfaces/IPodManager.sol";

abstract contract VaultSetup is Setup {
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public asDAI = 0x4C612E3B15b96Ff9A6faED838F8d07d479a8dD4c;
    address public podManager = 0xf3dEcC68c4FF828456696287B12e5AC0fa62fE56;
    address public sDAI = 0x6C5B2000f840ABD5Fa24064d5c1ebD3611C9B72e;
    address public pod;
    address public balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(DullahanPodManager(podManager).owner());

        DullahanPodManager(address(podManager)).addCollateral(Strategy(address(strategy)).sDAI(), asDAI);

        vm.stopPrank();
        Strategy(address(strategy)).init();
    }
}
