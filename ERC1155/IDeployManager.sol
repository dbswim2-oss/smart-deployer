// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title IDeployManager - Factory for utility contract clones
/// @notice Defines the errors, events and functions of the DeployManager factory
interface IDeployManager is IERC165{

    // ------------------------------------------------------------------------
    // Errors
    // ------------------------------------------------------------------------

    /// @dev Reverts if the contract is not active
    error ContractNotActive();

    /// @dev Reverts if msg.value is less than the template fee
    error NotEnoughFunds();

    /// @dev Reverts if the template is not registered
    error ContractDoesNotRegistered();

    /// @dev Reverts if the clone's initialize() returns false
    error InitializationFailed();

    /// @dev Reverts if the transfer of funds to the owner fails
    error TransferFailed();

    /// @dev Reverts if the contract is not a utility contract
    error ContractIsNotUtilityContract();

    /// @dev Reverts if the contract already registered 
    error AlreadyRegistered();

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------

    /// @notice Emitted when a new utility contract template is registered.
    /// @param _contractAddress Address of the registered utility contract template.
    /// @param _fee Fee (in wei) required to deploy a clone of this contract.
    /// @param _isActive Whether the contract is active and deployable.
    /// @param _timestamp Timestamp when the contract was added.
    event NewContractAdded(address indexed _contractAddress, uint256 _fee, bool _isActive, uint256 _timestamp);
    event ContractFeeUpdated(address indexed _contractAddress, uint256 _oldFee, uint256 _newFee, uint256 _timestamp);
    event ContractStatusUpdated(address indexed _contractAddress, bool _isActive, uint256 _timestamp);
    event NewDeployment(address indexed _deployer, address indexed _contractAddress, uint256 _fee, uint256 _timestamp);

    // ------------------------------------------------------------------------
    // Functions
    // ------------------------------------------------------------------------

    /// @notice Deploys a new clone of a registered utility contract template
    /// @param _utilityContract The address of the utility contract template
    /// @param _initData The initialization data for the clone
    /// @return The address of the deployed clone
    /// @dev Emits NewDeployment event
    function deploy(address _utilityContract, bytes calldata _initData) external payable returns (address);

    /// @notice Registers a new utility contract template
    function addNewContract(address _contractAddress, uint256 _fee, bool _isActive) external;

    /// @notice Updates the deployment fee of a registered template
    function updateFee(address _contractAddress, uint256 _newFee) external;

    /// @notice Deactivates a registered template
    function deactivateContract(address _contractAddress) external;

    /// @notice Activates a registered template
    function activateContract(address _contractAddress) external;
}