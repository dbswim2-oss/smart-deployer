// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";

contract CrowdFunding is Initializable, ReentrancyGuard {
    address public owner; // fundraiser
    uint256 public goal;
    uint64 public vestingDuration; // секунды
    uint256 public totalRaised;
    bool public goalReached;
    VestingWallet public vesting;

    mapping(address => uint256) public contributions;

    event Contributed(address indexed contributor, uint256 amount);
    event Refunded(address indexed contributor, uint256 amount);
    event GoalReached(address indexed vesting, uint256 totalRaised);

    error NotOwner();
    error ZeroAmount();
    error GoalAlreadyReached();
    error GoalNotReached();
    error NothingToRefund();
    error TransferFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(bytes calldata _initData) external initializer returns (bool) {
        (address _owner, uint256 _goal, uint64 _vestingDuration) =
            abi.decode(_initData, (address, uint256, uint64));

        require(_owner != address(0), "owner = 0");
        require(_goal > 0, "goal = 0");
        require(_vestingDuration > 0, "duration = 0");

        owner = _owner;
        goal = _goal;
        vestingDuration = _vestingDuration;

        return true;
    }

    function getInitData(address _fundraiser, uint256 _goal, uint64 _vestingDuration) external pure returns (bytes memory) {
        return abi.encode(_fundraiser, _goal, _vestingDuration);
    }

    function contribute() external payable nonReentrant {
        if (goalReached) revert GoalAlreadyReached();
        if (msg.value == 0) revert ZeroAmount();

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit Contributed(msg.sender, msg.value);

        if (totalRaised >= goal) {
            _startVesting();
        }
    }

    function refund() external nonReentrant {
        if (goalReached) revert GoalAlreadyReached();

        uint256 amount = contributions[msg.sender];
        if (amount == 0) revert NothingToRefund();

        contributions[msg.sender] = 0;
        totalRaised -= amount;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit Refunded(msg.sender, amount);
    }

    function withdraw() external onlyOwner nonReentrant {
        if (!goalReached) revert GoalNotReached();
        vesting.release();
    }

    function _startVesting() internal {
        goalReached = true;

        // Старт вестинга = блок, в котором набрана цель
        vesting = new VestingWallet(
            owner,
            uint64(block.timestamp),
            vestingDuration
        );

        (bool ok, ) = payable(address(vesting)).call{value: address(this).balance}("");
        if (!ok) revert TransferFailed();

        emit GoalReached(address(vesting), totalRaised);
    }
}