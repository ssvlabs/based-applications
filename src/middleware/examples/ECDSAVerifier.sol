// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {
    OwnableBasedApp
} from "@ssv/src/middleware/modules/core+roles/OwnableBasedApp.sol";

import {
    SignatureChecker
} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract ECDSAVerifier is OwnableBasedApp {
    constructor(
        address _basedAppManager,
        address _initOwner
    ) OwnableBasedApp(_basedAppManager, _initOwner) {}

    function optInToBApp(
        uint32,
        address[] calldata,
        uint32[] calldata,
        bytes calldata data
    ) external view override onlySSVBasedAppManager returns (bool success) {
        // (address signer) = abi
        //     .decode(data, (address));
        //     if (signer != 0x4CC366443d8B5846d56B57F29F0944Fa623906B4) {
        //         return false;
        //     }
        // (address signer, bytes32 messageHash, bytes memory signature) = abi
        //     .decode(data, (address, bytes32, bytes));
        // success = SignatureChecker.isValidSignatureNow(
        //     signer,
        //     messageHash,
        //     signature
        // );
        return true;
    }
}
