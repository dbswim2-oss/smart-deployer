// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./IUtilityContract.sol";

/// @title ERC1155AirDroper - Clonable utility contract that airdrops ERC-1155 tokens from a treasury
/// @notice Sends ERC-1155 tokens held by a treasury to a list of receivers
/// @dev Deployed once as a template and cloned by DeployManager. Each clone is configured by initialize().
///      The treasury must call setApprovalForAll(clone, true) for the clone's address before airdrop() works.
contract ERC1155AirDroper is IUtilityContract, Ownable {

    /// @dev Reverts when the receivers, amounts and tokenIds arrays have different lengths
    error ArraysLengthMismatch();

    /// @dev Reverts when the treasury has not approved this contract as an operator
    error NeedToApproveTokens();

    /// @dev Reverts when a zero address is passed where a real address is required
    error ZeroAddress();

    /// @notice ERC-1155 token contract that is airdropped
    IERC1155 public token;

    /// @notice Address that holds the tokens and sends them to receivers
    address public treasury;

    // Set to true in initialize(). The template sets it in its constructor so it cannot be initialized.
    bool private initialized;

    /// @notice Creates the template and locks it so that initialize() cannot be called on it
    /// @dev Clones do not run the constructor, and their storage starts empty, so initialized is false on every clone
    constructor() Ownable(msg.sender) {
        initialized = true;
    }

    /// @dev Reverts with AlreadyInitialized if initialize() has already run
    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    /// @notice Sends amounts[i] of token tokenIds[i] from the treasury to receivers[i] for every index i
    /// @dev Restricted to the owner. The three arrays must have the same length. Reverts with
    ///      NeedToApproveTokens if the treasury has not approved this contract as an operator.
    ///      If any single transfer fails, the whole call reverts.
    /// @param receivers Addresses that receive the tokens
    /// @param amounts Amount of each token to send to the matching receiver
    /// @param tokenIds ERC-1155 token id to send to the matching receiver
    function airdrop(address[] calldata receivers, uint256[] calldata amounts, uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        uint256 length = receivers.length;

        require(length == amounts.length && length == tokenIds.length, ArraysLengthMismatch());
        require(token.isApprovedForAll(treasury, address(this)), NeedToApproveTokens());

        for (uint256 i; i < length; ++i) {
            token.safeTransferFrom(treasury, receivers[i], tokenIds[i], amounts[i], "");
        }
    }

    /// @inheritdoc IUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address tokenAddress, address treasuryAddress, address newOwner) =
            abi.decode(_initData, (address, address, address));

        require(
            tokenAddress != address(0) && treasuryAddress != address(0) && newOwner != address(0),
            ZeroAddress()
        );

        token = IERC1155(tokenAddress);
        treasury = treasuryAddress;
        initialized = true;

        // Internal function: the public transferOwnership() would fail here,
        // because the clone's owner is still address(0) and the caller is not the owner
        _transferOwnership(newOwner);

        return true;
    }

    /// @notice Encodes the arguments that initialize() expects
    /// @dev Helper for building _initData off-chain or in tests. It does not read contract state.
    /// @param _tokenAddress ERC-1155 token contract address
    /// @param _treasury Address that holds the tokens
    /// @param _owner Address that will own the clone
    /// @return ABI-encoded initialization data
    function getInitData(address _tokenAddress, address _treasury, address _owner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_tokenAddress, _treasury, _owner);
    }
}