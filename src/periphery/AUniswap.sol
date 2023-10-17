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

    function _swapToDAI(uint256 amountIn) internal {
        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        // uint24 fee1 = 100;
        // uint24 fee2 = 500;
        // ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
        //     path: abi.encodePacked(DAI, fee1, USDC, fee2, GHO),
        //     recipient: address(this), // Receiver of the swapped tokens
        //     deadline: block.timestamp, // Swap has to be terminated at block time
        //     amountOut: amountOut, // The exact amount to swap // TODO handle slippage
        //     amountInMaximum: 0 // Quote is given by frontend to ensure slippage is minimised
        // });

        // swapRouter.exactOutput(params);

        ISwapRouter.ExactInputSingleParams memory params1 = ISwapRouter.ExactInputSingleParams({
            tokenIn: GHO, // The input token address
            tokenOut: USDC, // The token received should be Wrapped Ether
            fee: 500, // The fee tier of the pool
            recipient: address(this), // Receiver of the swapped tokens
            deadline: block.timestamp, // Swap has to be terminated at block time
            amountIn: amountIn, // The exact amount to swap
            amountOutMinimum: 0, // Quote is given by frontend to ensure slippage is minimised
            sqrtPriceLimitX96: 0 // Ensure we swap our exact input amount.
        });

        uint256 usdcAmountOut = swapRouter.exactInputSingle(params1);
    
        console2.log("Swap from GHO to USDC succeeded, got %e USDC", usdcAmountOut);

        ISwapRouter.ExactInputSingleParams memory params2 = ISwapRouter.ExactInputSingleParams({
            tokenIn: USDC, // The input token address
            tokenOut: DAI, // The token received should be Wrapped Ether
            fee: 100, // The fee tier of the pool
            recipient: address(this), // Receiver of the swapped tokens
            deadline: block.timestamp, // Swap has to be terminated at block time
            amountIn: amountIn, // The exact amount to swap
            amountOutMinimum: 0, // Quote is given by frontend to ensure slippage is minimised
            sqrtPriceLimitX96: 0 // Ensure we swap our exact input amount.
        });

        uint256 daiFinalAmount = swapRouter.exactInputSingle(params1);

        console2.log("Swap from USDC to DAI succeeded, got %e DAI", daiFinalAmount);
    }
}