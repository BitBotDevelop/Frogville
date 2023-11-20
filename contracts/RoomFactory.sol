// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";

//1. room factory  @john
//2. tokenomics / emissions @john
//3. game @webber

contract RoomFactory {
    error ERC1167FailedCreateClone();
    error InitErr();

    address public roomImpl;
    address[] public roomList;

    function createRoom(bytes calldata data_) external returns (address newRoom) {
        newRoom = clone(roomImpl);
        roomList.push(newRoom);
        (bool success,) = newRoom.call(data_);
        if (!success) revert InitErr();
    }

    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }
}
