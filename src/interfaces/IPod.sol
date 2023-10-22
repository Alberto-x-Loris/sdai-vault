pragma solidity ^0.8.10;

interface IPod {
    function depositCollateral(uint256 amount) external;
    function mintGho(uint256 amountToMint, address receiver) external returns (uint256 mintedAmount);
    function repayGho(uint256 amountToRepay) external returns (bool);
    function repayGhoAndWithdrawCollateral(uint256 repayAmount, uint256 withdrawAmount, address receiver)
        external
        returns (bool);

    function withdrawCollateral(uint256 amount, address receiver) external;
    function podCollateralBalance() external view returns (uint256);
    function podDebtBalance() external view returns (uint256);
}
