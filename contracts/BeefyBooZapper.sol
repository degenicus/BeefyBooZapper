pragma solidity >=0.7.0;

import "./interfaces/IWETH.sol";
import "./interfaces/IReaperVault.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IBooMirrorWorld.sol";
import "./libraries/LowGasSafeMath.sol";
import "./libraries/SafeERC20.sol";

contract BeefyBooZapper {
    using LowGasSafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IReaperVault;

    IUniswapV2Router02 public immutable router;
    address public immutable WETH;
    uint256 public constant minimumAmount = 1000;
    address public constant BOO = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address public constant XBOO = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;

    constructor(address _router, address _WETH) {
        router = IUniswapV2Router02(_router);
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function beefInETH(address reaperVault, uint256 tokenAmountOutMin)
        external
        payable
    {
        require(msg.value >= minimumAmount, "Insignificant input amount");

        IWETH(WETH).deposit{value: msg.value}();

        _swapAndStake(reaperVault, tokenAmountOutMin, WETH);
    }

    function beefIn(
        address reaperVault,
        uint256 tokenAmountOutMin,
        address tokenIn,
        uint256 tokenInAmount
    ) external {
        require(tokenInAmount >= minimumAmount, "Insignificant input amount");
        require(
            IERC20(tokenIn).allowance(msg.sender, address(this)) >=
                tokenInAmount,
            "Input token is not approved"
        );

        IERC20(tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            tokenInAmount
        );

        _swapAndStake(reaperVault, tokenAmountOutMin, tokenIn);
    }

    function beefOutAndSwap(
        address reaperVault,
        uint256 withdrawAmount,
        address desiredToken,
        uint256 desiredTokenOutMin
    ) external {
        (IReaperVault vault, address want) = _getVaultWant(reaperVault);
        require(want != desiredToken, "desiredToken cannot be want");
        vault.safeTransferFrom(msg.sender, address(this), withdrawAmount);
        vault.withdraw(withdrawAmount);
        address[] memory path = new address[](2);
        path[0] = want;
        path[1] = desiredToken;

        if (want == BOO && desiredToken == XBOO) {
            uint256 wantBalance = IERC20(BOO).balanceOf(address(this));
            _approveTokenIfNeeded(want, XBOO);
            IBooMirrorWorld(XBOO).enter(wantBalance);
        } else {
            _approveTokenIfNeeded(want, address(router));
            router.swapExactTokensForTokens(
                IERC20(want).balanceOf(address(this)),
                desiredTokenOutMin,
                path,
                address(this),
                block.timestamp
            );
        }

        _returnAssets(path);
    }

    function _getVaultWant(address reaperVault)
        private
        view
        returns (IReaperVault vault, address want)
    {
        vault = IReaperVault(reaperVault);
        want = vault.token();
    }

    function _swapAndStake(
        address reaperVault,
        uint256 tokenAmountOutMin,
        address tokenIn
    ) private {
        (IReaperVault vault, address want) = _getVaultWant(reaperVault);
        uint256 fullInvestment = IERC20(tokenIn).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = want;

        if (want == BOO && tokenIn == XBOO) {
            IBooMirrorWorld(XBOO).leave(fullInvestment);
        } else {
            _approveTokenIfNeeded(tokenIn, address(router));
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                fullInvestment,
                tokenAmountOutMin,
                path,
                address(this),
                block.timestamp
            );
        }
        uint256 wantBalance = IERC20(want).balanceOf(address(this));

        _approveTokenIfNeeded(want, address(vault));
        vault.deposit(wantBalance);

        vault.safeTransfer(msg.sender, vault.balanceOf(address(this)));
        _returnAssets(path);
    }

    function _returnAssets(address[] memory tokens) private {
        uint256 balance;
        for (uint256 i; i < tokens.length; i++) {
            balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                if (tokens[i] == WETH) {
                    IWETH(WETH).withdraw(balance);
                    (bool success, ) = msg.sender.call{value: balance}(
                        new bytes(0)
                    );
                    require(success, "ETH transfer failed");
                } else {
                    IERC20(tokens[i]).safeTransfer(msg.sender, balance);
                }
            }
        }
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, uint256(~0));
        }
    }
}
