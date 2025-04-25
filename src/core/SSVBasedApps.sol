// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { MAX_PERCENTAGE, ETH_ADDRESS } from "@ssv/src/core/libraries/ValidationLib.sol";
import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";
import { ISSVBasedApps } from "@ssv/src/core/interfaces/ISSVBasedApps.sol";
import { IProtocolManager } from "@ssv/src/core/interfaces/IProtocolManager.sol";
import { IStrategyManager } from "@ssv/src/core/interfaces/IStrategyManager.sol";
import { CoreStorageLib, SSVCoreModules } from "@ssv/src/core/libraries/CoreStorageLib.sol";
import { ProtocolStorageLib } from "@ssv/src/core/libraries/ProtocolStorageLib.sol";

/**
 * @title SSVBasedApps
 * @notice The Core Contract to manage Based Applications, Validator Balance Delegations & Strategies for SSV Based Applications Platform.
 *
 * **************
 * ** GLOSSARY **
 * **************
 * @dev The following terms are used throughout the contract:
 *
 * - **Account**: An Ethereum address that can:
 *   1. Delegate its balance to another address.
 *   2. Create and manage a strategy.
 *   3. Create and manage or be a bApp.
 *
 * - **Based Application**: or bApp.
 *   The entity that requests validation services from operators. On-chain is represented by an Ethereum address.
 *   A bApp can be created by registering to this Core Contract, specifying the risk level.
 *   The bApp can also specify one or many tokens as slashable capital to be provided by strategies.
 *   During the bApp registration, the bApp owner can set the shared risk level and optionally a metadata URI, to be used in the SSV bApp marketplace.
 *
 * - **Delegator**: An Ethereum address that has Ethereum Validator Balance of Staked ETH within the SSV platform. This capital delegated is non-slashable.
 *   The delegator can decide to delegate its balance to itself or/and to a single or many receiver accounts.
 *   The delegator has to set its address as the receiver account, when the delegator wants to delegate its balance to itself.
 *   The delegated balance goes to an account and not to a strategy. This receiver account can manage only a single strategy.
 *
 * - **Strategy**: The entity that manages the slashable assets bounded to based apps.
 *   The strategy has its own balance, accounted in this core contract.
 *   The strategy can be created by an account that becomes its owner.
 *   The assets can be ERC20 tokens or Native ETH tokens, that can be deposited or withdrawn by the participants.
 *   The strategy can manage its assets via s.obligations to one or many bApps.
 *
 * - **Obligation**: A percentage of the strategy's balance of ERC20 (or Native ETH), that is reserved for securing a bApp.
 *   The obligation is set exclusively by the strategy owner and can be updated by the strategy owner.
 *   The tokens specified in an obligation needs to match the tokens specified in the bApp.
 *
 * *************
 * ** AUTHORS **
 * *************
 * @author
 * Marco Tabasco
 * Riccardo Persiani
 */
