# bApp Onboarding Guide

### [Intro]((../README.md)) | bApp Onboarding Guide 

This guide outlines the steps for based applications developers looking to build on the bApps platform.

## 1. Creating and Configuring a bApp

1. **Define core attributes**:
- `bApp`: a unique 20-byte EVM address that uniquely identifies the bApp.
- `tokens`:  A list of ERC-20 tokens to be used in the bApp's security mechanism. For the native ETH token, use the special address [`0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F1).
- `sharedRiskLevels`: a list of $\beta$ values, one for each token, representing the bApp's tolerance for risk (token over-usage). Each $\beta$ value ranges from 0 to 4,294.967295. Since it's encoded in as a `uint32`, its first six digits represent decimal places. For example, a stored value of 1_000_000 corresponds to a real value of 1.0.
2. **Optional Non-Slashable Validator Balance**: If the bApp uses non-slashable validator balance, it should be configured off-chain, in the bApp's network.
3. **Register the bApp**: Use the [`registerBApp`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F20) function of the smart contract:
```solidity
function registerBApp(
   address bApp,
   address[] calldata tokens,
   uint32[] calldata sharedRiskLevels,
   string calldata metadataURI
)
```
- `metadataURI`: A link to a JSON file containing additional details about your bApp, such as its name, description, logo, and website.
4. **Update Configuration**: After registering, the bApp configuration can be updated only by the `owner` account. Namely, more tokens can be added with [`addTokensToBApp`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F1), the tokens' shared risk levels updated with [`updateBAppTokens`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F24), and the metadata updated with [`updateMetadataURI`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F26).

## 2. Securing the bApp

Once the bApp is registered, strategies can join it and allocate capital to secure it.

### 2.1 Opting in

The strategy opts-in to the bApp by using the [`optInToBApp`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F15) function of the smart contract:
```solidity
function optInToBApp(
   uint256 strategyId,
   address bApp,
   address[] calldata tokens,
   uint32[] calldata obligationPercentages,
   bytes calldata data
)
```
- `tokens`: List of tokens to obligate to the bApp.
- `obligationPercentages`: The proportion of each token's balance to commit to the bApp. Though it's encoded as a uint32, its first two digits represent decimal places of a percentage value. For example, a stored value of 5000 corresponds to 50.00%.
- `data`: An extra optional field for off-chain information required by the bApp for participation.

For example, if `tokens = [SSV]` and `obligationPercentages = [50%]`, then 50% of the strategy's `SSV` balance will be obligated to the bApp.

The strategy’s owner can later update its obligations by modifying existing ones or adding a new token obligation. Obligations can be increased instantly ([`fastUpdateObligation`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F7)), but decreasing obligations requires a timelock ([`proposeUpdateObligation`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F17) → [`finalizeUpdateObligation`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F11)) to ensure slashable capital can’t be pulled out instantly.

### 2.2 Strategy's Funds

