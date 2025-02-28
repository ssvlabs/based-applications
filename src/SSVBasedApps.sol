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
    ISSVBasedApps
{
    using SafeERC20 for IERC20;

    uint32 public constant FEE_TIMELOCK_PERIOD = 7 days;
    uint32 public constant FEE_EXPIRE_TIME = 1 days;
    uint32 public constant WITHDRAWAL_TIMELOCK_PERIOD = 5 days;
    uint32 public constant WITHDRAWAL_EXPIRE_TIME = 1 days;
    uint32 public constant OBLIGATION_TIMELOCK_PERIOD = 7 days;
    uint32 public constant OBLIGATION_EXPIRE_TIME = 1 days;
    uint32 public constant MAX_PERCENTAGE = 1e4;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint32 private _strategyCounter;
    uint32 public maxFeeIncrement;

    /**
     * @notice Tracks the strategies created
     * @dev The strategy ID is incremental and unique
     */
    mapping(uint32 strategyId => IStorage.Strategy) public strategies;
    /**
     * @notice Links an account to a single strategy for a specific bApp
     * @dev Guarantees that an account cannot have more than one strategy for a given bApp
     */
    mapping(address account => mapping(address bApp => uint32 strategyId)) public accountBAppStrategy;
    /**
     * @notice Tracks the percentage of validator balance a delegator has delegated to a specific receiver account
     * @dev Each delegator can allocate a portion of their validator balance to multiple accounts including itself
     */
    mapping(address delegator => mapping(address account => uint32 percentage)) public delegations;
    /**
     * @notice Tracks the total percentage of validator balance a delegator has delegated across all receiver accounts
     * @dev Ensures that a delegator cannot delegate more than 100% of their validator balance
     */
    mapping(address delegator => uint32 totalPercentage) public totalDelegatedPercentage;
    /**
     * @notice Tracks the token balances for individual strategies.
     * @dev Tracks that how much a token account has in a specific strategy
     */
    mapping(uint32 strategyId => mapping(address account => mapping(address token => uint256 balance))) public
        strategyTokenBalances;
    /**
     * @notice Tracks obligation percentages for a strategy based on specific bApps and tokens.
     * @dev Uses a hash of the bApp and token to map the obligation percentage for the strategy.
     */
    mapping(uint32 strategyId => mapping(address bApp => mapping(address token => IStorage.Obligation))) public obligations;
    /**
     * @notice Tracks unallocated tokens in a strategy.
     * @dev Count the number of bApps that have one obligation set for the token.
     * If the counter is 0, the token is unused and we can allow fast withdrawal.
     */
    mapping(uint32 strategyId => mapping(address token => uint32 bAppsCounter)) public usedTokens;
    /**
     * @notice Tracks all the withdrawal requests divided by token per strategy.
     * @dev User can have only one pending withdrawal request per token.
     *  Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint32 strategyId => mapping(address account => mapping(address token => IStorage.WithdrawalRequest))) public
        withdrawalRequests;
    /**
     * @notice Tracks all the obligation change requests divided by token per strategy.
     * @dev Strategy can have only one pending obligation change request per token.
     * Only the strategy owner can submit one.
     * Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint32 strategyId => mapping(address token => mapping(address bApp => IStorage.ObligationRequest))) public
        obligationRequests;
    /**
     * @notice Tracks the fee update requests for a strategy
     * @dev Only the strategy owner can submit one.
     * Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint32 strategyId => IStorage.FeeUpdateRequest) public feeUpdateRequests;

    /// @notice Prevents the initialization of the implementation contract itself during deployment
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the contract
    /// @param owner The owner of the contract
    /// @param _maxFeeIncrement The maximum fee increment
    function initialize(address owner, uint32 _maxFeeIncrement) public initializer {
        if (_maxFeeIncrement == 0 || _maxFeeIncrement > MAX_PERCENTAGE) {
            revert IStorage.InvalidMaxFeeIncrement();
        }
        __Ownable_init(owner);
        __UUPSUpgradeable_init();
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
        if (percentage == 0 || percentage > MAX_PERCENTAGE) revert IStorage.InvalidPercentage();
        if (delegations[msg.sender][account] != 0) revert IStorage.DelegationAlreadyExists();
        if (totalDelegatedPercentage[msg.sender] + percentage > MAX_PERCENTAGE) {
            revert IStorage.ExceedingPercentageUpdate();
        }

        delegations[msg.sender][account] = percentage;
        totalDelegatedPercentage[msg.sender] += percentage;

        emit DelegationCreated(msg.sender, account, percentage);
    }

    /// @notice Function to update the delegated validator balance percentage to another account
    /// @param account The address of the account to delegate to
    /// @param percentage The updated percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function updateDelegatedBalance(address account, uint32 percentage) external {
        if (percentage == 0 || percentage > MAX_PERCENTAGE) revert IStorage.InvalidPercentage();

        uint32 existingPercentage = delegations[msg.sender][account];
        if (existingPercentage == percentage) revert IStorage.DelegationExistsWithSameValue();
        if (existingPercentage == 0) revert IStorage.DelegationDoesNotExist();

        uint32 newTotalPercentage = totalDelegatedPercentage[msg.sender] - existingPercentage + percentage;
        if (newTotalPercentage > MAX_PERCENTAGE) revert IStorage.ExceedingPercentageUpdate();

        delegations[msg.sender][account] = percentage;
        totalDelegatedPercentage[msg.sender] = newTotalPercentage;

        emit DelegationUpdated(msg.sender, account, percentage);
    }

    /// @notice Removes delegation from an account.
    /// @param account The address of the account whose delegation is being removed.
    function removeDelegatedBalance(address account) external {
        uint32 percentage = delegations[msg.sender][account];
        if (percentage == 0) revert IStorage.DelegationDoesNotExist();

        delete delegations[msg.sender][account];
        totalDelegatedPercentage[msg.sender] -= percentage;

        emit DelegationRemoved(msg.sender, account);
    }

    // ***********************
    // ** Section: Strategy **
    // ***********************

    /// @notice Function to create a new Strategy
    /// @param metadataURI The metadata URI of the strategy
    /// @return strategyId The ID of the new Strategy
    function createStrategy(uint32 fee, string calldata metadataURI) external returns (uint32 strategyId) {
        if (fee > MAX_PERCENTAGE) revert IStorage.InvalidStrategyFee();

        strategyId = ++_strategyCounter;

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

        _createObligations(strategyId, bApp, tokens, obligationPercentages);

        accountBAppStrategy[msg.sender][bApp] = strategyId;

        if (_isContract(bApp)) {
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

        strategyTokenBalances[strategyId][msg.sender][address(token)] += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit StrategyDeposit(strategyId, msg.sender, address(token), amount);
    }

    /// @notice Deposit ETH into the strategy
    /// @param strategyId The ID of the strategy
    function depositETH(uint32 strategyId) external payable {
        if (msg.value == 0) revert IStorage.InvalidAmount();

        strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] += msg.value;

        emit StrategyDeposit(strategyId, msg.sender, ETH_ADDRESS, msg.value);
    }

    /// @notice Withdraw ERC20 tokens from the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to withdraw
    function fastWithdrawERC20(uint32 strategyId, IERC20 token, uint256 amount) external nonReentrant {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (usedTokens[strategyId][address(token)] != 0) revert IStorage.TokenIsUsedByTheBApp();
        if (strategyTokenBalances[strategyId][msg.sender][address(token)] < amount) revert IStorage.InsufficientBalance();
        if (address(token) == ETH_ADDRESS) revert IStorage.InvalidToken();

        strategyTokenBalances[strategyId][msg.sender][address(token)] -= amount;

        token.safeTransfer(msg.sender, amount);

        emit StrategyWithdrawal(strategyId, msg.sender, address(token), amount, true);
    }

    /// @notice Withdraw ETH from the strategy
    /// @param strategyId The ID of the strategy
    /// @param amount The amount to withdraw
    function fastWithdrawETH(uint32 strategyId, uint256 amount) external nonReentrant {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (usedTokens[strategyId][ETH_ADDRESS] != 0) revert IStorage.TokenIsUsedByTheBApp();
        if (strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] < amount) revert IStorage.InsufficientBalance();

        strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] -= amount;

        payable(msg.sender).transfer(amount);

        emit StrategyWithdrawal(strategyId, msg.sender, ETH_ADDRESS, amount, true);
    }

    /// @notice Propose a withdrawal of ERC20 tokens from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    /// @param amount The amount to withdraw.
    function proposeWithdrawal(uint32 strategyId, address token, uint256 amount) external {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (strategyTokenBalances[strategyId][msg.sender][address(token)] < amount) revert IStorage.InsufficientBalance();
        if (token == ETH_ADDRESS) revert IStorage.InvalidToken();

        IStorage.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][address(token)];

        request.amount = amount;
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
        _checkTimelocks(requestTime, WITHDRAWAL_TIMELOCK_PERIOD, WITHDRAWAL_EXPIRE_TIME);

        uint256 amount = request.amount;
        strategyTokenBalances[strategyId][msg.sender][address(token)] -= amount;
        delete withdrawalRequests[strategyId][msg.sender][address(token)];

        token.safeTransfer(msg.sender, amount);

        emit StrategyWithdrawal(strategyId, msg.sender, address(token), amount, false);
    }

    /// @notice Propose an ETH withdrawal from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param amount The amount of ETH to withdraw.
    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external {
        if (amount == 0) revert IStorage.InvalidAmount();
        if (strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] < amount) revert IStorage.InsufficientBalance();

        IStorage.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][ETH_ADDRESS];

        request.amount = amount;
        request.requestTime = uint32(block.timestamp);

        emit StrategyWithdrawalProposed(strategyId, msg.sender, ETH_ADDRESS, amount);
    }

    /// @notice Finalize the ETH withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    function finalizeWithdrawalETH(uint32 strategyId) external nonReentrant {
        IStorage.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][ETH_ADDRESS];
        uint256 requestTime = request.requestTime;

        if (requestTime == 0) revert IStorage.NoPendingWithdrawalETH();
        _checkTimelocks(requestTime, WITHDRAWAL_TIMELOCK_PERIOD, WITHDRAWAL_EXPIRE_TIME);

        uint256 amount = request.amount;
        strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] -= amount;
        delete withdrawalRequests[strategyId][msg.sender][ETH_ADDRESS];

        payable(msg.sender).transfer(amount);

        emit StrategyWithdrawal(strategyId, msg.sender, ETH_ADDRESS, amount, false);
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
    }

    /// @notice Fast set obligation ratio higher for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    /// @dev The used tokens counter cannot be decreased as the fast update can only bring the percentage up
    function fastUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage)
        external
        onlyStrategyOwner(strategyId)
    {
        if (obligationPercentage <= obligations[strategyId][bApp][token].percentage) revert IStorage.InvalidPercentage();

        _validateObligationUpdateInput(strategyId, bApp, token, obligationPercentage);
        _updateObligation(strategyId, bApp, token, obligationPercentage);

        emit ObligationUpdated(strategyId, bApp, token, obligationPercentage, true);
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
        _checkTimelocks(requestTime, OBLIGATION_TIMELOCK_PERIOD, OBLIGATION_EXPIRE_TIME);

        if (percentage == 0 && obligations[strategyId][bApp][address(token)].percentage > 0) {
            usedTokens[strategyId][address(token)] -= 1;
        }

        _updateObligation(strategyId, bApp, address(token), percentage);

        emit ObligationUpdated(strategyId, bApp, address(token), percentage, false);

        delete obligationRequests[strategyId][bApp][address(token)];
    }

    /// @notice Instantly lowers the fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function fastUpdateFee(uint32 strategyId, uint32 proposedFee) external onlyStrategyOwner(strategyId) {
        if (proposedFee >= strategies[strategyId].fee) revert IStorage.InvalidPercentageIncrement();

        uint32 oldFee = strategies[strategyId].fee;
        strategies[strategyId].fee = proposedFee;

        emit StrategyFeeUpdated(strategyId, msg.sender, proposedFee, oldFee);
    }

    /// @notice Propose a new fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external onlyStrategyOwner(strategyId) {
        if (proposedFee > MAX_PERCENTAGE) revert IStorage.InvalidPercentage();

        IStorage.Strategy storage strategy = strategies[strategyId];
        uint32 fee = strategy.fee;

        if (proposedFee == fee) revert IStorage.FeeAlreadySet();
        if (proposedFee > fee + maxFeeIncrement) revert IStorage.InvalidPercentageIncrement();

        IStorage.FeeUpdateRequest storage request = feeUpdateRequests[strategyId];

        request.percentage = proposedFee;
        request.requestTime = uint32(block.timestamp);

        emit StrategyFeeUpdateProposed(strategyId, msg.sender, proposedFee, fee);
    }

    /// @notice Finalize the fee update for a strategy
    /// @param strategyId The ID of the strategy
    function finalizeFeeUpdate(uint32 strategyId) external onlyStrategyOwner(strategyId) {
        IStorage.Strategy storage strategy = strategies[strategyId];
        IStorage.FeeUpdateRequest storage request = feeUpdateRequests[strategyId];

        uint256 feeRequestTime = request.requestTime;

        if (feeRequestTime == 0) revert IStorage.NoPendingFeeUpdate();
        _checkTimelocks(feeRequestTime, FEE_TIMELOCK_PERIOD, FEE_EXPIRE_TIME);

        uint32 oldFee = strategy.fee;
        strategy.fee = request.percentage;
        delete request.percentage;
        delete request.requestTime;

        emit StrategyFeeUpdated(strategyId, msg.sender, strategy.fee, oldFee);
    }

    // **********************
    // ** Section: Helpers **
    // **********************

    /// @notice Set the obligation percentages for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to set obligations for
    /// @param obligationPercentages The list of obligation percentages for each token
    function _createObligations(
        uint32 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages
    ) private {
        for (uint8 i = 0; i < tokens.length; i++) {
            _createSingleObligation(strategyId, bApp, tokens[i], obligationPercentages[i]);
        }
    }

    /// @notice Set a single obligation for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function _createSingleObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) private {
        if (!bAppTokens[bApp][token].isSet) revert IStorage.TokenNoTSupportedByBApp(token);
        if (obligationPercentage > MAX_PERCENTAGE) revert IStorage.InvalidPercentage();
        if (obligations[strategyId][bApp][token].isSet) revert IStorage.ObligationAlreadySet();

        if (obligationPercentage != 0) {
            usedTokens[strategyId][token] += 1;
            obligations[strategyId][bApp][token].percentage = obligationPercentage;
        }

        obligations[strategyId][bApp][token].isSet = true;

        emit ObligationCreated(strategyId, bApp, token, obligationPercentage);
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
        if (obligationPercentage > MAX_PERCENTAGE) revert IStorage.InvalidPercentage();
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
}
