//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IUtilityContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract ERC1155AirDroper is IUtilityContract, Ownable{

    IERC1155 public token;
    address public treasury;
    bool private initialized;

    error AlreadyInitialized();
    error ArraysLenghtMismatch();
    error NeedToApproveTokens();
    error TransferFailed();

    modifier notinitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    constructor() Ownable(msg.sender) {}

    function airdrop(address[] calldata receivers, uint256[] calldata amounts, uint256[] calldata tokenId) external {
        require(receivers.length == amounts.length && receivers.length == tokenId.length, ArraysLenghtMismatch());
        require(token.isApprovedForAll(treasury, address(this)), NeedToApproveTokens());

        for(uint256 i = 0; i < amounts.length; i++) {
            token.safeTransferFrom(
                treasury, 
                receivers[i], 
                tokenId[i], 
                amounts[i], 
                "");
        }
    }

    function initialize(bytes memory _initData) external notinitialized returns(bool){

        (address _tokenAddress, address _treasury, address _owner) = abi.decode(_initData, (address, address, address));

        token = IERC1155(_tokenAddress);
        treasury = _treasury;

        Ownable.transferOwnership(_owner);

        initialized = true;
        return true;
    }

    function getInitData(address _tokenAddress, address _treasury, address _owner) external pure returns(bytes memory){
        return abi.encode(_tokenAddress, _treasury, _owner);
    } 


  
}