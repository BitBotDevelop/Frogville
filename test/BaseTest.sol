// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../contracts/interfaces/IERC20.sol";

abstract contract BaseTest is Test {
    
    receive() external payable {}
}