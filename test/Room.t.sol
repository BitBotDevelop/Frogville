// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseTest.sol";
import "../contracts/interfaces/IERC20.sol";
import "../contracts/Room.sol";

contract RootTest is BaseTest {
    address public Alice = address(100);
    address public Bob = address(101);

    uint32 public initBlockTime = 1682553600;

    function setUp() public {
        vm.label(address(Alice), "Alice");
        vm.label(address(Bob), "Bob");

        vm.warp(initBlockTime);
        deployCoins();
        deployRoom();

        vm.startPrank(admin);
        WOLF_TOKEN.mint(address(Alice), 100000);
        WOLF_TOKEN.mint(address(Bob), 100000);
        vm.stopPrank();
    }

    //forge test --match-test test_buy_grass -vvv
    function test_buy_grass() public {
        room.setGenCoordinateMocked(2, 2);

        vm.roll(1);
        vm.startPrank(address(Alice));
        WOLF_TOKEN.approve(address(room), 100000);
        room.buy(0, 5);
        vm.stopPrank();

        uint32 grassNum = room.getOwnerOfSpecieNum(0, address(Alice));
        console.log("grassNum %d", grassNum);
        assertEq(grassNum, 5);
        
        uint32[] memory grasses = room.getSpecieIdsAt(0, 2, 2);
        assertEq(grasses[0], 1);
        assertEq(grasses[4], 5);
        // for (uint32 i = 0; i < grasses.length; i++) {
        //     console2.log("grasses[%s] %d", i, grasses[i]);
        // }

        (int16 _x, int16 _y, address _owner, uint32 _id, uint32 _bornTime, uint32 _updateTime, uint256 _height ,uint256 _value) = room.getGrass(2);
        console2.log("x %s", _x);
        console2.log("y %s", _y);
        console2.log("address %s", _owner);
        console2.log("id %s", _id);
        console2.log("bornTime %s", _bornTime);
        console2.log("updateTime %s", _updateTime);
        console2.log("_height %s", _height);
        console2.log("value %s", _value);
    }

    //forge test --match-test test_buy_sheep -vvv
    function test_buy_sheep() public {
        room.setGenCoordinateMocked(1, 1);

        vm.startPrank(address(Alice));
        WOLF_TOKEN.approve(address(room), 100000);
        room.buy(1, 5);
        vm.stopPrank();

        uint32 sheepNum = room.getOwnerOfSpecieNum(1, address(Alice));
        console.log("sheepNum %d", sheepNum);
        assertEq(sheepNum, 5);

        uint32[] memory sheeps = room.getSpecieIdsAt(1, 1, 1);
        assertEq(sheeps[0], 1);
        assertEq(sheeps[4], 5);
    }

    //forge test --match-test test_buy_wolf -vvv
    function test_buy_wolf() public {
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

        (int16 _x, int16 _y, address _owner, uint32 _id, uint32 _blood, uint32 _bornTime, uint32 _updateTime, uint256 _height ,uint256 _value) = room.getWolf(2);
        console2.log("x %s", _x);
        console2.log("y %s", _y);
        console2.log("address %s", _owner);
        console2.log("id %s", _id);
        console2.log("blood %s", _blood);
        console2.log("bornTime %s", _bornTime);
        console2.log("updateTime %s", _updateTime);
        console2.log("height %s", _height);
        console2.log("value %s", _value);
    }

    //forge test --match-test test_buy_and_sell_grass -vvv
    function test_buy_and_sell_grass() public {
        test_buy_grass();

        console2.log(" =========== sell =========");
        vm.warp(initBlockTime + 10 minutes);

        uint32[] memory ids = new uint32[](1);
        ids[0] = 2;

        vm.startPrank(address(Alice));
        room.sell(0, ids, address(Alice));
        vm.stopPrank();

        uint32 grassNum = room.getOwnerOfSpecieNum(0, address(Alice));
        // console.log("grassNum %d", grassNum);
        assertEq(grassNum, 4);

        uint32 grassNumAtMap = room.getSpecieNumAt(0, 2, 2);
        // console.log("grassNumAtMap %d", grassNumAtMap);
        assertEq(grassNumAtMap, 4);

        uint32[] memory grasses = room.getSpecieIdsAt(0, 2, 2);
        assertEq(grasses[0], 1);
        assertEq(grasses[1], 5);
        assertEq(grasses[2], 3);
        assertEq(grasses[3], 4);
        // for (uint32 i = 0; i < grassNumAtMap; i++) {
        //     console2.log("grasses[%s] %d", i, grasses[i]);
        // }

        // (int16 _x, int16 _y, address _owner, uint32 _id, uint32 _bornTime, uint32 _updateTime, uint256 _value) = room.getGrass(5);
        // console2.log("x %s", _x);
        // console2.log("y %s", _y);
        // console2.log("address %s", _owner);
        // console2.log("id %s", _id);
        // console2.log("bornTime %s", _bornTime);
        // console2.log("updateTime %s", _updateTime);
        // console2.log("value %s", _value);
    }

    //forge test --match-test test_buy_and_sell_sheep -vvv
    function test_buy_and_sell_sheep() public {
        test_buy_sheep();

        console2.log(" =========== sell =========");
        vm.roll(2);
        vm.warp(initBlockTime + 10 minutes);

        uint32[] memory ids = new uint32[](1);
        ids[0] = 3;

        vm.startPrank(address(Alice));
        room.sell(1, ids, address(Alice));
        vm.stopPrank();

        uint32 sheepNum = room.getOwnerOfSpecieNum(1, address(Alice));
        console.log("sheepNum %d", sheepNum);
        assertEq(sheepNum, 4);

        uint32 sheepNumAtMap = room.getSpecieNumAt(1, 1, 1);
        assertEq(sheepNumAtMap, 0);

        sheepNumAtMap = room.getSpecieNumAt(1, 2, 2);
        assertEq(sheepNumAtMap, 4);

        uint32[] memory sheepIds = room.getSpecieIdsAt(1, 2, 2);
        assertEq(sheepIds[0], 1);
        assertEq(sheepIds[1], 2);
        assertEq(sheepIds[2], 5);
        assertEq(sheepIds[3], 4);
    }

    //forge test --match-test test_eat_grass -vvv
    function test_eat_grass() public {
        test_buy_grass();// (2,2)

        // console2.log(" =========== Bob buy sheep =========");
        vm.roll(2);
        vm.warp(initBlockTime + 10 minutes);
        
        room.setGenCoordinateMocked(1, 1);

        // buy sheep
        vm.startPrank(address(Bob));
        WOLF_TOKEN.approve(address(room), 100000);
        room.buy(1, 5);
        vm.stopPrank();

        console2.log(" =========== Bob sell sheep =========");
        vm.roll(3);
        vm.warp(initBlockTime + 20 minutes);


        uint32[] memory ids = new uint32[](1);
        ids[0] = 3;
        vm.startPrank(address(Bob));
        WOLF_TOKEN.approve(address(room), 100000);
        room.sell(1, ids, address(Bob));
        vm.stopPrank();
    }
}
