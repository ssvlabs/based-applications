// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {SSVBasedApps} from "src/SSVBasedApps.sol";
import {IStrategyManager} from "@ssv/src/interfaces/IStrategyManager.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";
import {ISSVDAO} from "@ssv/src/interfaces/ISSVDAO.sol";
import {IBasedApp} from "@ssv/src/middleware/interfaces/IBasedApp.sol";
import {IERC20, ERC20Mock} from "@ssv/test/mocks/MockERC20.sol";
import {BasedAppMock} from "@ssv/test/mocks/MockBApp.sol";
import {BasedAppMock2} from "@ssv/test/mocks/MockBApp2.sol";
import {BasedAppMock3} from "@ssv/test/mocks/MockBAppAccessControl.sol";
import {NonCompliantBApp} from "@ssv/test/mocks/MockNonCompliantBApp.sol";
import {WhitelistExample} from "@ssv/src/middleware/examples/WhitelistExample.sol";
import {SSVDAO} from "@ssv/src/modules/SSVDAO.sol";
import {StrategyManager} from "@ssv/src/modules/StrategyManager.sol";
import {BasedAppsManager} from "@ssv/src/modules/BasedAppsManager.sol";
import {SlashingManager} from "@ssv/src/modules/SlashingManager.sol";
import {DelegationManager} from "@ssv/src/modules/DelegationManager.sol";
import {ISlashingManager} from "@ssv/src/interfaces/ISlashingManager.sol";
import {IDelegationManager} from "@ssv/src/interfaces/IDelegationManager.sol";

