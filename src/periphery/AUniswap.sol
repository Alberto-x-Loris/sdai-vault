// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Errors} from "./Errors.sol";
import {ISwapRouter} from "./uniswap/ISwapRouter.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {EtherUtils} from "./EtherUtils.sol";
import {console2} from "forge-std/console2.sol";


/// @title AUniswap
/// @author centonze.eth
/// @notice Utility functions related to Uniswap operations.
abstract contract AUniswap is EtherUtils {
    using SafeTransferLib for ERC20;

    // The uniswap pool fee for each token.
    mapping(address => uint24) public uniswapFees;
    // Address of Uniswap V3 router
    ISwapRouter public swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice Emitted when the Uniswap router address is updated.
    /// @param newRouter The address of the new router.
    event SetUniswapRouter(address newRouter);

    /// @notice Emitted when the Uniswap fee for a token is updated.
    /// @param token The token whose fee has been updated.
    /// @param fee The new fee value.
    event SetUniswapFee(address indexed token, uint24 fee);

    /// @notice Sets a new address for the Uniswap router.
    /// @param _swapRouter The address of the new router.
    function setUniswapRouter(address _swapRouter) external onlyOwner {
        if (_swapRouter == address(0)) revert Errors.ZeroAddress();
        swapRouter = ISwapRouter(_swapRouter);

        emit SetUniswapRouter(_swapRouter);
    }

    /// @dev Internal function to set Uniswap fee for a token.
    /// @param token The token for which to set the fee.
    /// @param fee The fee to be set.
    function _setUniswapFee(address token, uint24 fee) internal {
        uniswapFees[token] = fee;

        emit SetUniswapFee(token, fee);
    }

    /// @dev Resets allowance for the Uniswap router for a specific token.
    /// @param token The token for which to reset the allowance.
    function _resetUniswapAllowance(address token) internal {
        ERC20(token).safeApprove(address(swapRouter), type(uint256).max);
    }

    /// @dev Removes allowance for the Uniswap router for a specific token.
    /// @param token The token for which to remove the allowance.
    function _removeUniswapAllowance(address token) internal {
        ERC20(token).safeApprove(address(swapRouter), 0);
    }

    /// @dev Converts a given amount of a token into DAI using Uniswap.
    /// @param token The token to be converted.
    /// @param amountIn The amount of token to be swapped.
    /// @param minAmountOut The minimum amount of DAI expected in return.
    /// @return amountOut The amount of DAI received from the swap.
    function _swapToDAI(address token, uint256 amountIn, uint256 minAmountOut) internal returns (uint256 amountOut) {
        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        uint24 fee1 = 100;
        uint24 fee2 = 500;
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: abi.encodePacked(DAI, fee1, USDC, fee2, GHO),
            recipient: address(this), // Receiver of the swapped tokens
            deadline: block.timestamp, // Swap has to be terminated at block time
            amountOut: minAmountOut, // The exact amount to swap
            amountInMaximum: amountIn // Quote is given by frontend to ensure slippage is minimised
        });

        amountOut = swapRouter.exactOutput(params);
    }
}