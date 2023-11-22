// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";

contract EnergyPool {

    address public room;
    address public team;
    address public promotion;
    address public treasury;
    address public USDT;

    uint256 public totalEnergy;
    uint256 public teamEnergy;
    uint256 public treasuryEnergy;

    mapping(address => uint256) balanceOf;

    function produce(uint256 num, address to) external {
        require(msg.sender == room, "");

        if (to == address(0)) {
            uint256 _teamEnergy = num * 200 / 1000;
            uint256 _treasuryEnergy = _teamEnergy;
            uint256 _poolEnergy = num - _teamEnergy - _treasuryEnergy;

            teamEnergy += _teamEnergy;
            treasuryEnergy += _treasuryEnergy;
            totalEnergy += _poolEnergy;
        } else {
            treasuryEnergy += num;
        }
    }

    function consume(uint256 num) external {
        require(msg.sender == room, "");
        require(totalEnergy >= num, "");

        totalEnergy -= num;
    }

    function setRoom(address _room) external {
        room = _room;
    }

    function withdrawTeamEnergy(uint256 amount) external {
        require(amount <= teamEnergy, "");
        uint256 balance = IERC20(USDT).balanceOf(treasury);
        require(balance >= amount, "");
        IERC20(USDT).transferFrom(treasury, team, amount);
        teamEnergy -= amount;
    }
}
