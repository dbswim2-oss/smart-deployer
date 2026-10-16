//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUtilityContract.sol";

contract ERC20Airdroper is IUtilityContract{

    IERC20 public token;
    uint256 public amount;
    bool private initialized;

    error AlreadyInitialized();
    error ArraysLenghtMismatch();
    error NotEnougAllowance();
    error TransferFailed();

    modifier notinitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    constructor(address _tokenAddress, uint256 _airdropAmount) {
        amount = _airdropAmount;
        token = IERC20(_tokenAddress);
    }

    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external {
        require(receivers.length == amounts.length, ArraysLenghtMismatch());

        uint256 total;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }

        require(token.allowance(msg.sender, address(this)) >= total, NotEnougAllowance());

        for(uint256 i = 0; i < receivers.length; i++) {
            require(token.transferFrom(msg.sender, receivers[i], amounts[i]), TransferFailed());
        }
    }

    function initialize(bytes memory _initData) external notinitialized returns(bool){

        address _tokenAddress = abi.decode(_initData, (address));

        token = IERC20(_tokenAddress);
        initialized = true;
        return true;
    }

    function getInitData(address _tokenAddress) external pure returns(bytes memory){
        return abi.encode(_tokenAddress);
    } 


  
}