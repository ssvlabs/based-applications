// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { IBasedApp } from "@ssv/src/middleware/interfaces/IBasedApp.sol";

import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";

import { IStrategyManager } from "@ssv/src/core/interfaces/IStrategyManager.sol";

// =====================================================================================
// ⚠️ WARNING: IMPLEMENT OWNER OR ACCESS ROLES ⚠️
// -------------------------------------------------------------------------------------
// This contract does NOT include any ownership or access control mechanism by default.
// It is crucial that you add proper access control (e.g., Ownable, AccessControl)
// to prevent unauthorized interactions with critical functions.
// =====================================================================================
abstract contract BasedAppCore is IBasedApp {
    /// @notice Address of the SSV Based App Manager contract
    address public immutable SSV_BASED_APPS_NETWORK;

    /// @dev Allows only the SSV Based App Manager to call the function
    modifier onlySSVBasedAppManager() {
        if (msg.sender != address(SSV_BASED_APPS_NETWORK)) {
            revert UnauthorizedCaller();
        }
        _;
    }

    /// @notice constructor for the BasedAppCore contract,
    /// initializes the contract with the SSVBasedApps address and the owner and disables the initializers.
    /// @param _ssvBasedAppsNetwork address of the SSVBasedApps contract
    constructor(address _ssvBasedAppsNetwork) {
        SSV_BASED_APPS_NETWORK = _ssvBasedAppsNetwork;
    }

    /// @notice Registers a BApp calling the SSV SSVBasedApps
    /// @param tokens array of token addresses
    /// @param sharedRiskLevels array of shared risk levels
    /// @param metadataURI URI of the metadata
    /// @dev metadata should point to a json that respect template:
    ///    {
    ///        "name": "SSV Based App",
    ///        "website": "https://www.ssvlabs.io/",
    ///        "description": "SSV Based App Core",
    ///        "logo": "https://link-to-your-logo.png",
    ///        "social": "https://x.com/ssv_network"
    ///    }
    function registerBApp(
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external virtual {
        IBasedAppManager(SSV_BASED_APPS_NETWORK).registerBApp(
            tokens,
            sharedRiskLevels,
            metadataURI
        );
    }

    /// @notice Updates the metadata URI of a BApp
    /// @param metadataURI new metadata URI
    function updateBAppMetadataURI(
        string calldata metadataURI
    ) external virtual {
        IBasedAppManager(SSV_BASED_APPS_NETWORK).updateBAppMetadataURI(
            metadataURI
        );
    }

    function withdrawSlashingFund(
        address token,
        uint256 amount
    ) external virtual {
        IStrategyManager(SSV_BASED_APPS_NETWORK).withdrawSlashingFund(
            token,
            amount
        );
    }

    function withdrawETHSlashingFund(uint256 amount) external virtual {
        IStrategyManager(SSV_BASED_APPS_NETWORK).withdrawETHSlashingFund(
            amount
        );
    }

    /// @notice Allows a Strategy to Opt-in to a BApp, it can be called only by the SSV Based App Manager
    function optInToBApp(
        uint32,
        /*strategyId*/
        address[] calldata,
        /*tokens*/
        uint32[] calldata,
        /*obligationPercentages*/
        bytes calldata /*data*/
    ) external virtual onlySSVBasedAppManager returns (bool success) {
        ///@dev --- CORE LOGIC (TO BE IMPLEMENTED) ---
        ///@dev --- RETURN TRUE IF SUCCESS, FALSE OTHERWISE ---
        return true;
    }

    function slash(
        uint32,
        /*strategyId*/
        address,
        /*token*/
        uint256,
        /*amount*/
        bytes calldata
    ) external virtual onlySSVBasedAppManager returns (bool, address, bool) {
        ///@dev --- CORE LOGIC (TO BE IMPLEMENTED) ---
        ///@dev --- RETURN TRUE IF SUCCESS, FALSE OTHERWISE ---
        ///@dev --- RETURN RECEIVER ADDRESS FOR THE SLASHED FUNDS ---
        return (true, address(this), true);
    }

    /// @notice Checks if the contract supports the interface
    /// @param interfaceId interface id
    /// @return true if the contract supports the interface
    function supportsInterface(
        bytes4 interfaceId
    ) public pure virtual returns (bool) {
        return
            interfaceId == type(IBasedApp).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // Receive function to accept plain Ether transfers
    receive() external payable virtual {}
}
