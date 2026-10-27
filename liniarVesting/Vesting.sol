// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract ERC1155AirDroper is Ownable{

    bool private initialized;
    IERC20 public token;
    address public beneficiary;
    uint256 public totalAmount;
    uint256 public startTime;
    uint256 public cliff;
    uint256 public duration;
    uint256 public claimed;
    uint256 public periodLength;
    uint256 public periods;
    uint256 public claimedPeriods;
    uint256 public amountPerBeneficiary;
    bool public vestingStarted;

    address[] public beneficiaries;

    mapping(address => bool) public isBeneficiary;
    mapping(address => uint256) public claimedPeriodsOf;

    error AlreadyInitialized();
    error ClaimerIsNotBeneficiary();
    error CliffNotReached();
    error NothingToClaim();
    error TransferFailed();
    error NotOwner();
    error InvalidSchedule();
    error ZeroAddress();
    error NoPeriodUnlocked();
    error InvalidBeneficiary();
    error VestingAlreadyStarted();
    error VestingNotStarted();
    error InsufficientBalance();
    error WithdrawTransferFailed();
    error NothingToWithdraw();

    event Claim(address beneficiary, uint256 amount, uint256 timestamp);
    event VestingStarted(uint256 timestamp, uint256 funded);
    event TokensWithdrawn(address to, uint256 amount);

    modifier notinitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }
    
    constructor() Ownable(msg.sender) {}

    function initialize(bytes memory _initData) external notinitialized returns(bool){
        require(msg.sender == owner(), NotOwner());

        (
            address _tokenAddress,
            address _owner,
            address[] memory _beneficiaries,
            uint256 _amountPerBeneficiary,
            address _beneficiary,
            uint256 _startTime,
            uint256 _cliff,
            uint256 _periodLength,
            uint256 _periods
        ) = abi.decode(_initData, (address, address, address[], uint256, address, uint256, uint256, uint256, uint256));

        require(_owner != address(0) && _beneficiary != address(0), ZeroAddress());
        require(
            _beneficiaries.length > 0 &&
            _amountPerBeneficiary > 0 &&
            _periods > 0 &&
            _periodLength > 0,
            InvalidSchedule()
        );

        for (uint256 i; i < _beneficiaries.length; ++i) {
            address b = _beneficiaries[i];
            require(b != address(0) && !isBeneficiary[b], InvalidBeneficiary());
            isBeneficiary[b] = true;
            beneficiaries.push(b);
        }

        token = IERC20(_tokenAddress);
        amountPerBeneficiary = _amountPerBeneficiary;
        startTime = _startTime;
        cliff = _cliff;
        periodLength = _periodLength;
        periods = _periods;

        initialized = true;
        _transferOwnership(_owner);
        return true;
    }

    function getInitData(address _tokenAddress, address _owner, address[] calldata _beneficiaries, uint256 _amountPerBeneficiary, uint256 _startTime, uint256 _cliff, uint256 _periodLength, uint256 _periods) external pure returns(bytes memory){
        return abi.encode(_tokenAddress, _owner, _beneficiaries, _amountPerBeneficiary, _startTime, _cliff, _periodLength, _periods);
    } 
    
    function getBeneficiaries() external view returns(address[] memory) {
        return beneficiaries;
    }

    function totalRequired() public view returns(uint256) {
        return amountPerBeneficiary * beneficiaries.length;
    }

    function startVesting() external onlyOwner {
        require(!vestingStarted, VestingAlreadyStarted());

        uint256 balance = token.balanceOf(address(this));
        uint256 need = totalRequired();
        require(balance >= need, InsufficientBalance());

        vestingStarted = true;
        emit VestingStarted(block.timestamp, balance);
    }

    function unlockedPeriods() public view returns(uint256) {
        if (block.timestamp < startTime + cliff) return 0;

        uint256 elapsed = block.timestamp - (startTime + cliff);
        uint256 n = elapsed / periodLength + 1;
        return n > periods ? periods : n;
    }

    function periodAmount(uint256 index) public view returns(uint256) {
        uint256 base = totalAmount / periods;
        return index == periods - 1 ? totalAmount - base * (periods - 1) : base;
    }

    function claimableAmount() public view returns(uint256) {
        if (unlockedPeriods() <= claimedPeriods) return 0;
        return periodAmount(claimedPeriods);
    }

    function claimableFor(address _claimer) public view returns(uint256) {
        if (!vestingStarted) return 0;
        if (!isBeneficiary[_claimer]) return 0;
        if (unlockedPeriods() <= claimedPeriodsOf[_claimer]) return 0;
        return periodAmount(claimedPeriodsOf[_claimer]);
    }

    function claim() public {
        require(vestingStarted, VestingNotStarted());
        require(msg.sender == beneficiary, ClaimerIsNotBeneficiary());
        require(block.timestamp > startTime + cliff, CliffNotReached());

        uint256 claimable = claimableAmount();
        require(claimable > 0, NothingToClaim());

        claimedPeriods += 1;
        claimed += claimable;
        require(token.transfer(beneficiary, claimable), TransferFailed());

        emit Claim(msg.sender, claimable, block.timestamp);
    }

    function vestedAmount() internal view returns(uint256) {
        if (block.timestamp < startTime + cliff) return 0;

        uint256 passedTime = block.timestamp - (startTime + cliff);
        return (totalAmount * passedTime) / duration;
    }

    function withdrawUnallocated(address _to) external onlyOwner {
        uint256 availeble = token.balanceOf(address(this)) - claimed;
        require(availeble > 0, NothingToWithdraw());

        require(token.transfer(msg.sender, availeble), WithdrawTransferFailed());

        emit TokensWithdrawn(_to, availeble);
    }



}