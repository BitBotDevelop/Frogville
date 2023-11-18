// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
// import "solmate/test/utils/mocks/MockERC20.sol";
import "../contracts/interfaces/IERC20.sol";

import "../contracts/Wolf.sol";
import "../contracts/Room.sol";

abstract contract BaseTest is Test {
    
    address public admin = address(9999);
    Wolf public WOLF_TOKEN;
    Room public room;

    function deployCoins() public {
        WOLF_TOKEN = new Wolf(admin);
    }

    function deployRoom() public {
        room = new Room(1000, 100, 10, address(WOLF_TOKEN), address(0));
    }
    receive() external payable {}
}