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
    event LotteryStarted(uint32 indexed lotteryId);

    constructor() {
        startTimes[0] = block.timestamp;
    }

    receive() external payable {
        require(!inResolution, LotteryNotActive());
        if (participantAddressToId[msg.sender] == 0) {
            participantAddressToId[msg.sender] = participantsCount[lotteryId];
            ++participantsCount[lotteryId];
        }
        participantAmounts[msg.sender] += msg.value;
        emit PaymentAccepted(msg.sender, msg.value);
    }

    function getParticipantBalance(address calldata participant) public view returns (uint256){
        return participantAmounts[lotteryId][participant];
    }

    function getPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function commitValueAndStartResolution(uint256 calldata value) public {
        require(message.value == COMMITTER_STAKE, WrongStakeAmount());
        require(committedValues[lotteryId] == 0, ValueAlreadyCommitted());
        require(value != 0, WrongCommitValue());
        require(!inResolution, LotteryActive());
        require(
            block.timestamp >= startTimes[lotteryId] + DURATION,
            WrongState()
        );
        inResolution = true;
        resolutionBlockNumbers[lotteryId] = block.number + 1;
        committedValues[lotteryId] = value;
    }

    function recommitValueAndRestartResolution(uint256 calldata value) public {
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

        uint256 monteCarloDot = uint256(keccak256(abi.encodePacked(preimage, blockhash(resolutionBlockNumbers[lotteryId])))) % poolBalance;

        mapping(address => uint256) memory participantAmounts = participantAmounts[lotteryId];

        uint256 monteCarloLine = 0;
        for (uint32 i = 0; i < participantAmounts.length; ++i) {
            if (monteCarloDot <= monteCarloLine) {
                winnerAmounts[i][msg.sender] = participantAmounts[i];
                poolBalance -= participantAmounts[i];
                participantAmounts[i] = 0;
            }
        }


        emit ResolvedLottery(lotteryId);

        inResolution = false;
        ++lotteryId;
        startTimes[lotteryId] = block.timestamp;
        payable(msg.sender).transfer(REWARD_MULTIPLIER * COMMITTER_STAKE);
        emit LotteryStarted(block.timestamp);
    }

    function rewardCaller() private {
        // Send a multiple of the transaction gas cost to the lottery resolution caller
        // as a reward for calling a function of common interest
        payable(msg.sender).transfer(REWARD_MULTIPLIER * tx.gasprice * tx.gaslimit);
    }

}
