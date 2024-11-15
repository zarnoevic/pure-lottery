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

    function test_alternativeResolution() public {
        PureLottery pureLottery = setupLotteryWithInitialCommit();
        
        address alternativeResolver = address(0xbbbbb1);
        vm.startPrank(alternativeResolver);
        vm.deal(alternativeResolver, 1 ether);
        
        uint256 newPreimage = 987654321;
        uint256 newValue = uint256(keccak256(abi.encodePacked(newPreimage)));
        
        // Move past COMMITTER_BLOCKS_WINDOW
        vm.roll(pureLottery.COMMITTER_BLOCKS_WINDOW() + 3);
        
        pureLottery.commitValueAndStartResolution{value: 0.1 ether}(newValue);
        
        assertEq(pureLottery.getCommittedValue(), newValue);
        assertEq(pureLottery.getResolutionBlockNumber(), block.number + 1);
        
        // Test resolution with alternative value
        vm.roll(block.number + 5);
        pureLottery.revealValueAndResolveLottery(newPreimage);
        
        assertEq(pureLottery.inResolution(), false);
        
        vm.stopPrank();
    }

    function test_revealValueAndResolveLotteryReverts() public {
        PureLottery pureLottery = setupLotteryWithInitialCommit();
        
        address committerAddress = address(0xaaaaa1);
        vm.startPrank(committerAddress);
        
        // Try reveal before resolution block
        vm.expectRevert(WaitingForResolutionBlockHash);
        pureLottery.revealValueAndResolveLottery(1234567890);
        
        // Try reveal with wrong preimage
        vm.roll(pureLottery.COMMITTER_BLOCKS_WINDOW() - 2);
        vm.expectRevert(InvalidPreimageRevealed);
        pureLottery.revealValueAndResolveLottery(999999);
        
        vm.stopPrank();
    }

    function test_withdrawReward() public {
        PureLottery pureLottery = setupAndResolveLottery();
        
        address winner = address(0x1111111234567);
        vm.startPrank(winner);
        
        uint256 initialBalance = address(winner).balance;
        pureLottery.withdrawReward();
        
        assertGt(address(winner).balance, initialBalance);
        
        // Try withdraw again
        vm.expectRevert(NoRewardAvailable);
        pureLottery.withdrawReward();
        
        vm.stopPrank();
    }

    function test_fullLotteryLifecycle() public {
        PureLottery pureLottery = new PureLottery();
        uint256 startTime = block.timestamp;

        // Multiple entries
        for(uint i = 1; i <= 5; i++) {
            address player = address(uint160(i));
            vm.deal(player, 10 ether);
            vm.prank(player);
            pureLottery.enterLottery{value: 1 ether}();
        }
        
        assertEq(pureLottery.getParticipantsCount(), 5);
        assertEq(pureLottery.getPoolBalance(), 5 ether);

        // Wait for lottery duration
        vm.warp(startTime + pureLottery.DURATION() + 1);

        // Initial commit
        address resolver = address(0xaaaaa1);
        vm.startPrank(resolver);
        vm.deal(resolver, 1 ether);
        
        uint256 preimage = 1234567890;
        uint256 value = uint256(keccak256(abi.encodePacked(preimage)));
        pureLottery.commitValueAndStartResolution{value: 0.1 ether}(value);

        // Reveal and resolve
        vm.roll(block.number + 5);
        pureLottery.revealValueAndResolveLottery(preimage);
        
        assertEq(pureLottery.lotteryId(), 2);
        assertEq(pureLottery.inResolution(), false);
        
        vm.stopPrank();
    }

    // Helper functions
    function setupLotteryWithInitialCommit() internal returns (PureLottery) {
        uint startTime = 1640995200;
        vm.warp(startTime);
        PureLottery pureLottery = new PureLottery();

        // Add participants
        pureLottery.enterLottery{value: 5 ether}();
        
        address otherAddress = address(0x1111111234567);
        vm.prank(otherAddress);
        vm.deal(otherAddress, 10 ether);
        pureLottery.enterLottery{value: 10 ether}();

        // Initial commit
        vm.warp(startTime + pureLottery.DURATION() + 10);
        address committerAddress = address(0xaaaaa1);
        vm.startPrank(committerAddress);
        vm.deal(committerAddress, 1 ether);

        uint256 preimage = 1234567890;
        uint256 value = uint256(keccak256(abi.encodePacked(preimage)));
        pureLottery.commitValueAndStartResolution{value: 0.1 ether}(value);
        
        vm.stopPrank();
        return pureLottery;
    }

    function setupAndResolveLottery() internal returns (PureLottery) {
        PureLottery pureLottery = setupLotteryWithInitialCommit();
        
        address committerAddress = address(0xaaaaa1);
        vm.startPrank(committerAddress);
        
        vm.roll(pureLottery.COMMITTER_BLOCKS_WINDOW() - 2);
        pureLottery.revealValueAndResolveLottery(1234567890);
        
        vm.stopPrank();
        return pureLottery;
    }


}
