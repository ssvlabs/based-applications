// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {ValidationLib} from "@ssv/src/core/libraries/ValidationLib.sol";
import {Setup} from "@ssv/test/helpers/Setup.t.sol";

contract ValidationLibTest is Setup {
    function testValidatePercentage() public {
        ValidationLib.validatePercentage(0);
        ValidationLib.validatePercentage(1e4);
    }

    function testValidatePercentageWithZero() public {
        ValidationLib.validatePercentageAndNonZero(1e4);
    }
}
