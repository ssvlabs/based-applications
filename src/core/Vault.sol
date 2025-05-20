// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "forge-std/console.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract Vault is ERC4626 {
    constructor(
        address underlying
    ) ERC20("Investment Vault stETH", "VSTETH") ERC4626(IERC20(underlying)) {}
}
