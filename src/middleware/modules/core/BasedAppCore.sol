// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// =====================================================================================
// ⚠️ WARNING: IMPLEMENT OWNER OR ACCESS ROLES ⚠️
// -------------------------------------------------------------------------------------
// This contract does NOT include any ownership or access control mechanism by default.
// It is crucial that you add proper access control (e.g., Ownable, AccessControl)
// to prevent unauthorized interactions with critical functions.
// =====================================================================================
abstract contract BasedAppCore is IBasedApp {
    /// @notice Address of the SSV Based App Manager contract
    address public immutable BASED_APP_MANAGER;

    /// @dev Allows only the SSV Based App Manager to call the function
    modifier onlySSVBasedAppManager() {
        if (msg.sender != address(BASED_APP_MANAGER)) {
            revert UnauthorizedCaller();
        }
        _;
    }

    /// @notice constructor for the BasedAppCore contract, initializes the contract with the SSVBasedApps address and the owner and disables the initializers.
    /// @param _basedAppManager address of the SSVBasedApps contract
    constructor(address _basedAppManager) {
        BASED_APP_MANAGER = _basedAppManager;
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
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI)
        external
        virtual
    {
        IBasedAppManager(BASED_APP_MANAGER).registerBApp(tokens, sharedRiskLevels, metadataURI);
    }

    /// @notice Adds tokens to a BApp
    /// @param tokens array of token addresses
    /// @param sharedRiskLevels array of shared risk levels
    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external virtual {
        IBasedAppManager(BASED_APP_MANAGER).addTokensToBApp(tokens, sharedRiskLevels);
    }

    /// @notice Updates the tokens of a BApp
    /// @param tokens array of token addresses
    /// @param sharedRiskLevels array of shared risk levels
    function proposeBAppTokensUpdate(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external virtual {
        IBasedAppManager(BASED_APP_MANAGER).proposeBAppTokensUpdate(tokens, sharedRiskLevels);
    }

    /// @notice Finalizes the update of the tokens of a BApp
    function finalizeBAppTokensUpdate() external virtual {
        IBasedAppManager(BASED_APP_MANAGER).finalizeBAppTokensUpdate();
    }

    /// @notice Removes tokens from a BApp
    /// @param tokens array of token addresses
    function proposeBAppTokensRemoval(address[] calldata tokens) external virtual {
        IBasedAppManager(BASED_APP_MANAGER).proposeBAppTokensRemoval(tokens);
    }

    /// @notice Finalizes the removal of the tokens of a BApp
    function finalizeBAppTokensRemoval() external virtual {
        IBasedAppManager(BASED_APP_MANAGER).finalizeBAppTokensRemoval();
    }

    /// @notice Updates the metadata URI of a BApp
    /// @param metadataURI new metadata URI
    function updateBAppMetadataURI(string calldata metadataURI) external virtual {
        IBasedAppManager(BASED_APP_MANAGER).updateBAppMetadataURI(metadataURI);
    }

    /// @notice Allows a Strategy to Opt-in to a BApp, it can be called only by the SSV Based App Manager
    function optInToBApp(
        uint32, /*strategyId*/
        address[] calldata, /*tokens*/
        uint32[] calldata, /*obligationPercentages*/
        bytes calldata /*data*/
    ) external virtual onlySSVBasedAppManager returns (bool success) {
        ///@dev --- CORE LOGIC (TO BE IMPLEMENTED) ---
        ///@dev --- RETURN TRUE IF SUCCESS, FALSE OTHERWISE ---
        return true;
    }

    function slash(uint32, /*strategyId*/ address, /*token*/ uint256, /*amount*/ bytes calldata)
        external
        virtual
        onlySSVBasedAppManager
        returns (bool)
    {
        ///@dev --- CORE LOGIC (TO BE IMPLEMENTED) ---
        ///@dev --- RETURN TRUE IF SUCCESS, FALSE OTHERWISE ---
        return false;
    }

    /// @notice Checks if the contract supports the interface
    /// @param interfaceId interface id
    /// @return true if the contract supports the interface
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(IBasedApp).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
