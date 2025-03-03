// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IBasedApp is IERC165 {
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;

    function optInToBApp(
        uint32 strategyId,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external returns (bool);

    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function proposeBAppTokensUpdate(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function finalizeBAppTokensUpdate() external;

    function proposeBAppTokensRemoval(address[] calldata tokens) external;

    function finalizeBAppTokensRemoval() external;

    function updateBAppMetadataURI(string calldata metadataURI) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
