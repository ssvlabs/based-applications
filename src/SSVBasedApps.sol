// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IStorage} from "@ssv/src/interfaces/IStorage.sol";
import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";
import {ISSVBasedApps} from "@ssv/src/interfaces/ISSVBasedApps.sol";
import {BasedAppManagement} from "src/BasedAppManagement.sol";
import {SSVBasedAppStorage} from "src/SSVBasedAppStorage.sol";

/**
 * @title SSVBasedApps
 * @notice The Core Contract to manage Based Applications, Delegations & Strategies for SSV Based Applications Platform.
 *
 * **************
 * ** GLOSSARY **
 * **************
 * @dev The following terms are used throughout the contract:
 *
 * - **Account**: An Ethereum address that can:
 *   1. Delegate its balance to another address.
 *   2. Create and manage a strategy.
 *   3. Create and manage a bApp.
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
 *   The strategy can manage its assets via obligations to one or many bApps.
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
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardTransient,
    BasedAppManagement,
    SSVBasedAppStorage
{
    using SafeERC20 for IERC20;

    /// @notice Prevents the initialization of the implementation contract itself during deployment
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the contractz
    /// @param owner The owner of the contract
    /// @param _maxFeeIncrement The maximum fee increment
    function initialize(address owner, uint32 _maxFeeIncrement) public initializer {
        if (_maxFeeIncrement == 0 || _maxFeeIncrement > 10_000) revert IStorage.InvalidMaxFeeIncrement();

        __Ownable_init(owner);
        __UUPSUpgradeable_init();
        initializeBasedAppManagement();

        feeTimelockPeriod = 7 days;
        feeExpireTime = 1 days;
        withdrawalTimelockPeriod = 5 days;
        withdrawalExpireTime = 1 days;
        obligationTimelockPeriod = 7 days;
        obligationExpireTime = 1 days;
        maxPercentage = 1e4;
        ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        maxShares = 1e50;

        maxFeeIncrement = _maxFeeIncrement;

        emit MaxFeeIncrementSet(maxFeeIncrement);
    }

    /// @notice Allow the function to be called only by the strategy owner
    /// @param strategyId The ID of the strategy
    modifier onlyStrategyOwner(uint32 strategyId) {
        if (strategies[strategyId].owner != msg.sender) {
            revert IStorage.InvalidStrategyOwner(msg.sender, strategies[strategyId].owner);
        }
        _;
    }

    /// @notice Defines who can authorize the upgrade
    /// @param newImplementation The address of the new implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // *****************************************
    // *********** Section: Account ************
    // *****************************************

    /// @notice Function to update the metadata URI of the Account
    /// @param metadataURI The new metadata URI
    function updateAccountMetadataURI(string calldata metadataURI) external {
        emit AccountMetadataURIUpdated(msg.sender, metadataURI);
    }

    // *****************************************
    // ** Section: Delegate Validator Balance **
    // *****************************************

    /// @notice Function to delegate a percentage of the account's balance to another account
    /// @param account The address of the account to delegate to
    /// @param percentage The percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function delegateBalance(address account, uint32 percentage) external {
        if (percentage == 0 || percentage > maxPercentage) revert IStorage.InvalidPercentage();
        if (delegations[msg.sender][account] != 0) revert IStorage.DelegationAlreadyExists();

        unchecked {
            uint32 newTotal = totalDelegatedPercentage[msg.sender] + percentage;
            if (newTotal > maxPercentage) {
                revert IStorage.ExceedingPercentageUpdate();
            }
            totalDelegatedPercentage[msg.sender] = newTotal;
        }
        delegations[msg.sender][account] = percentage;

        emit DelegationCreated(msg.sender, account, percentage);
    }

    /// @notice Function to update the delegated validator balance percentage to another account
    /// @param account The address of the account to delegate to
    /// @param percentage The updated percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function updateDelegatedBalance(address account, uint32 percentage) external {
        if (percentage == 0 || percentage > maxPercentage) revert IStorage.InvalidPercentage();

        uint32 existingPercentage = delegations[msg.sender][account];
        if (existingPercentage == 0) revert IStorage.DelegationDoesNotExist();
        if (existingPercentage == percentage) revert IStorage.DelegationExistsWithSameValue();

        unchecked {
            uint32 newTotalPercentage = totalDelegatedPercentage[msg.sender] - existingPercentage + percentage;
            if (newTotalPercentage > maxPercentage) revert IStorage.ExceedingPercentageUpdate();
            totalDelegatedPercentage[msg.sender] = newTotalPercentage;
        }

        delegations[msg.sender][account] = percentage;

        emit DelegationUpdated(msg.sender, account, percentage);
    }

    /// @notice Removes delegation from an account.
    /// @param account The address of the account whose delegation is being removed.
    function removeDelegatedBalance(address account) external {
        uint32 percentage = delegations[msg.sender][account];
        if (percentage == 0) revert IStorage.DelegationDoesNotExist();

        unchecked {
            totalDelegatedPercentage[msg.sender] -= percentage;
        }

        delete delegations[msg.sender][account];

        emit DelegationRemoved(msg.sender, account);
    }

    // ***********************
    // ** Section: Strategy **
    // ***********************

    /// @notice Function to create a new Strategy
    /// @param metadataURI The metadata URI of the strategy
    /// @return strategyId The ID of the new Strategy
    function createStrategy(uint32 fee, string calldata metadataURI) external returns (uint32 strategyId) {
        if (fee > maxPercentage) revert IStorage.InvalidStrategyFee();

        unchecked {
            strategyId = ++_strategyCounter;
        }

        IStorage.Strategy storage newStrategy = strategies[strategyId];
        newStrategy.owner = msg.sender;
        newStrategy.fee = fee;

        emit StrategyCreated(strategyId, msg.sender, fee, metadataURI);
    }

    /// @notice Function to update the metadata URI of the Strategy
    /// @param strategyId The id of the strategy
    /// @param metadataURI The new metadata URI
    function updateStrategyMetadataURI(uint32 strategyId, string calldata metadataURI) external onlyStrategyOwner(strategyId) {
        emit StrategyMetadataURIUpdated(strategyId, metadataURI);
    }

    /// @notice Opt-in to a bApp with a list of tokens and obligation percentages
    /// @dev checks that each token is supported by the bApp, but not that the obligation is > 0
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to opt-in with
    /// @param obligationPercentages The list of obligation percentages for each token
    /// @param data Optional parameter that could be required by the service
    function optInToBApp(
        uint32 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external onlyStrategyOwner(strategyId) {
        if (tokens.length != obligationPercentages.length) revert IStorage.LengthsNotMatching();

        // Check if a strategy exists for the given bApp.
        // It is not possible opt-in to the same bApp twice with the same strategy owner.
        if (accountBAppStrategy[msg.sender][bApp] != 0) revert IStorage.BAppAlreadyOptedIn();

        _createOptInObligations(strategyId, bApp, tokens, obligationPercentages);

        accountBAppStrategy[msg.sender][bApp] = strategyId;

        if (_isBApp(bApp)) {
            bool success = IBasedApp(bApp).optInToBApp(strategyId, tokens, obligationPercentages, data);
            if (!success) revert IStorage.BAppOptInFailed();
        }

        emit BAppOptedInByStrategy(strategyId, bApp, data, tokens, obligationPercentages);
    }

    /// @notice Deposit ERC20 tokens into the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to deposit
    function depositERC20(uint32 strategyId, IERC20 token, uint256 amount) external nonReentrant {
        if (amount == 0) revert IStorage.InvalidAmount();

        address tokenAddress = address(token);
        uint256 totalTokenBalance = strategyTotalBalance[strategyId][tokenAddress];
        uint256 totalShares = strategyTotalShares[strategyId][tokenAddress];

        uint256 shares;
        if (totalShares == 0 || totalTokenBalance == 0) shares = amount;
        else shares = (amount * totalShares) / totalTokenBalance;

        if (totalShares + shares > maxShares) revert IStorage.ExceedingMaxShares();

        strategyAccountShares[strategyId][msg.sender][tokenAddress] += shares;
        strategyTotalShares[strategyId][tokenAddress] += shares;
        strategyTotalBalance[strategyId][tokenAddress] += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit StrategyDeposit(strategyId, msg.sender, address(token), amount);
    }

    /// @notice Deposit ETH into the strategy
    /// @param strategyId The ID of the strategy
    function depositETH(uint32 strategyId) external payable nonReentrant {
        if (msg.value == 0) revert IStorage.InvalidAmount();

        uint256 amount = msg.value;
        uint256 totalEthBalance = strategyTotalBalance[strategyId][ethAddress];
        uint256 totalShares = strategyTotalShares[strategyId][ethAddress];

        uint256 shares;
        if (totalShares == 0 || totalEthBalance == 0) shares = amount;
        else shares = (amount * totalShares) / totalEthBalance;

        if (totalShares + shares > maxShares) revert IStorage.ExceedingMaxShares();

        strategyAccountShares[strategyId][msg.sender][ethAddress] += shares;
        strategyTotalShares[strategyId][ethAddress] += shares;
        strategyTotalBalance[strategyId][ethAddress] += amount;

        emit StrategyDeposit(strategyId, msg.sender, ethAddress, msg.value);
    }

    /// @notice Withdraw ERC20 tokens from the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to withdraw
    function fastWithdrawERC20(uint32 strategyId, IERC20 token, uint256 amount) external nonReentrant {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (address(token) == ethAddress) revert IStorage.InvalidToken();
        if (usedTokens[strategyId][address(token)] != 0) revert IStorage.TokenIsUsedByTheBApp();

        uint256 totalTokenBalance = strategyTotalBalance[strategyId][address(token)];
        uint256 totalShares = strategyTotalShares[strategyId][address(token)];

        if (totalTokenBalance == 0 || totalShares == 0) revert IStorage.InsufficientLiquidity();

        uint256 shares = (amount * totalShares) / totalTokenBalance;

        if (strategyAccountShares[strategyId][msg.sender][address(token)] < shares) revert IStorage.InsufficientBalance();

        // Deduct shares instead of raw token balance
        strategyAccountShares[strategyId][msg.sender][address(token)] -= shares;
        strategyTotalShares[strategyId][address(token)] -= shares;
        strategyTotalBalance[strategyId][address(token)] -= amount;

        token.safeTransfer(msg.sender, amount);

        emit StrategyWithdrawal(strategyId, msg.sender, address(token), amount, true);
    }

    /// @notice Withdraw ETH from the strategy
    /// @param strategyId The ID of the strategy
    /// @param amount The amount to withdraw
    function fastWithdrawETH(uint32 strategyId, uint256 amount) external nonReentrant {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (usedTokens[strategyId][ethAddress] != 0) revert IStorage.TokenIsUsedByTheBApp();

        uint256 totalETHBalance = strategyTotalBalance[strategyId][ethAddress];
        uint256 totalShares = strategyTotalShares[strategyId][ethAddress];

        if (totalETHBalance == 0 || totalShares == 0) revert IStorage.InsufficientLiquidity();

        uint256 shares = (amount * totalShares) / totalETHBalance;

        if (strategyAccountShares[strategyId][msg.sender][ethAddress] < shares) revert IStorage.InsufficientBalance();

        // Deduct shares instead of raw ETH balance
        strategyAccountShares[strategyId][msg.sender][ethAddress] -= shares;
        strategyTotalShares[strategyId][ethAddress] -= shares;
        strategyTotalBalance[strategyId][ethAddress] -= amount;

        payable(msg.sender).transfer(amount);

        emit StrategyWithdrawal(strategyId, msg.sender, ethAddress, amount, true);
    }

    /// @notice Propose a withdrawal of ERC20 tokens from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    /// @param amount The amount to withdraw.
    function proposeWithdrawal(uint32 strategyId, address token, uint256 amount) external {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (token == ethAddress) revert IStorage.InvalidToken();

        uint256 totalTokenBalance = strategyTotalBalance[strategyId][token];
        uint256 totalShares = strategyTotalShares[strategyId][token];

        if (totalTokenBalance == 0 || totalShares == 0) revert IStorage.InsufficientLiquidity();
        uint256 shares = (amount * totalShares) / totalTokenBalance;

        if (strategyAccountShares[strategyId][msg.sender][token] < shares) revert IStorage.InsufficientBalance();
        IStorage.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][address(token)];

        request.shares = shares;
        request.requestTime = uint32(block.timestamp);

        emit StrategyWithdrawalProposed(strategyId, msg.sender, address(token), amount);
    }

    /// @notice Finalize the ERC20 withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    function finalizeWithdrawal(uint32 strategyId, IERC20 token) external nonReentrant {
        IStorage.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][address(token)];
        uint256 requestTime = request.requestTime;

        if (requestTime == 0) revert IStorage.NoPendingWithdrawal();
        _checkTimelocks(requestTime, withdrawalTimelockPeriod, withdrawalExpireTime);

        uint256 shares = request.shares;

        if (strategyAccountShares[strategyId][msg.sender][address(token)] < shares) revert IStorage.InsufficientBalance();

        uint256 totalTokenBalance = strategyTotalBalance[strategyId][address(token)];
        uint256 totalShares = strategyTotalShares[strategyId][address(token)];

        if (totalTokenBalance == 0 || totalShares == 0) revert IStorage.InsufficientLiquidity();

        uint256 amount = (shares * totalTokenBalance) / totalShares;

        strategyAccountShares[strategyId][msg.sender][address(token)] -= shares;
        strategyTotalShares[strategyId][address(token)] -= shares;
        strategyTotalBalance[strategyId][address(token)] -= amount;

        delete withdrawalRequests[strategyId][msg.sender][address(token)];

        token.safeTransfer(msg.sender, amount);

        emit StrategyWithdrawal(strategyId, msg.sender, address(token), amount, false);
    }

    /// @notice Propose an ETH withdrawal from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param amount The amount of ETH to withdraw.
    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external {
        if (amount == 0) revert IStorage.InvalidAmount();

        uint256 totalETHBalance = strategyTotalBalance[strategyId][ethAddress];
        uint256 totalShares = strategyTotalShares[strategyId][ethAddress];

        if (totalETHBalance == 0 || totalShares == 0) revert IStorage.InsufficientLiquidity();

        uint256 shares = (amount * totalShares) / totalETHBalance;

        if (strategyAccountShares[strategyId][msg.sender][ethAddress] < shares) revert IStorage.InsufficientBalance();

        IStorage.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][ethAddress];

        request.shares = shares;
        request.requestTime = uint32(block.timestamp);

        emit StrategyWithdrawalProposed(strategyId, msg.sender, ethAddress, amount);
    }

    /// @notice Finalize the ETH withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    function finalizeWithdrawalETH(uint32 strategyId) external nonReentrant {
        IStorage.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][ethAddress];
        uint256 requestTime = request.requestTime;

        if (requestTime == 0) revert IStorage.NoPendingWithdrawalETH();
        _checkTimelocks(requestTime, withdrawalTimelockPeriod, withdrawalExpireTime);

        uint256 shares = request.shares;

        if (strategyAccountShares[strategyId][msg.sender][ethAddress] < shares) revert IStorage.InsufficientBalance();

        uint256 totalEthBalance = strategyTotalBalance[strategyId][ethAddress];
        uint256 totalShares = strategyTotalShares[strategyId][ethAddress];

        if (totalEthBalance == 0 || totalShares == 0) revert IStorage.InsufficientLiquidity();

        uint256 amount = (shares * totalEthBalance) / totalShares;

        strategyAccountShares[strategyId][msg.sender][ethAddress] -= shares;
        strategyTotalShares[strategyId][ethAddress] -= shares;
        strategyTotalBalance[strategyId][ethAddress] -= amount;

        delete withdrawalRequests[strategyId][msg.sender][ethAddress];

        payable(msg.sender).transfer(amount);

        emit StrategyWithdrawal(strategyId, msg.sender, ethAddress, amount, false);
    }

    /// @notice Add a new obligation for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function createObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage)
        external
        onlyStrategyOwner(strategyId)
    {
        if (accountBAppStrategy[msg.sender][bApp] != strategyId) revert IStorage.BAppNotOptedIn();

        _createSingleObligation(strategyId, bApp, token, obligationPercentage);

        emit ObligationCreated(strategyId, bApp, token, obligationPercentage);
    }

    /// @notice Propose a withdrawal of ERC20 tokens from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    /// @param obligationPercentage The new percentage of the obligation
    function proposeUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage)
        external
        onlyStrategyOwner(strategyId)
    {
        _validateObligationUpdateInput(strategyId, bApp, token, obligationPercentage);

        IStorage.ObligationRequest storage request = obligationRequests[strategyId][bApp][token];

        request.percentage = obligationPercentage;
        request.requestTime = uint32(block.timestamp);

        emit ObligationUpdateProposed(strategyId, bApp, address(token), obligationPercentage);
    }

    /// @notice Finalize the withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    /// @param bApp The address of the bApp.
    /// @param token The ERC20 token address.
    function finalizeUpdateObligation(uint32 strategyId, address bApp, address token) external onlyStrategyOwner(strategyId) {
        IStorage.ObligationRequest storage request = obligationRequests[strategyId][bApp][address(token)];
        uint256 requestTime = request.requestTime;
        uint32 percentage = request.percentage;

        if (requestTime == 0) revert IStorage.NoPendingObligationUpdate();
        _checkTimelocks(requestTime, obligationTimelockPeriod, obligationExpireTime);

        if (percentage == 0 && obligations[strategyId][bApp][address(token)].percentage > 0) {
            usedTokens[strategyId][address(token)] -= 1;
        }

        _updateObligation(strategyId, bApp, address(token), percentage);

        emit ObligationUpdated(strategyId, bApp, address(token), percentage);

        delete obligationRequests[strategyId][bApp][address(token)];
    }

    /// @notice Instantly lowers the fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function reduceFee(uint32 strategyId, uint32 proposedFee) external onlyStrategyOwner(strategyId) {
        if (proposedFee >= strategies[strategyId].fee) revert IStorage.InvalidPercentageIncrement();

        strategies[strategyId].fee = proposedFee;

        emit StrategyFeeUpdated(strategyId, msg.sender, proposedFee, true);
    }

    /// @notice Propose a new fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external onlyStrategyOwner(strategyId) {
        if (proposedFee > maxPercentage) revert IStorage.InvalidPercentage();

        IStorage.Strategy storage strategy = strategies[strategyId];
        uint32 fee = strategy.fee;

        if (proposedFee == fee) revert IStorage.FeeAlreadySet();
        if (proposedFee > fee + maxFeeIncrement) revert IStorage.InvalidPercentageIncrement();

        IStorage.FeeUpdateRequest storage request = feeUpdateRequests[strategyId];

        request.percentage = proposedFee;
        request.requestTime = uint32(block.timestamp);

        emit StrategyFeeUpdateProposed(strategyId, msg.sender, proposedFee);
    }

    /// @notice Finalize the fee update for a strategy
    /// @param strategyId The ID of the strategy
    function finalizeFeeUpdate(uint32 strategyId) external onlyStrategyOwner(strategyId) {
        IStorage.Strategy storage strategy = strategies[strategyId];
        IStorage.FeeUpdateRequest storage request = feeUpdateRequests[strategyId];

        uint256 feeRequestTime = request.requestTime;

        if (feeRequestTime == 0) revert IStorage.NoPendingFeeUpdate();
        _checkTimelocks(feeRequestTime, feeTimelockPeriod, feeExpireTime);

        strategy.fee = request.percentage;
        delete request.percentage;
        delete request.requestTime;

        emit StrategyFeeUpdated(strategyId, msg.sender, strategy.fee, false);
    }

    // ***********************
    // ** Section: Slashing **
    // ***********************

    /// @notice Get the slashable balance for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @return slashableBalance The slashable balance
    function getSlashableBalance(uint32 strategyId, address bApp, address token) public view returns (uint256 slashableBalance) {
        uint32 percentage = obligations[strategyId][bApp][token].percentage;
        uint256 balance = strategyTotalBalance[strategyId][token];
        return balance * percentage / maxPercentage;
    }

    /// @notice Slash a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param amount The amount to slash
    /// @param data Optional parameter that could be required by the service
    function slash(uint32 strategyId, address bApp, address token, uint256 amount, bytes calldata data, address receiver)
        external
        nonReentrant
    {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (!registeredBApps[bApp]) revert IStorage.BAppNotRegistered();

        uint256 slashableBalance = getSlashableBalance(strategyId, bApp, token);
        if (slashableBalance < amount) revert IStorage.InsufficientBalance();

        if (_isBApp(bApp)) {
            // (bool success, uint32 alpha, uint256 amount) = IBasedApp(bApp).slash(strategyId, token, amount, data);
            (bool success) = IBasedApp(bApp).slash(strategyId, token, amount, data);
            if (!success) revert IStorage.BAppSlashingFailed();
        } else {
            // Only the bApp EOA or non-compliant bapp owner can slash
            if (msg.sender != bApp) revert IStorage.InvalidBAppOwner(msg.sender, bApp);
        }

        strategyTotalBalance[strategyId][token] -= amount;
        slashingFund[receiver][token] += amount;

        emit ISSVBasedApps.StrategySlashed(strategyId, bApp, token, amount, data);
    }

    /// @notice Withdraw the slashing fund for a token
    /// @param token The address of the token
    /// @param amount The amount to withdraw
    function withdrawSlashingFund(address token, uint256 amount) external {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (token == ethAddress) revert IStorage.InvalidToken();
        if (slashingFund[msg.sender][token] < amount) revert IStorage.InsufficientBalance();

        slashingFund[msg.sender][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);

        emit ISSVBasedApps.SlashingFundWithdrawn(token, amount);
    }

    /// @notice Withdraw the slashing fund for ETH
    /// @param amount The amount to withdraw
    function withdrawETHSlashingFund(uint256 amount) external {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (slashingFund[msg.sender][ethAddress] < amount) revert IStorage.InsufficientBalance();

        slashingFund[msg.sender][ethAddress] -= amount;
        payable(msg.sender).transfer(amount);

        emit ISSVBasedApps.SlashingFundWithdrawn(ethAddress, amount);
    }

    // **********************
    // ** Section: Helpers **
    // **********************

    /// @notice Set the obligation percentages for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to set obligations for
    /// @param obligationPercentages The list of obligation percentages for each token
    function _createOptInObligations(
        uint32 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages
    ) private {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length;) {
            _createSingleObligation(strategyId, bApp, tokens[i], obligationPercentages[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Set a single obligation for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function _createSingleObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) private {
        if (!bAppTokens[bApp][token].isSet) revert IStorage.TokenNoTSupportedByBApp(token);
        if (obligationPercentage > maxPercentage) revert IStorage.InvalidPercentage();
        if (obligations[strategyId][bApp][token].isSet) revert IStorage.ObligationAlreadySet();

        if (obligationPercentage != 0) {
            usedTokens[strategyId][token] += 1;
            obligations[strategyId][bApp][token].percentage = obligationPercentage;
        }

        obligations[strategyId][bApp][token].isSet = true;
    }

    /// @notice Validate the input for the obligation creation or update
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function _validateObligationUpdateInput(uint32 strategyId, address bApp, address token, uint32 obligationPercentage)
        private
        view
    {
        if (accountBAppStrategy[msg.sender][bApp] != strategyId) revert IStorage.BAppNotOptedIn();
        if (obligationPercentage > maxPercentage) revert IStorage.InvalidPercentage();
        if (obligationPercentage == obligations[strategyId][bApp][token].percentage) {
            revert IStorage.ObligationAlreadySet();
        }
        if (!obligations[strategyId][bApp][token].isSet) revert IStorage.ObligationHasNotBeenCreated();
    }

    /// @notice Update a single obligation for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    function _updateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) private {
        if (obligations[strategyId][bApp][token].percentage == 0 && obligationPercentage > 0) {
            usedTokens[strategyId][token] += 1;
        }
        obligations[strategyId][bApp][token].percentage = obligationPercentage;
    }

    // *****************************************
    // ** Section: Setters **
    // *****************************************
    function setFeeTimelockPeriod(uint32 value) external onlyOwner {
        feeTimelockPeriod = value;
    }

    function setFeeExpireTime(uint32 value) external onlyOwner {
        feeExpireTime = value;
    }

    function setWithdrawalTimelockPeriod(uint32 value) external onlyOwner {
        withdrawalTimelockPeriod = value;
    }

    function setWithdrawalExpireTime(uint32 value) external onlyOwner {
        withdrawalExpireTime = value;
    }

    function setObligationTimelockPeriod(uint32 value) external onlyOwner {
        obligationTimelockPeriod = value;
    }

    function setObligationExpireTime(uint32 value) external onlyOwner {
        obligationExpireTime = value;
    }

    function setMaxPercentage(uint32 value) external onlyOwner {
        maxPercentage = value;
    }

    function setEthAddress(address value) external onlyOwner {
        ethAddress = value;
    }

    function setMaxShares(uint256 value) external onlyOwner {
        maxShares = value;
    }

    function setMaxFeeIncrement(uint32 value) external onlyOwner {
        maxFeeIncrement = value;
    }
}
