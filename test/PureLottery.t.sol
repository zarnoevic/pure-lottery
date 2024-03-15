// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {PureLottery} from "../src/PureLottery.sol";

contract PureLotteryTest is Test {

    function test_constructorValues() public {
        PureLottery pureLottery = new PureLottery();

        assertEq(pureLottery.lotteryId(), 1);
        assertEq(pureLottery.getStartTime(), block.timestamp);

        assertEq(pureLottery.getParticipantBalance(), 0);
        assertEq(pureLottery.getPoolBalance(), 0);
        assertEq(pureLottery.getParticipantsCount(), 0);
    }

    bytes private WrongLotteryEntry = abi.encodeWithSignature("WrongLotteryEntry()");

    function test_receiveReverts() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectRevert(WrongLotteryEntry);

        (bool success,) = payable(pureLottery).call{value: 1 ether}("");

        assertEq(success, true);
        assertEq(pureLottery.getParticipantBalance(), 0);
        assertEq(pureLottery.getPoolBalance(), 0);
        assertEq(pureLottery.getParticipantsCount(), 0);
    }

    function test_fallbackReverts() public {
        PureLottery pureLottery = new PureLottery();

        vm.expectRevert(WrongLotteryEntry);

        (bool success,) = payable(pureLottery).call{value: 1 ether}("random");

        assertEq(success, true);
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

        address otherAddress = address(0x1111111234567);
        vm.startPrank(otherAddress, otherAddress);
        vm.deal(otherAddress, 1000 ether);

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(otherAddress, 14 ether);
        pureLottery.enterLottery{value: 14 ether}();
        assertEq(pureLottery.getParticipantBalance(), 14 ether);
        assertEq(pureLottery.getParticipantsCount(), 2);
        assertEq(pureLottery.getPoolBalance(), 20 ether);

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(otherAddress, 10 ether);
        pureLottery.enterLottery{value: 10 ether}();
        assertEq(pureLottery.getParticipantBalance(), 24 ether);
        assertEq(pureLottery.getParticipantsCount(), 2);
        assertEq(pureLottery.getPoolBalance(), 30 ether);

        vm.stopPrank();
    }

    bytes private WrongStakeAmount = abi.encodeWithSignature("WrongStakeAmount()");
    bytes private ValueAlreadyCommitted = abi.encodeWithSignature("ValueAlreadyCommitted()");
    bytes private WrongCommitValue = abi.encodeWithSignature("WrongCommitValue()");

    function test_commitValueAndStartResolutionReverts() public {
        PureLottery pureLottery = new PureLottery();

        uint256 preimage = 1234567890;
        uint256 value = uint256(keccak256(abi.encodePacked(preimage)));

        vm.expectRevert(WrongStakeAmount);
        pureLottery.commitValueAndStartResolution{value: 0.11 ether}(value);

        vm.expectRevert(WrongCommitValue);
        pureLottery.commitValueAndStartResolution{value: 0.1 ether}(0);
    }

    bytes private LotteryNotActive = abi.encodeWithSignature("LotteryNotActive()");

    function test_commitValueAndStartResolutionAccepts() public {
        uint startTime = 1640995200;
        vm.warp(startTime);
        PureLottery pureLottery = new PureLottery();

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 5 ether);
        pureLottery.enterLottery{value: 5 ether}();
        assertEq(pureLottery.getParticipantBalance(), 5 ether);
        assertEq(pureLottery.getParticipantsCount(), 1);
        assertEq(pureLottery.getPoolBalance(), 5 ether);

        address otherAddress = address(0x1111111234567);
        vm.startPrank(otherAddress, otherAddress);
        vm.deal(otherAddress, 1000 ether);

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(otherAddress, 10 ether);
        pureLottery.enterLottery{value: 10 ether}();
        assertEq(pureLottery.getParticipantBalance(), 10 ether);
        assertEq(pureLottery.getParticipantsCount(), 2);
        assertEq(pureLottery.getPoolBalance(), 15 ether);

        vm.stopPrank();

        address committerAddress = address(0xaaaaa1);
        vm.startPrank(committerAddress, committerAddress);
        vm.deal(committerAddress, 1 ether);

        vm.warp(startTime + pureLottery.DURATION() + 10);

        uint256 preimage = 1234567890;
        uint256 value = uint256(keccak256(abi.encodePacked(preimage)));

        pureLottery.commitValueAndStartResolution{value: 0.1 ether}(value);

        assertEq(pureLottery.inResolution(), true);
        assertEq(pureLottery.getCommittedValue(), value);
        assertEq(pureLottery.getResolutionBlockNumber(), 2);

        vm.stopPrank();
    }

    function test_revealValueAndResolveLottery() public {
        uint startTime = 1640995200;
        vm.warp(startTime);
        PureLottery pureLottery = new PureLottery();

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(address(this), 5 ether);
        pureLottery.enterLottery{value: 5 ether}();
        assertEq(pureLottery.getParticipantBalance(), 5 ether);
        assertEq(pureLottery.getParticipantsCount(), 1);
        assertEq(pureLottery.getPoolBalance(), 5 ether);

        address otherAddress = address(0x1111111234567);
        vm.startPrank(otherAddress, otherAddress);
        vm.deal(otherAddress, 1000 ether);

        vm.expectEmit(true, true, true, true);
        emit PaymentAccepted(otherAddress, 10 ether);
        pureLottery.enterLottery{value: 10 ether}();
        assertEq(pureLottery.getParticipantBalance(), 10 ether);
        assertEq(pureLottery.getParticipantsCount(), 2);
        assertEq(pureLottery.getPoolBalance(), 15 ether);

        vm.stopPrank();

        address committerAddress = address(0xaaaaa1);
        vm.startPrank(committerAddress, committerAddress);
        vm.deal(committerAddress, 1 ether);

        vm.warp(startTime + pureLottery.DURATION() + 10);

        uint256 preimage = 1234567890;
        uint256 value = uint256(keccak256(abi.encodePacked(preimage)));

        pureLottery.commitValueAndStartResolution{value: 0.1 ether}(value);

        assertEq(pureLottery.inResolution(), true);
        assertEq(pureLottery.getCommittedValue(), value);
        assertEq(pureLottery.getResolutionBlockNumber(), 2);

        vm.roll(pureLottery.COMMITTER_BLOCKS_WINDOW() - 2);

        uint balance = address(committerAddress).balance;
        uint32 lotteryId = pureLottery.lotteryId();

        pureLottery.revealValueAndResolveLottery(preimage);

        assertEq(pureLottery.inResolution(), false);
        assertEq(pureLottery.lotteryId(), lotteryId + 1);
        assertGt(address(committerAddress).balance, balance);

        vm.stopPrank();

    }


}
