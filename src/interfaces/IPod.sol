pragma solidity ^0.8.10;

interface IPod {

    function depositCollateral(uint256 amount) external;
    function mintGho(uint256 amountToMint, address receiver) external returns (uint256 mintedAmount);
}