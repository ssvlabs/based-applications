// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IBasedApp is IERC165 {
    function optInToBApp(
        uint32 strategyId,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external returns (bool);
    function registerBApp(
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external;
    function slash(
        uint32 strategyId,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, address receiver, bool exit);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function updateBAppMetadataURI(string calldata metadataURI) external;

    error UnauthorizedCaller();
}
