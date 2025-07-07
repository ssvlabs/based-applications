// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.30;

// there needs to be different shares per token...

// shares[tokenAddress][ownerAddress] = 1;
// use balanceOf for balance.
import { IStrategyVault } from "@ssv/src/core/interfaces/IStrategyVault.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ISSVBasedApps } from "@ssv/src/core/interfaces/ISSVBasedApps.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    ReentrancyGuardTransient
} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StrategyVault is
    IStrategyVault,
    Initializable,
    ReentrancyGuardTransient
{
    using SafeERC20 for IERC20;

    address public ssvBasedApps;

    error UnauthorizedCaller();

    /// @dev Allows only the SSV Based App Manager to call the function
    modifier onlySSVBasedAppManager() {
        if (msg.sender != ssvBasedApps) {
            revert UnauthorizedCaller();
        }
        _;
    }

    function initialize(address _ssvBasedApps) public initializer {
        ssvBasedApps = _ssvBasedApps;
        emit NewStrategyCreated();
    }

    function withdraw(
        IERC20 token,
        uint256 amount,
        address receiver
    ) public onlySSVBasedAppManager nonReentrant {
        token.transfer(receiver, amount);
    }

    function withdrawETH(
        uint256 amount,
        address receiver
    ) public onlySSVBasedAppManager nonReentrant {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        require(amount > 0, "Amount must be > 0");
        require(receiver != address(0), "Zero address");
        (bool success, ) = payable(receiver).call{ value: amount }("");
        require(success, "ETH transfer failed");
    }

    receive() external payable onlySSVBasedAppManager {}

    fallback() external payable onlySSVBasedAppManager {}
}
