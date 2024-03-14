// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract PureLottery {
    error WrongStakeAmount();
    error LotteryActive();
    error CannotResolveLottery();
    error WrongState();
    error ValueAlreadyCommitted();
    error WrongCommitValue();
    error ValueNotCommitted();

    uint256 public constant DURATION = 7 * 24 hours;
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

    event PaymentAccepted(address indexed participant, uint256 amount);
    event ResolutionStarted(uint32 indexed lotteryId, uint256 startBlockNumber);
    event ResolvedLottery(uint32 indexed lotteryId);
    event LotteryStarted(uint32 indexed lotteryId, uint256 startTime);

    constructor() {
        lotteryId = 1;
        startTimes[lotteryId] = block.timestamp;
    }

    function getLotteryId() external view returns (uint32) {
        return lotteryId;
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

    function enterLottery() external payable {
        if (inResolution) {
            revert LotteryNotActive();
        }
        if (participantAddressToId[msg.sender] == 0) {
            ++participantsCount[lotteryId];
            participantAddressToId[msg.sender] = participantsCount[lotteryId];
        }
        participantAmounts[lotteryId][msg.sender] += msg.value;
        emit PaymentAccepted(msg.sender, msg.value);
    }

    function getParticipantsCount() external view returns (uint256) {
        return participantsCount[lotteryId];
    }

    function getParticipantBalance(address participantAddress) external view returns (uint256) {
        return participantAmounts[lotteryId][participantAddress];
    }

    function getPoolBalance() external view returns (uint256) {
        return address(this).balance;
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

    // Revealing and resolving the lottery

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
        for (uint32 i = 0; i < participantsCount[lotteryId]; ++i) {
            if (monteCarloDot <= monteCarloLine) {
//                winnerAmounts[i][msg.sender] = participantAmounts[lotteryId][i];
//                poolBalances[lotteryId] -= participantAmounts[lotteryId][i];
//                participantAmounts[lotteryId][i] = 0;
            }
        }

        emit ResolvedLottery(lotteryId);

        inResolution = false;
        ++lotteryId;
        startTimes[lotteryId] = block.timestamp;
        payable(msg.sender).transfer(REWARD_MULTIPLIER * COMMITTER_STAKE);
        emit LotteryStarted(lotteryId, block.timestamp);
    }

    function withdrawReward() external {}

}
