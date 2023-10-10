pragma solidity ^0.8.10;

interface DullahanPodManager {
    event CollateralUpdated(address indexed collateral, bool allowed);
    event DiscountCalculatorUpdated(address indexed oldCalculator, address indexed newCalculator);
    event ExtraLiquidationRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event FeeChestUpdated(address indexed oldFeeChest, address indexed newFeeChest);
    event FeeModuleUpdated(address indexed oldMoldule, address indexed newModule);
    event FreedStkAave(address indexed pod, uint256 pullAmount);
    event LiquidatedPod(
        address indexed pod, address indexed collateral, uint256 collateralAmount, uint256 receivedFeeAmount
    );
    event MintFeeRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event MintingFees(address indexed pod, uint256 feeAmount);
    event NewCollateral(address indexed collateral, address indexed aToken);
    event NewPendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);
    event OracleModuleUpdated(address indexed oldMoldule, address indexed newModule);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PaidFees(address indexed pod, uint256 feeAmount);
    event Paused(address account);
    event PodCreation(address indexed collateral, address indexed podOwner, address indexed pod);
    event ProcessThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event ProtocolFeeRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event RegistryUpdated(address indexed oldRegistry, address indexed newRegistry);
    event RentedStkAave(address indexed pod, uint256 rentAmount);
    event ReserveProcessed(uint256 stakingRewardsAmount);
    event Unpaused(address account);

    function MAX_BPS() external view returns (uint256);
    function UNIT() external view returns (uint256);
    function aTokenForCollateral(address) external view returns (address);
    function acceptOwnership() external;
    function addCollateral(address collateral, address aToken) external;
    function allPods(uint256) external view returns (address);
    function allowedCollaterals(address) external view returns (bool);
    function createPod(address collateral) external returns (address);
    function discountCalculator() external view returns (address);
    function estimatePodLiquidationexternal(address pod)
        external
        view
        returns (uint256 feeAmount, uint256 collateralAmount);
    function extraLiquidationRatio() external view returns (uint256);
    function feeModule() external view returns (address);
    function freeStkAave(address pod) external returns (bool);
    function getAllOwnerPods(address account) external view returns (address[] memory);
    function getAllPods() external view returns (address[] memory);
    function getCurrentIndex() external view returns (uint256);
    function getStkAave(uint256 amountToMint) external returns (bool);
    function isPodLiquidable(address pod) external view returns (bool);
    function lastIndexUpdate() external view returns (uint256);
    function lastUpdatedIndex() external view returns (uint256);
    function liquidatePod(address pod) external returns (bool);
    function mintFeeRatio() external view returns (uint256);
    function notifyMintingFee(uint256 feeAmount) external;
    function notifyPayFee(uint256 feeAmount) external;
    function notifyStkAaveClaim(uint256 claimedAmount) external;
    function oracleModule() external view returns (address);
    function owner() external view returns (address);
    function ownerPods(address, uint256) external view returns (address);
    function pause() external;
    function paused() external view returns (bool);
    function pendingOwner() external view returns (address);
    function podCurrentOwedFees(address pod) external view returns (uint256);
    function podImplementation() external view returns (address);
    function podOwedFees(address pod) external view returns (uint256);
    function pods(address)
        external
        view
        returns (
            address podAddress,
            address podOwner,
            address collateral,
            uint96 lastUpdate,
            uint256 lastIndex,
            uint256 rentedAmount,
            uint256 accruedFees
        );
    function processReserve() external returns (bool);
    function processThreshold() external view returns (uint256);
    function protocolFeeChest() external view returns (address);
    function protocolFeeRatio() external view returns (uint256);
    function registry() external view returns (address);
    function renounceOwnership() external;
    function reserveAmount() external view returns (uint256);
    function rewardsStaking() external view returns (address);
    function transferOwnership(address newOwner) external;
    function unpause() external;
    function updateAllPodsRegistry() external;
    function updateCollateral(address collateral, bool allowed) external;
    function updateDiscountCalculator(address newCalculator) external;
    function updateExtraLiquidationRatio(uint256 newRatio) external;
    function updateFeeChest(address newFeeChest) external;
    function updateFeeModule(address newModule) external;
    function updateGlobalState() external returns (bool);
    function updateMintFeeRatio(uint256 newRatio) external;
    function updateMultiplePodsDelegation(address[] memory podList) external;
    function updateMultiplePodsRegistry(address[] memory podList) external;
    function updateOracleModule(address newModule) external;
    function updatePodDelegation(address pod) external;
    function updatePodRegistry(address pod) external;
    function updatePodState(address pod) external returns (bool);
    function updateProcessThreshold(uint256 newThreshold) external;
    function updateProtocolFeeRatio(uint256 newRatio) external;
    function updateRegistry(address newRegistry) external;
    function vault() external view returns (address);
}