contract SSVBasedApps is
    ISSVBasedApps,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    IBasedAppManager,
    IStrategyManager,
    IProtocolManager
{
    // ***************************
    // ** Section: Initializers **
    // ***************************
    function initialize(
        address owner_,
        IBasedAppManager ssvBasedAppManger_,
        IStrategyManager ssvStrategyManager_,
        IProtocolManager protocolManager_,
        ProtocolStorageLib.Data calldata config
    ) external override initializer onlyProxy {
        __UUPSUpgradeable_init();
        __Ownable_init_unchained(owner_);
        __SSVBasedApplications_init_unchained(
            ssvBasedAppManger_,
            ssvStrategyManager_,
            protocolManager_,
            config
        );
    }

    // solhint-disable-next-line func-name-mixedcase
    function __SSVBasedApplications_init_unchained(
        IBasedAppManager ssvBasedAppManger_,
        IStrategyManager ssvStrategyManager_,
        IProtocolManager protocolManager_,
        ProtocolStorageLib.Data calldata config
    ) internal onlyInitializing {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        ProtocolStorageLib.Data storage sp = ProtocolStorageLib.load();
        s.ssvContracts[SSVCoreModules.SSV_STRATEGY_MANAGER] = address(
            ssvStrategyManager_
        );
        s.ssvContracts[SSVCoreModules.SSV_BAPPS_MANAGER] = address(
            ssvBasedAppManger_
        );
        s.ssvContracts[SSVCoreModules.SSV_PROTOCOL_MANAGER] = address(
            protocolManager_
        );

        if (config.maxFeeIncrement == 0 || config.maxFeeIncrement > 10_000) {
            revert InvalidMaxFeeIncrement();
        }

        sp.maxFeeIncrement = config.maxFeeIncrement;
        sp.feeTimelockPeriod = config.feeTimelockPeriod;
        sp.feeExpireTime = config.feeExpireTime;
        sp.withdrawalTimelockPeriod = config.withdrawalTimelockPeriod;
        sp.withdrawalExpireTime = config.withdrawalExpireTime;
        sp.obligationTimelockPeriod = config.obligationTimelockPeriod;
        sp.obligationExpireTime = config.obligationExpireTime;
        sp.tokenUpdateTimelockPeriod = config.tokenUpdateTimelockPeriod;
        sp.maxShares = config.maxShares;
        sp.disabledFeatures = config.disabledFeatures;

        emit MaxFeeIncrementSet(sp.maxFeeIncrement);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ****************************
    // ** Section: UUPS Required **
    // ****************************
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // *********************************
    // ** Section: External Functions **
    // *********************************

    // solhint-disable no-unused-vars
    function updateBAppMetadataURI(string calldata metadataURI) external {
        _delegateTo(SSVCoreModules.SSV_BAPPS_MANAGER);
    }

    function registerBApp(
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external {
        _delegateTo(SSVCoreModules.SSV_BAPPS_MANAGER);
    }

    function updateBAppsTokens(
        ICore.TokenConfig[] calldata tokenConfigs
    ) external {
        _delegateTo(SSVCoreModules.SSV_BAPPS_MANAGER);
    }

    function createObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function createStrategy(
        uint32 fee,
        string calldata metadataURI
    ) external returns (uint32 strategyId) {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function delegateBalance(address receiver, uint32 percentage) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function depositERC20(
        uint32 strategyId,
        IERC20 token,
        uint256 amount
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function depositETH(uint32 strategyId) external payable {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function finalizeFeeUpdate(uint32 strategyId) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function finalizeUpdateObligation(
        uint32 strategyId,
        address bApp,
        address token
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function finalizeWithdrawal(uint32 strategyId, IERC20 token) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function finalizeWithdrawalETH(uint32 strategyId) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function getSlashableBalance(
        uint32 strategyId,
        address bApp,
        address token
    ) public view returns (uint256 slashableBalance) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[
            strategyId
        ][token];

        uint32 percentage = s.obligations[strategyId][bApp][token].percentage;
        uint256 balance = strategyTokenShares.totalTokenBalance;

        return (balance * percentage) / MAX_PERCENTAGE;
    }

    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function proposeUpdateObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function proposeWithdrawal(
        uint32 strategyId,
        address token,
        uint256 amount
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function reduceFee(uint32 strategyId, uint32 proposedFee) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function removeDelegatedBalance(address receiver) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function updateDelegatedBalance(
        address receiver,
        uint32 percentage
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function updateStrategyMetadataURI(
        uint32 strategyId,
        string calldata metadataURI
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function updateAccountMetadataURI(string calldata metadataURI) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function slash(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 percentage,
        bytes calldata data
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function withdrawSlashingFund(address token, uint256 amount) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function withdrawETHSlashingFund(uint256 amount) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function optInToBApp(
        uint32 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    // *************************************
    // ** Section: External Functions DAO **
    // *************************************

    function updateFeeTimelockPeriod(uint32 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateFeeExpireTime(uint32 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateWithdrawalTimelockPeriod(uint32 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateWithdrawalExpireTime(uint32 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateObligationTimelockPeriod(uint32 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateObligationExpireTime(uint32 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateTokenUpdateTimelockPeriod(uint32 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateMaxShares(uint256 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateMaxFeeIncrement(uint32 value) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    function updateDisabledFeatures(
        uint32 disabledFeatures
    ) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PROTOCOL_MANAGER);
    }

    // *****************************
    // ** Section: External Views **
    // *****************************

    function delegations(
        address account,
        address receiver
    ) external view returns (uint32) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.delegations[account][receiver];
    }

    function totalDelegatedPercentage(
        address delegator
    ) external view returns (uint32) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.totalDelegatedPercentage[delegator];
    }

    function registeredBApps(
        address bApp
    ) external view returns (bool isRegistered) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.registeredBApps[bApp];
    }

    function strategies(
        uint32 strategyId
    ) external view returns (address strategyOwner, uint32 fee) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (s.strategies[strategyId].owner, s.strategies[strategyId].fee);
    }

    function ownedStrategies(
        address owner
    ) external view returns (uint32[] memory strategyIds) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.strategyOwners[owner];
    }

    function strategyAccountShares(
        uint32 strategyId,
        address account,
        address token
    ) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[
            strategyId
        ][token];
        if (
            strategyTokenShares.accountGeneration[account] !=
            strategyTokenShares.currentGeneration
        ) return 0;
        else
            return
                s.strategyTokenShares[strategyId][token].accountShareBalance[
                    account
                ];
    }

    function strategyTotalBalance(
        uint32 strategyId,
        address token
    ) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.strategyTokenShares[strategyId][token].totalTokenBalance;
    }

    function strategyTotalShares(
        uint32 strategyId,
        address token
    ) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.strategyTokenShares[strategyId][token].totalShareBalance;
    }

    function strategyGeneration(
        uint32 strategyId,
        address token
    ) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.strategyTokenShares[strategyId][token].currentGeneration;
    }

    function obligations(
        uint32 strategyId,
        address bApp,
        address token
    ) external view returns (uint32 percentage, bool isSet) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (
            s.obligations[strategyId][bApp][token].percentage,
            s.obligations[strategyId][bApp][token].isSet
        );
    }

    function bAppTokens(
        address bApp,
        address token
    )
        external
        view
        returns (
            uint32 currentValue,
            bool isSet,
            uint32 pendingValue,
            uint32 effectTime
        )
    {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (
            s.bAppTokens[bApp][token].currentValue,
            s.bAppTokens[bApp][token].isSet,
            s.bAppTokens[bApp][token].pendingValue,
            s.bAppTokens[bApp][token].effectTime
        );
    }

    function accountBAppStrategy(
        address account,
        address bApp
    ) external view returns (uint32) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.accountBAppStrategy[account][bApp];
    }

    function feeUpdateRequests(
        uint32 strategyId
    ) external view returns (uint32 percentage, uint32 requestTime) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (
            s.feeUpdateRequests[strategyId].percentage,
            s.feeUpdateRequests[strategyId].requestTime
        );
    }

    function withdrawalRequests(
        uint32 strategyId,
        address account,
        address token
    ) external view returns (uint256 shares, uint32 requestTime) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (
            s.withdrawalRequests[strategyId][account][token].shares,
            s.withdrawalRequests[strategyId][account][token].requestTime
        );
    }

    function obligationRequests(
        uint32 strategyId,
        address token,
        address bApp
    ) external view returns (uint32 percentage, uint32 requestTime) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (
            s.obligationRequests[strategyId][token][bApp].percentage,
            s.obligationRequests[strategyId][token][bApp].requestTime
        );
    }

    function slashingFund(
        address account,
        address token
    ) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.slashingFund[account][token];
    }

    // **************************************
    // ** Section: External Protocol Views **
    // **************************************

    function maxPercentage() external pure returns (uint32) {
        return MAX_PERCENTAGE;
    }

    function ethAddress() external pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxShares() external view returns (uint256) {
        return ProtocolStorageLib.load().maxShares;
    }

    function maxFeeIncrement() external view returns (uint32) {
        return ProtocolStorageLib.load().maxFeeIncrement;
    }

    function feeTimelockPeriod() external view returns (uint32) {
        return ProtocolStorageLib.load().feeTimelockPeriod;
    }

    function feeExpireTime() external view returns (uint32) {
        return ProtocolStorageLib.load().feeExpireTime;
    }

    function withdrawalTimelockPeriod() external view returns (uint32) {
        return ProtocolStorageLib.load().withdrawalTimelockPeriod;
    }

    function withdrawalExpireTime() external view returns (uint32) {
        return ProtocolStorageLib.load().withdrawalExpireTime;
    }

    function obligationTimelockPeriod() external view returns (uint32) {
        return ProtocolStorageLib.load().obligationTimelockPeriod;
    }

    function obligationExpireTime() external view returns (uint32) {
        return ProtocolStorageLib.load().obligationExpireTime;
    }

    function disabledFeatures() external view returns (uint32) {
        return ProtocolStorageLib.load().disabledFeatures;
    }

    function tokenUpdateTimelockPeriod() external view returns (uint32) {
        return ProtocolStorageLib.load().tokenUpdateTimelockPeriod;
    }

    function getVersion() external pure returns (string memory) {
        return "0.1.0";
    }

    // *********************************
    // ** Section: External Libraries **
    // *********************************
    /**
     * @notice Retrieves the currently configured Module contract address.
     * @param moduleId The ID of the SSV Module.
     * @return The address of the SSV Module.
     */
    function getModuleAddress(
        SSVCoreModules moduleId
    ) external view returns (address) {
        return CoreStorageLib.load().ssvContracts[moduleId];
    }

    function updateModule(
        SSVCoreModules[] calldata moduleIds,
        address[] calldata moduleAddresses
    ) external onlyOwner {
        uint32 size;
        for (uint256 i; i < moduleIds.length; i++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                size := extcodesize(
                    calldataload(add(moduleAddresses.offset, mul(i, 32)))
                )
            }
            if (size == 0) revert TargetModuleDoesNotExist(uint8(moduleIds[i]));

            CoreStorageLib.load().ssvContracts[moduleIds[i]] = moduleAddresses[
                i
            ];

            emit ModuleUpdated(moduleIds[i], moduleAddresses[i]);
        }
    }

    function _delegateTo(SSVCoreModules moduleId) internal {
        address implementation = CoreStorageLib.load().ssvContracts[moduleId];
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            // slither-disable-next-line incorrect-return
            default {
                return(0, returndatasize())
            }
        }
    }
}
