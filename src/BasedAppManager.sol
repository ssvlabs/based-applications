// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ICore.sol";
import "./interfaces/IBasedAppManager.sol";

/**
 * @title BasedAppManager
 * @notice Core contract to manage strategies, services, and obligations for SSV Based Apps.
 *
 * **************
 * ** GLOSSARY **
 * **************
 * @dev The following terms are used throughout the contract:
 *
 * - **Account**: An Ethereum address that can:
 *   1. Delegate its balance to another address.
 *   2. Create a strategy.
 *   3. Create a service.
 *
 * - **Delegator**: An Ethereum address that delegates its balance to a receiver.
 *   The delegator can be equal to the receiver, meaning the delegator delegates its balance to itself.
 *
 * - **Strategy**: A component that manages the delegated ERC20 tokens and has obligations to services.
 *
 * - **Obligation**: A percentage of the strategy's balance in ERC20 (or ETH) that is reserved for securing a service.
 *
 * - **Service**: Accountable Validator Service (AVS).
 *   A service is an entity that requests validation from strategies, requiring a minimum balance to operate.
 *
 * *************
 * ** AUTHORS **
 * *************
 * @author
 * Marco Tabasco
 * Riccardo Persiani
 */
contract BasedAppManager is Initializable, OwnableUpgradeable, UUPSUpgradeable, IBasedAppManager {
    using SafeERC20 for IERC20;

    uint32 public constant MAX_PERCENTAGE = 1e4;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant FEE_TIMELOCK_PERIOD = 7 days;
    uint256 public constant WITHDRAWAL_TIMELOCK_PERIOD = 5 days;
    uint256 public constant OBLIGATION_TIMELOCK_PERIOD = 7 days;
    uint256 public constant WITHDRAWAL_EXPIRE_TIME = 1 days;
    uint256 public constant FEE_EXPIRE_TIME = 1 days;
    uint256 public constant OBLIGATION_EXPIRE_TIME = 1 days;
    uint32 public constant MAX_INCREMENT = 500; // 5% // TODO set in the constructor...

    uint256 private _strategyCounter;

    /**
     * @notice Tracks the strategies created
     * @dev The strategy ID is incremental and unique
     */
    mapping(address service => ICore.Service) public services;
    /**
     * @notice Tracks the strategies created
     * @dev The strategy ID is incremental and unique
     */
    mapping(uint256 strategyId => ICore.Strategy) public strategies;
    /**
     * @notice Links an account to a single strategy for a specific service
     * @dev Guarantees that an account cannot have more than one strategy for a given service
     */
    mapping(address account => mapping(address service => uint256 strategyId)) public accountServiceStrategy;
    /**
     * @notice Tracks the percentage of validator balance a delegator has delegated to a specific receiver
     * @dev Each delegator can allocate a portion of their validator balance to multiple accounts including itself
     */
    mapping(address delegator => mapping(address account => uint32 percentage)) public delegations;
    /**
     * @notice Tracks the total percentage of validator balance a delegator has delegated across all receivers
     * @dev Ensures that a delegator cannot delegate more than 100% of their validator balance
     */
    mapping(address delegator => uint32 totalPercentage) public totalDelegatedPercentage;
    /**
     * @notice Tracks the token balances for individual strategies.
     * @dev Tracks that how much a token account has in a specific strategy
     */
    mapping(uint256 strategyId => mapping(address account => mapping(address token => uint256 balance))) public
        strategyTokenBalances;
    /**
     * @notice Tracks obligation percentages for a strategy based on specific services and tokens.
     * @dev Uses a hash of the service and token to map the obligation percentage for the strategy.
     */
    mapping(uint256 strategyId => mapping(address service => mapping(address token => uint32 obligationPercentage)))
        public obligations;
    /**
     * @notice Tracks unallocated tokens in a strategy.
     * @dev Count the number of services that have one obligation set for the token.
     * If the counter is 0, the token is unused and we can allow fast withdrawal.
     */
    mapping(uint256 strategyId => mapping(address token => uint32 servicesCounter)) public usedTokens;
    /**
     * @notice Tracks all the withdrawal requests divided by token per strategy.
     * @dev User can have only one pending withdrawal request per token.
     *  Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint256 strategyId => mapping(address account => mapping(address token => ICore.WithdrawalRequest))) public
        withdrawalRequests;
    /**
     * @notice Tracks all the obligation change requests divided by token per strategy.
     * @dev Strategy can have only one pending obligation change request per token.
     * Only the strategy owner can submit one.
     * Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint256 strategyId => mapping(address token => mapping(address service => ICore.ObligationRequest))) public
        obligationRequests;

    mapping(uint256 strategyId => mapping(address service => uint32 numberOfObligations)) public obligationsCounter;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // *****************************************
    // ** Section: Delegate Validator Balance **
    // *****************************************

    /// @notice Function to delegate a percentage of the account's balance to another account
    /// @param receiver The address of the account to delegate to
    /// @param percentage The percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function delegateBalance(address receiver, uint32 percentage) external {
        require(percentage > 0 && percentage <= MAX_PERCENTAGE, "Invalid percentage");

        require(delegations[msg.sender][receiver] == 0, "Delegation already exists");

        require(totalDelegatedPercentage[msg.sender] + percentage <= MAX_PERCENTAGE, "Total percentage exceeds 100%");

        delegations[msg.sender][receiver] = percentage;
        totalDelegatedPercentage[msg.sender] += percentage;

        emit DelegatedBalance(msg.sender, receiver, percentage);
    }

    /// @notice Function to update the delegated validator balance percentage to another account
    /// @param receiver The address of the account to delegate to
    /// @param percentage The updated percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function updateDelegatedBalance(address receiver, uint32 percentage) external {
        require(percentage > 0 && percentage <= MAX_PERCENTAGE, "Invalid percentage");

        uint32 existingPercentage = delegations[msg.sender][receiver];
        require(existingPercentage > 0, "Delegation does not exist");

        uint32 newTotalPercentage = totalDelegatedPercentage[msg.sender] - existingPercentage + percentage;
        require(newTotalPercentage <= MAX_PERCENTAGE, "Percentage exceeds 100%");

        delegations[msg.sender][receiver] = percentage;
        totalDelegatedPercentage[msg.sender] = newTotalPercentage;

        emit DelegatedBalance(msg.sender, receiver, percentage);
    }

    /// @notice Function to remove delegation from an account
    /// @param receiver The address of the account to remove delegation from
    function removeDelegatedBalance(
        address receiver
    ) external {
        uint32 percentage = delegations[msg.sender][receiver];
        require(percentage > 0, "No delegation exists");

        // Clear delegation
        delegations[msg.sender][receiver] = 0;
        totalDelegatedPercentage[msg.sender] -= percentage;

        emit RemoveDelegatedBalance(msg.sender, receiver);
    }

    // ********************
    // ** Section: bApps **
    // ********************

    /// @notice Function to register a service
    /// @param owner The address of the owner
    /// @param serviceAddress The address of the service
    /// @param tokens The list of tokens the service accepts
    /// @param sharedRiskLevel The shared risk level of the service
    /// @param slashingCorrelationPenalty The slashing correlation penalty of the service
    function registerService(
        address owner,
        address serviceAddress,
        address[] calldata tokens,
        uint32 sharedRiskLevel,
        uint32 slashingCorrelationPenalty
    ) external {
        ICore.Service storage service = services[serviceAddress];
        require(service.owner == address(0), "Service already registered");
        service.owner = owner;
        service.sharedRiskLevel = sharedRiskLevel;
        service.slashingCorrelationPenalty = slashingCorrelationPenalty;

        for (uint256 i = 0; i < tokens.length; i++) {
            service.tokens.push(tokens[i]);
        }

        emit ServiceRegistered(serviceAddress, owner, msg.sender);
    }

    /// @notice Function to add tokens to a service
    /// @param serviceAddress The address of the service
    /// @param tokens The list of tokens to add
    function addTokensToService(address serviceAddress, address[] calldata tokens) external {
        ICore.Service storage service = services[serviceAddress];
        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = 0; j < service.tokens.length; j++) {
                if (service.tokens[j] == tokens[i]) {
                    revert("Token already added");
                }
            }
            service.tokens.push(tokens[i]);
        }
        emit ServiceTokensUpdated(serviceAddress, tokens);
    }

    /// @notice Function to get the tokens for a service
    /// @param serviceAddress The address of the service
    function getServiceTokens(
        address serviceAddress
    ) external view returns (address[] memory) {
        return services[serviceAddress].tokens;
    }

    // ***********************
    // ** Section: Strategy **
    // ***********************

    /// @notice Function to create a new Strategy
    /// @return strategyId The ID of the new Strategy
    function createStrategy(
        uint32 fee
    ) external returns (uint256 strategyId) {
        require(fee > 0 && fee <= MAX_PERCENTAGE, "Invalid delegation fee");
        strategyId = ++_strategyCounter;

        // Create the strategy struct
        ICore.Strategy storage newStrategy = strategies[strategyId];
        newStrategy.owner = msg.sender;
        newStrategy.fee = fee;

        strategies[strategyId] = newStrategy;

        emit StrategyCreated(strategyId, msg.sender);
    }

    /// @notice Opt-in to a service with a list of tokens and obligation percentages
    /// @param strategyId The ID of the strategy
    /// @param service The address of the service
    /// @param tokens The list of tokens to opt-in with
    /// @param obligationPercentages The list of obligation percentages for each token
    function optInToService(
        uint256 strategyId,
        address service,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages
    ) external {
        require(tokens.length == obligationPercentages.length, "Strategy: tokens and percentages length mismatch");

        ICore.Service storage existingService = services[service];
        matchTokens(tokens, existingService.tokens);

        uint256 existingStrategyId = accountServiceStrategy[msg.sender][service];
        require(existingStrategyId == 0, "Strategy: already opted-in to this service");

        ICore.Strategy storage strategy = strategies[strategyId];
        require(strategy.owner == msg.sender, "Strategy: not the owner");

        emit ServiceOptedIn(strategyId, service);

        _setObligations(strategyId, service, tokens, obligationPercentages);

        accountServiceStrategy[msg.sender][service] = strategyId;
    }

    /// @notice Deposit ERC20 tokens into the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to deposit
    function depositERC20(uint256 strategyId, IERC20 token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        strategyTokenBalances[strategyId][msg.sender][address(token)] += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit StrategyDeposit(strategyId, msg.sender, address(token), amount);
    }

    /// @notice Withdraw ERC20 tokens from the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to withdraw
    function fastWithdrawERC20(uint256 strategyId, IERC20 token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        require(usedTokens[strategyId][address(token)] == 0, "Token is used by a service");

        uint256 contributorBalance = strategyTokenBalances[strategyId][msg.sender][address(token)];
        require(contributorBalance >= amount, "Insufficient balance");

        strategyTokenBalances[strategyId][msg.sender][address(token)] -= amount;

        token.safeTransfer(msg.sender, amount);

        emit StrategyWithdrawal(strategyId, msg.sender, address(token), amount);
    }

    /**
     * @notice Propose a withdrawal of ERC20 tokens from the strategy.
     * @param strategyId The ID of the strategy.
     * @param token The ERC20 token address.
     * @param amount The amount to withdraw.
     */
    function proposeWithdrawal(uint256 strategyId, address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        uint256 accountBalance = strategyTokenBalances[strategyId][msg.sender][address(token)];

        require(accountBalance >= amount, "Insufficient balance");

        ICore.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][address(token)];

        request.amount = amount;
        request.requestTime = block.timestamp;

        emit WithdrawalProposed(
            strategyId, msg.sender, address(token), amount, block.timestamp + WITHDRAWAL_TIMELOCK_PERIOD
        );
    }

    /**
     * @notice Finalize the withdrawal after the timelock period has passed.
     * @param strategyId The ID of the strategy.
     * @param token The ERC20 token address.
     */
    function finalizeWithdrawal(uint256 strategyId, IERC20 token) external {
        ICore.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][address(token)];
        require(request.requestTime > 0, "No pending withdrawal");
        require(block.timestamp >= request.requestTime + WITHDRAWAL_TIMELOCK_PERIOD, "Timelock not elapsed");
        require(block.timestamp <= request.requestTime + WITHDRAWAL_EXPIRE_TIME, "Withdrawal expired");

        uint256 amount = request.amount;

        strategyTokenBalances[strategyId][msg.sender][address(token)] -= amount;

        delete withdrawalRequests[strategyId][msg.sender][address(token)];

        token.safeTransfer(msg.sender, amount);

        emit WithdrawalFinalized(strategyId, msg.sender, address(token), amount);
    }

    // TODO: add eth proposeWithdrawal and finalizeWithdrawal

    /// @notice Deposit ETH into the strategy
    /// @param strategyId The ID of the strategy
    function depositETH(
        uint256 strategyId
    ) external payable {
        require(msg.value > 0, "Amount must be greater than zero");

        strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] += msg.value;

        emit StrategyDeposit(strategyId, msg.sender, ETH_ADDRESS, msg.value);
    }

    /// @notice Withdraw ETH from the strategy
    /// @param strategyId The ID of the strategy
    /// @param amount The amount to withdraw
    function fastWithdrawETH(uint256 strategyId, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        require(usedTokens[strategyId][ETH_ADDRESS] == 0, "ETH is used by a service");

        uint256 contributorBalance = strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS];
        require(contributorBalance >= amount, "Insufficient balance");

        strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] -= amount;

        payable(msg.sender).transfer(amount);

        emit StrategyWithdrawal(strategyId, msg.sender, ETH_ADDRESS, amount);
    }

    /// @notice Set the obligation percentages for a strategy
    /// @param strategyId The ID of the strategy
    /// @param service The address of the service
    /// @param tokens The list of tokens to set obligations for
    /// @param obligationPercentages The list of obligation percentages for each token
    function _setObligations(
        uint256 strategyId,
        address service,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages
    ) private {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint32 obligationPercentage = obligationPercentages[i];
            require(obligationPercentage > 0 && obligationPercentage <= 1e4, "ODP: invalid obligation percentage");

            obligations[strategyId][service][token] = obligationPercentage;
            obligationsCounter[strategyId][service] += 1;

            usedTokens[strategyId][token] += 1;
            emit ServiceObligationSet(strategyId, service, token, obligationPercentage);
        }
    }

    /// @notice Add a new obligation for a service
    /// @param strategyId The ID of the strategy
    /// @param service The address of the service
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function createObligation(
        uint256 strategyId,
        address service,
        address token,
        uint32 obligationPercentage
    ) external {
        require(strategies[strategyId].owner == msg.sender, "Not the strategy owner");
        require(obligationPercentage > 0 && obligationPercentage <= 1e4, "Invalid obligation percentage");
        require(obligations[strategyId][service][token] == 0, "Obligation already set");
        require(obligationsCounter[strategyId][service] > 0, "Service not opted-in");

        matchToken(token, services[service].tokens);

        obligations[strategyId][service][token] = obligationPercentage;
        accountServiceStrategy[msg.sender][service] = strategyId;
        usedTokens[strategyId][token] += 1;
        obligationsCounter[strategyId][service] += 1;

        emit ServiceObligationSet(strategyId, service, token, obligationPercentage);
    }

    /// @notice Fast set obligation ratio higher for a service
    /// @param strategyId The ID of the strategy
    /// @param service The address of the service
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function fastUpdateObligation(
        uint256 strategyId,
        address service,
        address token,
        uint32 obligationPercentage
    ) external {
        require(strategies[strategyId].owner == msg.sender, "Not the strategy owner");
        require(obligationPercentage > 0 && obligationPercentage <= 1e4, "Invalid obligation percentage");
        require(
            obligationPercentage > obligations[strategyId][service][token], "Percentage must be greater for fast update"
        );

        obligations[strategyId][service][token] = obligationPercentage;

        emit ServiceObligationUpdated(strategyId, service, token, obligationPercentage);
    }

    /// @notice Remove obligation for a service
    /// @param strategyId The ID of the strategy
    /// @param service The address of the service
    /// @param token The address of the token
    function fastRemoveObligation(uint256 strategyId, address service, address token) external {
        require(strategies[strategyId].owner == msg.sender, "Not the strategy owner");
        require(obligations[strategyId][service][token] > 0, "Obligation not set");

        for (uint256 i = 0; i < services[service].tokens.length; i++) {
            if (services[service].tokens[i] == token) {
                revert("token is used by the service");
            }
        }

        obligations[strategyId][service][token] = 0;
        usedTokens[strategyId][token] -= 1;
        obligationsCounter[strategyId][service] -= 1;

        emit ServiceObligationUpdated(strategyId, service, token, 0);
        // todo: create a new event for removedObligation?
    }

    /**
     * @notice Propose a withdrawal of ERC20 tokens from the strategy.
     * @param strategyId The ID of the strategy.
     * @param token The ERC20 token address.
     * @param obligationPercentage The new percentage of the obligation
     */
    function proposeUpdateObligation(
        uint256 strategyId,
        address service,
        address token,
        uint32 obligationPercentage
    ) external {
        require(strategies[strategyId].owner == msg.sender, "Not the strategy owner");
        require(obligationPercentage <= 10_000, "Percentage must lower than 100%");

        ICore.ObligationRequest storage request = obligationRequests[strategyId][service][token];

        request.percentage = obligationPercentage;
        request.requestTime = block.timestamp;

        emit ObligationUpdateProposed(
            strategyId, msg.sender, address(token), obligationPercentage, block.timestamp + OBLIGATION_TIMELOCK_PERIOD
        );
    }

    /**
     * @notice Finalize the withdrawal after the timelock period has passed.
     * @param strategyId The ID of the strategy.
     * @param service The address of the service.
     * @param token The ERC20 token address.
     */
    function finalizeUpdateObligation(uint256 strategyId, address service, address token) external {
        require(strategies[strategyId].owner == msg.sender, "Not the strategy owner");

        ICore.ObligationRequest storage request = obligationRequests[strategyId][service][address(token)];
        require(request.requestTime > 0, "No pending update");
        require(block.timestamp >= request.requestTime + OBLIGATION_TIMELOCK_PERIOD, "Timelock not elapsed");
        require(block.timestamp <= request.requestTime + OBLIGATION_EXPIRE_TIME, "Update expired");

        // Remove the obligation if the percentage is 0
        if (request.percentage == 0) {
            usedTokens[strategyId][address(token)] -= 1;
            obligationsCounter[strategyId][service] -= 1;
        }

        obligations[strategyId][msg.sender][address(token)] = request.percentage;

        emit ObligationUpdateFinalized(strategyId, msg.sender, address(token), request.percentage);
    }

    /// @notice Propose a new fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function proposeFeeUpdate(uint256 strategyId, uint32 proposedFee) external {
        require(strategies[strategyId].owner == msg.sender, "Not the strategy owner");
        require(proposedFee > 0 && proposedFee <= 1e4, "Invalid fee");
        ICore.Strategy storage strategy = strategies[strategyId];

        // Enforce the maximum increment rule
        require(proposedFee <= strategy.fee + MAX_INCREMENT, "Fee increase exceeds max increment");

        strategy.feeProposed = proposedFee;
        require(proposedFee != strategy.fee, "Fee already set");
        strategy.feeUpdateTime = block.timestamp + FEE_TIMELOCK_PERIOD;

        emit StrategyFeeUpdateRequested(strategyId, msg.sender, proposedFee, strategy.fee, strategy.feeUpdateTime);
    }

    /// @notice Finalize the fee update for a strategy
    /// @param strategyId The ID of the strategy
    function finalizeFeeUpdate(
        uint256 strategyId
    ) external {
        ICore.Strategy storage strategy = strategies[strategyId];
        require(strategy.owner == msg.sender, "Not the strategy owner");
        require(strategy.feeProposed > 0, "No fee proposed");
        require(block.timestamp >= strategy.feeUpdateTime, "Timelock not passed");
        require(block.timestamp <= strategy.feeUpdateTime + FEE_EXPIRE_TIME, "Fee update expired");

        uint32 oldFee = strategy.fee;
        strategy.fee = strategy.feeProposed;
        strategy.feeProposed = 0;
        strategy.feeUpdateTime = 0;

        emit StrategyFeeUpdated(strategyId, msg.sender, strategy.fee, oldFee);
    }

    // **********************
    // ** Section: Helpers **
    // **********************

    // Match the tokens of strategy with the service
    // Complexity: O(n * m)
    function matchTokens(address[] calldata tokens, address[] storage serviceTokens) internal view {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            matchToken(token, serviceTokens);
        }
    }

    function matchToken(address token, address[] storage serviceTokens) internal view {
        for (uint256 i = 0; i < serviceTokens.length; i++) {
            bool matched = false;
            address serviceToken = serviceTokens[i];
            if (serviceToken == token) {
                matched = true;
                break;
            }
            require(matched == true, "Strategy: token not supported by service");
        }
    }
}
