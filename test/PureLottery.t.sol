// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {PureLottery} from "../src/PureLottery.sol";

contract PureLotteryTest is Test {

    function test_constructor() public {
        PureLottery pureLottery = new PureLottery();
        assertEq(pureLottery.getLotteryId(), 1);
        assertEq(pureLottery.getStartTime(), block.timestamp);
    }

    bytes private WrongLotteryEntry = abi.encodeWithSignature("WrongLotteryEntry()");

    function test_receiveReverts() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectRevert(WrongLotteryEntry);

        payable(pureLottery).call{value: 1 ether}("");

        assertEq(pureLottery.getParticipantBalance(msg.sender), 0);
    }

    function test_fallbackReverts() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectRevert(WrongLotteryEntry);

        address(pureLottery).call{value: 1 ether}("sdasdasd");

        assertEq(pureLottery.getParticipantBalance(msg.sender), 0);
    }

    function test_enterLottery() public {
        PureLottery pureLottery = new PureLottery();
        pureLottery.enterLottery{value: 1 ether}();
        assertEq(pureLottery.getParticipantBalance(msg.sender), 1 ether);
    }

}
