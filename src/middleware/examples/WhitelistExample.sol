// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppCore} from "middleware/modules/core/BasedAppCore.sol";

contract WhitelistBasedApp is BasedAppCore {
    error NonWhitelistedCaller();

    mapping(address => bool) public isWhitelisted;

    constructor(address _basedAppManager, address owner) BasedAppCore(_basedAppManager, owner) {
        isWhitelisted[owner] = true;
    }

    function addWhitelisted(address account) external onlyOwner {
        isWhitelisted[account] = true;
    }

    function removeWhitelisted(address account) external onlyOwner {
        isWhitelisted[account] = false;
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
