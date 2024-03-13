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
        // Attempt to send 1 ether to the pureLottery contract
        (bool success, ) = payable(pureLottery).call{value: 1 ether}("");

        // Check if the call was unsuccessful, which means the receive function reverted
        require(!success, "receive() should revert");

        // Assuming getParticipantBalance is a function that returns the balance of a participant
        // Verify that the sender's balance in the lottery contract is still 0
        assertEq(pureLottery.getParticipantBalance(msg.sender), 0);
    }


}
