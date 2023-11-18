// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseTest.sol";
import "../contracts/interfaces/IERC20.sol";



contract RootTest is BaseTest {

    address public Alice = address(100);
    address public Bob = address(101); 

    function setUp() public {
        deployCoins();
        deployRoom();
    }

    //forge test --match-test test_buy_grass -vvv
    function test_buy_grass() public {
        
        vm.startPrank(admin);
        WOLF_TOKEN.mint(address(Alice), 100000);
        vm.stopPrank();


        vm.startPrank(address(Alice));
        WOLF_TOKEN.approve(address(room), 100000);
        room.buy(0, 1);
        vm.stopPrank();
    }
}