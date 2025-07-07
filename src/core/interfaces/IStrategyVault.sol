// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategyVault {
    event NewStrategyCreated();
    function initialize(address _allowedSender) external;
    function withdraw(IERC20 token, uint256 amount, address receiver) external;
    function withdrawETH(uint256 amount, address receiver) external;
}
