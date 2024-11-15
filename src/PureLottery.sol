// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/console.sol";

contract PureLottery {
    error WrongStakeAmount();
    error LotteryActive();
    error CannotResolveLottery();
    error WrongState();
    error ValueAlreadyCommitted();
    error WrongCommitValue();
    error ValueNotCommitted();
    error NoRewardAvailable();

    uint256 public constant DURATION = 24 hours;
    uint256 public constant MIN_TOTAL_POOL = 1 ether;
    uint256 public constant COMMITTER_STAKE = 0.1 ether;
    uint256 public constant COMMITTER_BLOCKS_WINDOW = 10;
    uint256 public constant REWARD_MULTIPLIER = 5;

    uint32 public lotteryId;
    bool public inResolution;

    mapping(uint32 => mapping(address => uint256)) public participantAmounts;
    mapping(address => uint256) public participantAddressToId;
    mapping(uint32 => uint256) public poolBalances;
    mapping(uint32 => uint16) public participantsCount;
    mapping(uint32 => mapping(address => uint256)) public winnerAmounts;
    mapping(uint32 => uint256) public startTimes;
    mapping(uint32 => uint256) public committedValues;
    mapping(uint32 => uint256) public resolutionBlockNumbers;

    event ResolutionStarted(uint32 indexed lotteryId, uint256 startBlockNumber);
    event ResolvedLottery(uint32 indexed lotteryId);
    event LotteryStarted(uint32 indexed lotteryId, uint256 startTime);
    event WinnerSelected(uint32 indexed lotteryId, address winner, uint256 amount);
    event RewardWithdrawn(uint32 indexed lotteryId, address winner, uint256 amount);

    constructor() {
        lotteryId = 1;
        startTimes[lotteryId] = block.timestamp;
    }

    function getStartTime() external view returns (uint256) {
        return startTimes[lotteryId];
    }

    error WrongLotteryEntry();

    receive() external payable {
        revert WrongLotteryEntry();
    }

    fallback() external payable {
        revert WrongLotteryEntry();
    }

    error LotteryNotActive();

    event PaymentAccepted(address indexed participant, uint256 amount);

    function enterLottery() external payable {
        if (inResolution) {
            revert LotteryNotActive();
        }
        console.log("enterLottery", msg.sender, msg.value);

        if (participantAddressToId[msg.sender] == 0) {
            ++participantsCount[lotteryId];
            participantAddressToId[msg.sender] = participantsCount[lotteryId];
        }
        console.log("participantsCount[lotteryId]", participantsCount[lotteryId]);

        participantAmounts[lotteryId][msg.sender] += msg.value;
        poolBalances[lotteryId] += msg.value;
        emit PaymentAccepted(msg.sender, msg.value);
    }

    function getParticipantsCount() external view returns (uint256) {
        return participantsCount[lotteryId];
    }

    function getParticipantBalance() external view returns (uint256) {
        return participantAmounts[lotteryId][msg.sender];
    }

    function getPoolBalance() external view returns (uint256) {
        return poolBalances[lotteryId];
    }

    function commitValueAndStartResolution(uint256 value) external payable {
        if (msg.value != COMMITTER_STAKE) {
            revert WrongStakeAmount();
        } else if (committedValues[lotteryId] != 0) {
            revert ValueAlreadyCommitted();
        } else if (value == 0) {
            revert WrongCommitValue();
        } else if (inResolution) {
            revert LotteryActive();
        } else if (block.timestamp < startTimes[lotteryId] + DURATION) {
            revert WrongState();
        }
        inResolution = true;
        resolutionBlockNumbers[lotteryId] = block.number + 1;
        committedValues[lotteryId] = value;
    }

    function getCommittedValue() external view returns (uint256) {
        return committedValues[lotteryId];
    }

    function getResolutionBlockNumber() external view returns (uint256) {
        return resolutionBlockNumbers[lotteryId];
    }

    function recommitValueAndRestartResolution(uint256 value) external payable {
        if (msg.value != COMMITTER_STAKE) {
            revert WrongStakeAmount();
        } else if (value == 0) {
            revert WrongCommitValue();
        } else if (resolutionBlockNumbers[lotteryId] == 0) {
            revert ValueNotCommitted();
        } else if (!inResolution) {
            revert LotteryActive();
        } else if (
            !(
            block.number > resolutionBlockNumbers[lotteryId] + 256
            || block.number >= resolutionBlockNumbers[lotteryId] + COMMITTER_BLOCKS_WINDOW
        )
        ) {
            revert ValueAlreadyCommitted();
        }
        committedValues[lotteryId] = value;
        resolutionBlockNumbers[lotteryId] = block.number + 1;
    }

    error WaitingForResolutionBlockHash();
    error InvalidPreimageRevealed();

    function revealValueAndResolveLottery(uint256 preimage) external {
        if (!inResolution) {
            revert LotteryNotActive();
        } else if (block.number <= resolutionBlockNumbers[lotteryId]) {
            revert WaitingForResolutionBlockHash();
        } else if (keccak256(abi.encodePacked(preimage)) != bytes32(committedValues[lotteryId])) {
            revert InvalidPreimageRevealed();
        }

        uint256 monteCarloDot = uint256(
            keccak256(abi.encodePacked(preimage, blockhash(resolutionBlockNumbers[lotteryId])))
        ) % poolBalances[lotteryId];
        
        uint256 monteCarloLine = 0;
        address currentParticipant;
        
        // Iterate through participants to find winner
        for (uint16 i = 1; i <= participantsCount[lotteryId]; i++) {
            // Find participant address by id
            for (uint16 j = 1; j <= participantsCount[lotteryId]; j++) {
                if (participantAddressToId[currentParticipant] == i) {
                    monteCarloLine += participantAmounts[lotteryId][currentParticipant];
                    if (monteCarloDot <= monteCarloLine) {
                        // Winner found
                        winnerAmounts[lotteryId][currentParticipant] = poolBalances[lotteryId];
                        emit WinnerSelected(lotteryId, currentParticipant, poolBalances[lotteryId]);
                        break;
                    }
                }
                currentParticipant = address(uint160(uint256(keccak256(abi.encodePacked(j)))));
            }
        }

        emit ResolvedLottery(lotteryId);

        inResolution = false;
        ++lotteryId;
        startTimes[lotteryId] = block.timestamp;
        payable(msg.sender).transfer(REWARD_MULTIPLIER * COMMITTER_STAKE);
        emit LotteryStarted(lotteryId, block.timestamp);
    }

    function withdrawReward() external {
        uint256 reward = winnerAmounts[lotteryId - 1][msg.sender];
        if (reward == 0) {
            revert NoRewardAvailable();
        }
        
        winnerAmounts[lotteryId - 1][msg.sender] = 0;
        payable(msg.sender).transfer(reward);
        emit RewardWithdrawn(lotteryId - 1, msg.sender, reward);
    }
}