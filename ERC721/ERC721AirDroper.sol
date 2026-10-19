//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IUtilityContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract ERC721AirDroper is IUtilityContract, Ownable{

    IERC721 public token;
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

    function airdrop(address[] calldata receivers, uint256[] calldata tokenId) external {
        require(receivers.length == tokenId.length, ArraysLenghtMismatch());
        require(token.isApprovedForAll(treasury, address(this)), NeedToApproveTokens());

        for(uint256 i = 0; i < tokenId.length; i++) {
            token.safeTransferFrom(
                treasury, 
                receivers[i], 
                tokenId[i]);
        }
    }

    function initialize(bytes memory _initData) external notinitialized returns(bool){

        (address _tokenAddress, address _treasury, address _owner) = abi.decode(_initData, (address, address, address));

        token = IERC721(_tokenAddress);
        treasury = _treasury;

        Ownable.transferOwnership(_owner);

        initialized = true;
        return true;
    }

    function getInitData(address _tokenAddress, address _treasury, address _owner) external pure returns(bytes memory){
        return abi.encode(_tokenAddress, _treasury, _owner);
    } 


  
}