To compose their balances, strategies:
1. receive ERC20 (or ETH) via [**deposits**](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F5) from accounts.
2. inherit the non-slashable validator balance from its owner account. Accounts [**delegate**](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#writeProxyContract#F4) validator balances between themselves, and the strategy inherits all balances delegated to its owner.

If a token is allocated to a bApp ([`usedTokens[strategyId][token] != 0`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F22)), accounts need to propose a withdrawal and wait a timelock before finalizing it, ensuring the slashable collateral cannot be removed instantly.

## 3. Participant Weight

bApp clients track the weight of each participant in the bApp. For that, clients will:

1. **Gather Obligated Balances**: First, for each token used by the bApp, it should get the obligated balance from each strategy.
```go
ObligatedBalance mapping(Token -> Strategy -> Amount)
```
2. **Sum Obligations**: From `ObligatedBalance`, it can sum all obligations and compute the total amount obligated to the bApp by all strategies.
```go
TotalBAppBalance mapping(Token -> Amount)
```
3. **Calculate Risk**: For each token, it should get the risk (token-over usage) of each strategy.
```go
Risk mapping(Token -> Strategy -> Float)
```
4. **Compute Risk-Aware Weights**: With this information, it can compute the weight of a participant for a certain token by

$$W_{\text{strategy, token}} = c_{\text{token}} \times \frac{ObligatedBalance[\text{token}][\text{strategy}]}{TotalBAppBalance[\text{token}]} e^{-\beta_{\text{token}} \times max(1, Risk[\text{token}][\text{strategy}])}$$

where $c_{\text{token}}$ is a normalization constant defined as

$$c_{\text{token}} = \left( \sum_{\text{strategy}} \frac{ObligatedBalance[\text{token}][\text{strategy}]}{TotalBAppBalance[\text{token}]} e^{-\beta_{\text{token}} \times max(1, Risk[\text{token}][\text{strategy}])} \right)^{-1}$$


> [!NOTE]
> If the bApp uses validator balance, the client should also read a `map[Strategy]ValidatorBalance` with the amount from each strategy. As this capital doesn't involve any type of risk, all risk values can be set to 0. Thus, for this capital, this is equivalent to
> $$W_{\text{strategy, validator balance}} = \frac{ObligatedBalance[\text{validator balance}][\text{strategy}]}{TotalBAppBalance[\text{validator balance}]}$$


5. **Combine into the Final Weight**: With the per-token weights, the final step is to compute a final weight for the participant using a **combination function**. Such function is defined by the bApp and can be tailored to its specific needs. Traditional examples include the arithmetic mean, geometric mean, and harmonic mean.


**Example**: Let's consider a bApp that uses tokens $A$ and $B$, and considers $A$ to be twice as important as $B$. Then, it could use the following weighted harmonic mean as its combination function:

$$W_{\text{strategy}}^{\text{final}} = c_{\text{final}} \times \frac{1}{\frac{2/3}{W_{\text{strategy, A}}} + \frac{1/3}{W_{\text{strategy, B}}}}$$

where $c_{\text{final}}$ is a normalization constant computed as

$$c_{\text{final}} = \left( \sum_{\text{strategy}} \frac{1}{\frac{2/3}{W_{\text{strategy, A}}} + \frac{1/3}{W_{\text{strategy, B}}}} \right)^{-1}$$


### 3.1 Fecthing obligated balances, validator balances, and risks

In this subsection, we detail how the data for computing the participants' weights can be read from the chain state.

**Map of obligation balances**

```r
function ObligatedBalances(bApp)
   obligatedBalances = New(Map<Token, Map<Strategy, Amount>>)

   # Get bApp tokens
   bAppTokens = api.GetbAppTokens(bApp)

   # Loop through every strategy
   strategies = api.GetStrategies()
   for strategy in strategies do

      # Check if strategy participates in the bApp
      ownerAccount := api.GetStrategyOwnerAccount(strategy)
      if api.GetStrategyOptedInToBApp(ownerAccount, bApp) != strategy then
         # If not, continue
         continue

      # Get strategy balance
      balance = api.GetStrategyBalance(strategy)

      # Add obligated balance for each bApp token
      for token in bAppTokens do
         obligationPercentage = api.GetObligation(strategy, bApp, token)
         obligatedBalances[token][strategy] = obligationPercentage * balance[token]

   return obligatedBalances
```

**Map of validator balances**

```r
function ValidatorBalances(bApp)
   validatorBalances = New(Map<Strategy, Amount>)

   # Loop through every strategy
   strategies = api.GetStrategies()
   for strategy in strategies do

      # Get account that owns the strategy
      ownerAccount = api.GetStrategyOwnerAccount(strategy)

      # Check if strategy participates in the bApp
      if api.GetStrategyOptedInToBApp(ownerAccount, bApp) != strategy then
         # If not, continue
         continue

      # Store validator balance
      validatorBalances[strategy] = ComputeEffectiveValidatorBalance(ownerAccount)

   return obligatedBalances


function ComputeEffectiveValidatorBalance(account)

   total = 0

   # Get all other accounts that delegated to it along with the percentages
   delegatorsToAccount = New(Map<Account, Percentage>)
   delegatorsToAccount = api.GetDelegatorsToAccount(account)

   # Add the delegated balances
   for delegator, percentage in delegatorsToAccount
      total += GetOriginalValidatorBalance(delegator) * percentage

   return total


function GetOriginalValidatorBalance(account)

   total = 0

   # Get SSV validators from account
   validatorsPubKeys = SSVNode.GetValidatorsPubKeys(account)

   for PubKey in validatorsPubKeys
      # Get validator balance and active status
      balance, isActive = ETHNode.GetValidatorBalance(PubKey)

      if isActive
         total += balance

   return total
```

**Map of risks**

```r
function Risks(bApp)
   risks = New(Map<Token, Map<Strategy, Percentage>>)

   # Get bApp tokens
   bAppTokens = api.GetbAppTokens(bApp)

   # Loop through every strategy
   strategies = api.GetStrategies()
   for strategy in strategies do

      # Check if strategy participates in the bApp
      ownerAccount := api.GetStrategyOwnerAccount(strategy)
      if api.GetStrategyOptedInToBApp(ownerAccount, bApp) != strategy then
         # If not, continue
         continue

      # Store risk (i.e. sum of all obligation percentages)
      risks[token][strategy] = api.AddAllObligationsForToken(strategy, token)

   return risks
```

**API Calls**

For reference, we list the API calls used in the above snippets along with the chain state variables that should be read for each call:
- `GetbAppTokens(bApp)`: [`bAppTokens`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F12)
- `GetStrategies()`: [`strategies`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F19)
- `GetStrategyOptedInToBApp(account, bApp)`: [`accountBAppStrategy`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F10)
- `GetStrategyBalance(strategy)`: [`strategyTokenBalances`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F20)
- `GetObligation(strategy, bApp, token)`: [`obligations`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F16)
- `GetStrategyOwnerAccount(strategy)`: [`strategies`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F19)
- `GetTotalDelegation(account)`: [`totalDelegatedPercentage`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F21)
- `GetDelegatorsToAccount(account)`: [`delegations`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A#readProxyContract#F13)


## Appendix

## Numerical example for participant weight

### 1. BApp Configuration

Consider a bApp with the following configuration:

| Configuration                | Value              |
|------------------------------|--------------------|
| `Tokens`                     | [SSV]              |
| `SharedRiskLevels` ($\beta$) | [2]                |
| Uses validator balance       | True |
| Final weight combination function       | $W_{\text{strategy}}^{\text{final}} = c_{\text{final}} \times \frac{1}{\frac{2/3}{W_{\text{strategy, SSV}}} + \frac{1/3}{W_{\text{strategy, VB}}}}$ |

This setup means:
- The only slashable token in use is SSV, with $\beta = 2$.
- Validator balance is included in the model.
- The combination function is a harmonic mean, where SSV carries twice the weight of validator balance.


### 2. Strategies securing the bApp

The following strategies have opted-in to the bApp:

| Strategy | SSV Balance | SSV Obligation | Risk for SSV token | Validator Balance |
|----------|-------------|----------------|--------------------|-------------------|
| 1        | 100         | 50%            | 1.5 (150%)               | 32                |
| 2        | 200         | 10%            | 1 (100%)                | 96                |

The obligated balances are:
- Strategy 1: $100 * 50\% = 50$ SSV
- Strategy 2: $200 * 10\% = 20$ SSV

Thus, in total, the bApp has:
- $50 + 20 = 70$ SSV
- $32 + 96 = 128$ validator balance

### 3.1 Weight for SSV

First, compute the normalization constant for the SSV token:

$$c_{\text{SSV}} = \left( \frac{50}{70}\times e^{-\beta_{\text{SSV}} \times max(1, 1.5)} + \frac{20}{70}\times e^{-\beta_{\text{SSV}} \times max(1, 1)} \right)^{-1} \approx 13.47$$

Using this coefficient, we can compute the weights:

$$W_{1, \text{SSV}} = c_{\text{SSV}} \times \frac{50}{70} \times e^{-\beta_{\text{SSV}} \times max(1, 1.5)} = 0.479$$

$$W_{2, \text{SSV}} = c_{\text{SSV}} \times \frac{20}{70} \times e^{-\beta_{\text{SSV}} \times max(1, 1)} = 0.521$$

Thus, the weights for the SSV token are:
- Strategy 1: 47.9%
- Strategy 2: 52.1%

Note that, despite Strategy 1 obligating $50/70 \approx 71\%$ of the total SSV, its weight drops to $47.9\%$ due to its higher risk.

### 3.2 Weight for Validator Balance

For validator balance:

$$c_{\text{VB}} = \left( \frac{32}{128} + \frac{96}{128}\right)^{-1} = 1$$

$$W_{1, \text{VB}} = c_{\text{VB}} \times \frac{32}{128} = 0.25$$

$$W_{2, \text{VB}} = c_{\text{VB}} \times \frac{96}{128} = 0.75$$

Thus, the validator balance weights are:
- Strategy 1: 25%
- Strategy 2: 75%

Since validator balance carries no risk, it remains proportional to the amount contributed.

### 3.3 Final Weight

Using the harmonic mean combination, we have:

$$c_{\text{final}} = \left( \frac{1}{\frac{2/3}{W_{\text{1, SSV}}} + \frac{1/3}{W_{\text{1, VB}}}} + \frac{1}{\frac{2/3}{W_{\text{2, SSV}}} + \frac{1/3}{W_{\text{2, VB}}}} \right)^{-1} \approx 1.05$$

$$W_1^{\text{final}} = c_{\text{final}} \times \left( \frac{1}{\frac{2/3}{W_{\text{1, SSV}}} + \frac{1/3}{W_{\text{1, VB}}}} \right) = 0.387$$

$$W_2^{\text{final}} = c_{\text{final}} \times \left( \frac{1}{\frac{2/3}{W_{\text{2, SSV}}} + \frac{1/3}{W_{\text{2, VB}}}} \right) = 0.613$$

Thus, the final weights are:
- Strategy 1: 38.7%
- Strategy 2: 61.3%
