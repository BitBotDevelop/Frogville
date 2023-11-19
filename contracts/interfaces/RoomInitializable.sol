// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface RoomInitializable {
    function initialize(uint32[12] calldata params1, uint256[3] calldata params2, address[2] calldata param3) external;
}
