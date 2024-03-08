// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

    error WrongStakeAmount();
    error LotteryNotActive();
    error LotteryActive();
    error CannotResolveLottery();
    error WrongState();
    error ValueAlreadyCommitted();
    error WrongCommitValue();
    error ValueNotCommitted();

contract TrustlessLottery {
    uint256 public constant DURATION = 7 * 24 hours;
    uint256 public constant MIN_TOTAL_POOL = 1 ether;
    uint256 public constant COMMITTER_STAKE = 0.1 ether;
    uint256 public constant COMMITTER_BLOCKS_WINDOW = 10;
    uint256 public constant REWARD_MULTIPLIER = 5;

    uint256 public lotteryId;
    bool public inResolution;

    mapping(uint32 => mapping(address => uint256)) public participantAmounts;
    mapping(uint32 => mapping(address => uint256)) public winnerAmounts;
    mapping(uint32 => uint256) public startTimes;
    mapping(uint32 => uint256) public committedValues;
    mapping(uint32 => uint256) public resolutionBlockNumbers;


    event PaymentAccepted(address indexed participant, uint256 amount);
    event ResolutionStarted(uint32 indexed lotteryId, uint256 startBlockNumber);
    event Resolved(uint32 indexed lotteryId);

    constructor() {
        startTimes[0] = block.timestamp;
    }

    receive() external payable {
        require(!inResolution, LotteryNotActive());
        participantAmounts[msg.sender] += msg.value;
        emit PaymentAccepted(msg.sender, msg.value);
    }

    function getParticipantBalance(address calldata participant) public view returns (uint256){
        return participantAmounts[participant];
    }

    function getPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function commitValue(uint256 calldata value) public {
        require(message.value == COMMITTER_STAKE, WrongStakeAmount());
        require(committedValues[lotteryId] == 0, ValueAlreadyCommitted());
        require(value != 0, WrongCommitValue());
        committedValues[lotteryId] = value;
    }

    function startLotteryResolution() public {
        require(
            !inResolution
            && block.timestamp >= startTimes[lotteryId] + DURATION
            && committedValues[lotteryId] != 0,
            WrongState()
        );
        inResolution = true;
        resolutionBlockNumbers[lotteryId] = block.number + 1;
        rewardCaller();
    }

    function recommitValue(uint256 calldata value) public {
        require(message.value == COMMITTER_STAKE, WrongStakeAmount());
        require(value != 0, WrongCommitValue());
        require(resolutionBlockNumbers[lotteryId] != 0, ValueNotCommitted());
        require(
            block.number > resolutionStartBlockNumber + 256
            || block.number >= resolutionBlockNumbers[lotteryId] + COMMITTER_BLOCKS_WINDOW,
            ValueAlreadyCommitted()
        );
        committedValues[lotteryId] = value;
        resolutionBlockNumbers[lotteryId] = block.number + 1;
    }

    function revealValueAndResolveLottery(uint256 calldata preimage) public {
        require(
            inResolution
            && block.number > resolutionBlockNumbers[lotteryId]
            && keccak256(abi.encodePacked(preimage)) == committedValues[lotteryId],
            CannotResolveLottery()
        );

        inResolution = false;
        startTime = block.timestamp;
        ++lotteryId;
        rewardCaller();
        emit LotteryStarted(startBlockNumber);
    }

    function rewardCaller() private {
        // Send a multiple of the transaction gas cost to the lottery resolution caller
        // as a reward for calling a function of common interest
        payable(msg.sender).transfer(REWARD_MULTIPLIER * tx.gasprice * tx.gaslimit);
    }

}
