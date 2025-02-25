// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppCore} from "middleware/modules/core/BasedAppCore.sol";
import {BasedAppWhitelisted} from "middleware/modules/BasedAppWhitelisted.sol";

contract WhitelistExample is BasedAppCore, BasedAppWhitelisted {
    constructor(address _basedAppManager, address owner) BasedAppCore(_basedAppManager, owner) {
        isWhitelisted[owner] = true;
    }

    function addWhitelisted(address account) external override onlyOwner {
        if (isWhitelisted[account]) revert AlreadyWhitelisted();
        if (account == address(0)) revert ZeroAddress();
        isWhitelisted[account] = true;
    }

    function removeWhitelisted(address account) external override onlyOwner {
        if (!isWhitelisted[account]) revert NotWhitelisted();
        delete isWhitelisted[account];
    }

    function optInToBApp(
        uint32, /*strategyId*/
        address[] calldata, /*tokens*/
        uint32[] calldata, /*obligationPercentages*/
        bytes calldata /*data*/
    ) external view override onlySSVBasedAppManager returns (bool success) {
        if (!isWhitelisted[msg.sender]) revert NonWhitelistedCaller();
        return true;
    }
}
