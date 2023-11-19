// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseTest.sol";
import "../contracts/interfaces/IERC20.sol";
import "../contracts/Room.sol";


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

        room.setGenCoordinateMocked(1, 1);

        vm.startPrank(address(Alice));
        WOLF_TOKEN.approve(address(room), 100000);
        room.buy(0, 2);
        vm.stopPrank();

        uint32 grassNum = room.getOwnerOfSpecieNum(0, address(Alice));
        console.log("grassNum %d", grassNum);
        assertEq(grassNum, 2);

        uint32[] memory grasses = room.getSpecieIdsAt(0, 1, 1);
        for (uint32 i = 0; i < grasses.length; i++) {
            console2.log("grasses[%s] %d", i, grasses[i]);
        }

        (int16 _x, int16 _y, address _owner, uint32 _id, uint32 _bornTime, uint32 _updateTime, uint256 _value) = room.getGrass(3);
        console2.log("x %s", _x);
        console2.log("y %s", _y);
        console2.log("address %s", _owner);
        console2.log("id %s", _id);
        console2.log("bornTime %s", _bornTime);
        console2.log("updateTime %s", _updateTime);
        console2.log("value %s", _value);
    }

    //forge test --match-test test_buy_sheep -vvv
    function test_buy_sheep() public {
        
        vm.startPrank(admin);
        WOLF_TOKEN.mint(address(Alice), 100000);
        vm.stopPrank();

        room.setGenCoordinateMocked(1, 1);

        vm.startPrank(address(Alice));
        WOLF_TOKEN.approve(address(room), 100000);
        room.buy(1, 2);
        vm.stopPrank();

        uint32 sheepNum = room.getOwnerOfSpecieNum(1, address(Alice));
        console.log("sheepNum %d", sheepNum);
        assertEq(sheepNum, 2);

        uint32[] memory sheeps = room.getSpecieIdsAt(1, 1, 1);
        for (uint32 i = 0; i < sheeps.length; i++) {
            console2.log("sheeps[%s] %d", i, sheeps[i]);
        }

        (int16 _x, int16 _y, address _owner, uint32 _id, uint32 _blood, uint32 _bornTime, uint32 _updateTime, uint256 _value) = room.getSheep(2);
        console2.log("x %s", _x);
        console2.log("y %s", _y);
        console2.log("address %s", _owner);
        console2.log("id %s", _id);
        console2.log("blood %s", _blood);
        console2.log("bornTime %s", _bornTime);
        console2.log("updateTime %s", _updateTime);
        console2.log("value %s", _value);
    }

    //forge test --match-test test_buy_wolf -vvv
    function test_buy_wolf() public {
        
        vm.startPrank(admin);
        WOLF_TOKEN.mint(address(Alice), 100000);
        vm.stopPrank();

        room.setGenCoordinateMocked(1, 1);

        vm.startPrank(address(Alice));
        WOLF_TOKEN.approve(address(room), 100000);
        room.buy(2, 2);
        vm.stopPrank();

        uint32 wolfNum = room.getOwnerOfSpecieNum(2, address(Alice));
        console.log("wolfNum %d", wolfNum);
        assertEq(wolfNum, 2);

        uint32[] memory wolfs = room.getSpecieIdsAt(2, 1, 1);
        for (uint32 i = 0; i < wolfs.length; i++) {
            console2.log("wolfs[%s] %d", i, wolfs[i]);
        }

        (int16 _x, int16 _y, address _owner, uint32 _id, uint32 _blood, uint32 _bornTime, uint32 _updateTime, uint256 _value) = room.getWolf(2);
        console2.log("x %s", _x);
        console2.log("y %s", _y);
        console2.log("address %s", _owner);
        console2.log("id %s", _id);
        console2.log("blood %s", _blood);
        console2.log("bornTime %s", _bornTime);
        console2.log("updateTime %s", _updateTime);
        console2.log("value %s", _value);
    }

}