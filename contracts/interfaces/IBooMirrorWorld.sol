// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity >=0.7.0;

interface IBooMirrorWorld is IERC20 {
    // Locks Boo and mints xBoo
    function enter(uint256 _amount) external;

    // Unlocks the staked + gained Boo and burns xBoo
    function leave(uint256 _share) external;

    // returns the total amount of BOO an address has in the contract including fees earned
    function BOOBalance(address _account)
        external
        view
        returns (uint256 booAmount_);

    // returns how much BOO someone gets for redeeming xBOO
    function xBOOForBOO(uint256 _xBOOAmount)
        external
        view
        returns (uint256 booAmount_);

    // returns how much xBOO someone gets for depositing BOO
    function BOOForxBOO(uint256 _booAmount)
        external
        view
        returns (uint256 xBOOAmount_);
}