contract Setup is Test {
    // Main Contract
    SSVBasedApps public implementation;
    // Modules
    StrategyManager public strategyManagerMod;
    BasedAppsManager public basedAppsManagerMod;
    SSVDAO public ssvDAOMod;
    SlashingManager public slashingManagerMod;
    DelegationManager public delegationManagerMod;

    // Proxies
    ERC1967Proxy public proxy; // UUPS Proxy contract
    SSVBasedApps public proxiedManager; // Proxy interface for interaction
    // BApps
    BasedAppMock public bApp1;
    BasedAppMock2 public bApp2;
    BasedAppMock3 public bApp3;
    NonCompliantBApp public nonCompliantBApp;
    WhitelistExample public whitelistExample;
    // Tokens
    IERC20 public erc20mock;
    IERC20 public erc20mock2;
    IERC20 public erc20mock3;
    IERC20 public erc20mock4;
    IERC20 public erc20mock5;
    // EOAs
    address public immutable OWNER = makeAddr("Owner");
    address public immutable USER1 = makeAddr("User1");
    address public immutable USER2 = makeAddr("User2");
    address public immutable USER3 = makeAddr("User3");
    address public immutable NON_EXISTENT_BAPP = makeAddr("NonExistentBApp");
    address public immutable ATTACKER = makeAddr("Attacker");
    address public immutable RECEIVER = makeAddr("Receiver");
    address public immutable RECEIVER2 = makeAddr("Receiver2");
    // Strategies Ids
    uint32 public constant STRATEGY1 = 1;
    uint32 public constant STRATEGY2 = 2;
    uint32 public constant STRATEGY3 = 3;
    uint32 public constant STRATEGY4 = 4;
    // Fees
    uint32 public constant STRATEGY1_INITIAL_FEE = 5;
    uint32 public constant STRATEGY2_INITIAL_FEE = 0;
    uint32 public constant STRATEGY3_INITIAL_FEE = 1000;
    uint32 public constant STRATEGY4_INITIAL_FEE = 900;
    uint32 public constant STRATEGY1_UPDATE_FEE = 10;
    // Initial Balances
    uint256 public constant INITIAL_USER1_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 public constant INITIAL_USER1_BALANCE_ETH = 1_000_000 ether;
    uint256 public constant INITIAL_USER2_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 public constant INITIAL_USER2_BALANCE_ETH = 10 ether;
    uint256 public constant INITIAL_RECEIVER_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 public constant INITIAL_RECEIVER_BALANCE_ETH = 10 ether;
    uint256 public constant INITIAL_ATTACKER_BALANCE_ERC20 = 100_000_000 * 10 ** 18;
    uint256 public constant INITIAL_ATTACKER_BALANCE_ETH = 10 ether;
    uint256 public constant INITIAL_USER3_BALANCE_ERC20 = 1e51;
    uint256 public constant INITIAL_USER3_BALANCE_ETH = 1e51;
    // Constants
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint32 public constant MAX_FEE_INCREMENT = 500;
    // Array containing all the BApps created
    IBasedApp[] public bApps;

    function setUp() public virtual {
        vm.label(OWNER, "Owner");
        vm.label(USER1, "User1");
        vm.label(USER2, "User2");
        vm.label(ATTACKER, "Attacker");
        vm.label(RECEIVER, "Receiver");
        vm.label(RECEIVER2, "Receiver2");

        vm.startPrank(OWNER);
        basedAppsManagerMod = new BasedAppsManager();
        strategyManagerMod = new StrategyManager();
        ssvDAOMod = new SSVDAO();
        slashingManagerMod = new SlashingManager();
        delegationManagerMod = new DelegationManager();
        implementation = new SSVBasedApps();
        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            ISSVDAO(ssvDAOMod),
            ISlashingManager(slashingManagerMod),
            IDelegationManager(delegationManagerMod),
            MAX_FEE_INCREMENT
        );
        proxy = new ERC1967Proxy(address(implementation), data);
        proxiedManager = SSVBasedApps(payable(address(proxy)));
        assertEq(proxiedManager.getVersion(), "v0.0.0", "Version mismatch");
        assertEq(proxiedManager.maxFeeIncrement(), 500, "Initialization failed");
        vm.stopPrank();

        vm.startPrank(USER1);
        bApp1 = new BasedAppMock(address(proxiedManager), USER1);
        bApp2 = new BasedAppMock2(address(proxiedManager));
        bApp3 = new BasedAppMock3(address(proxiedManager), USER1);
        bApp3.hasRole(bApp3.OWNER_ROLE(), USER1);
        bApp3.hasRole(bApp3.MANAGER_ROLE(), USER1);
        bApp3.grantManagerRole(USER1);
        bApp3.hasRole(bApp3.MANAGER_ROLE(), USER1);
        vm.stopPrank();

        nonCompliantBApp = new NonCompliantBApp(address(proxiedManager));
        whitelistExample = new WhitelistExample(address(proxiedManager), USER1);

        bApps.push(bApp1);
        bApps.push(bApp2);
        bApps.push(bApp3);

        vm.startPrank(OWNER);
        vm.label(address(bApp1), "BasedApp1");
        vm.label(address(bApp2), "BasedApp2");
        vm.label(address(bApp3), "BasedApp3");
        vm.label(address(nonCompliantBApp), "NonCompliantBApp");
        vm.label(address(whitelistExample), "WhitelistExample");
        vm.label(address(proxiedManager), "BasedAppManagerProxy");

        vm.deal(USER1, INITIAL_USER1_BALANCE_ETH);
        vm.deal(USER2, INITIAL_USER2_BALANCE_ETH);
        vm.deal(USER3, INITIAL_USER3_BALANCE_ETH);
        vm.deal(RECEIVER, INITIAL_RECEIVER_BALANCE_ETH);
        vm.deal(ATTACKER, INITIAL_ATTACKER_BALANCE_ETH);

        erc20mock = new ERC20Mock();
        erc20mock2 = new ERC20Mock();
        erc20mock3 = new ERC20Mock();
        erc20mock4 = new ERC20Mock();
        erc20mock5 = new ERC20Mock();

        erc20mock.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock.transfer(USER2, INITIAL_USER2_BALANCE_ERC20);
        erc20mock.transfer(USER3, INITIAL_USER3_BALANCE_ERC20);
        erc20mock.transfer(ATTACKER, INITIAL_ATTACKER_BALANCE_ERC20);
        erc20mock.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        erc20mock2.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        vm.stopPrank();
    }
}
