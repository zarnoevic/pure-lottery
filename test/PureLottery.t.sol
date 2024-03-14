// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {PureLottery} from "../src/PureLottery.sol";
import "forge-std/Vm.sol";
//import {DSTest} from "forge-std/test.sol";

contract PureLotteryTest is Test {
//    Vm public vm = Vm(HEVM_ADDRESS);

    function test_constructorValues() public {
        PureLottery pureLottery = new PureLottery();

        assertEq(pureLottery.getLotteryId(), 1);
        assertEq(pureLottery.getStartTime(), block.timestamp);

        assertEq(pureLottery.getParticipantBalance(), 0);
        assertEq(pureLottery.getPoolBalance(), 0);
        assertEq(pureLottery.getParticipantsCount(), 0);
    }

    bytes private WrongLotteryEntry = abi.encodeWithSignature("WrongLotteryEntry()");

    function test_receiveReverts() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectRevert(WrongLotteryEntry);

        payable(pureLottery).call{value: 1 ether}("");

        assertEq(pureLottery.getParticipantBalance(), 0);
        assertEq(pureLottery.getPoolBalance(), 0);
        assertEq(pureLottery.getParticipantsCount(), 0);
    }

    function test_fallbackReverts() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectRevert(WrongLotteryEntry);

        payable(pureLottery).call{value: 1 ether}("random");

        assertEq(pureLottery.getParticipantBalance(), 0);
        assertEq(pureLottery.getPoolBalance(), 0);
        assertEq(pureLottery.getParticipantsCount(), 0);
    }

    event PaymentAccepted(address indexed participant, uint256 amount);

    function test_enterLotteryOnce() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 1 ether);
        pureLottery.enterLottery{value: 1 ether}();
        assertEq(pureLottery.getParticipantBalance(), 1 ether);
        assertEq(pureLottery.getParticipantsCount(), 1);

        assertEq(pureLottery.getPoolBalance(), 1 ether);
    }

    function test_enterLotteryTwoTimes() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 1 ether);
        pureLottery.enterLottery{value: 1 ether}();
        assertEq(pureLottery.getParticipantBalance(), 1 ether);
        assertEq(pureLottery.getParticipantsCount(), 1);

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 2 ether);
        pureLottery.enterLottery{value: 2 ether}();
        assertEq(pureLottery.getParticipantBalance(), 3 ether);
        assertEq(pureLottery.getParticipantsCount(), 1);

        assertEq(pureLottery.getPoolBalance(), 3 ether);
    }

    function test_enterLotteryMultipleAddresses() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 1 ether);
        pureLottery.enterLottery{value: 1 ether}();
        assertEq(pureLottery.getParticipantBalance(), 1 ether);
        assertEq(pureLottery.getParticipantsCount(), 1);
        assertEq(pureLottery.getPoolBalance(), 1 ether);

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 5 ether);
        pureLottery.enterLottery{value: 5 ether}();
        assertEq(pureLottery.getParticipantBalance(), 6 ether);
        assertEq(pureLottery.getParticipantsCount(), 1);
        assertEq(pureLottery.getPoolBalance(), 6 ether);

        vm.prank(0x12345);

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 14 ether);
        pureLottery.enterLottery{value: 14 ether}();
        assertEq(pureLottery.getParticipantBalance(), 14 ether);
        assertEq(pureLottery.getParticipantsCount(), 2);
        assertEq(pureLottery.getPoolBalance(), 20 ether);

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 10 ether);
        pureLottery.enterLottery{value: 10 ether}();
        assertEq(pureLottery.getParticipantBalance(), 10 ether);
        assertEq(pureLottery.getParticipantsCount(), 2);
        assertEq(pureLottery.getPoolBalance(), 30 ether);
    }

}
