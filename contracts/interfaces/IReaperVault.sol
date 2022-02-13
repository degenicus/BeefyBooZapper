pragma solidity >=0.7.0;

import "./IERC20.sol";

interface IReaperVault is IERC20 {
    function deposit(uint256 amount) external;

    function withdraw(uint256 shares) external;

    function token() external view returns (address);
}
