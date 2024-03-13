// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {PureLottery} from "../src/PureLottery.sol";

contract CounterTest is Test {
    PureLottery public pureLottery;

    function setUp() public {
        pureLottery = new PureLottery();
    }

    function test_enterLottery() public {
        pureLottery.enterLottery{value: 1 ether}();
        assertEq(pureLottery.getParticipantBalance(msg.sender), 1 ether);
    }

    function test_receive() public {
        pureLottery.send{value: 1 ether}();
        assertEq(pureLottery.getParticipantBalance(msg.sender), 1 ether);
    }
}
