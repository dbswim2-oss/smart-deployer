// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title IUtilityContract - Interface of a utility contract template
/// @notice Implemented by templates that the DeployManager clones
interface IUtilityContract {
    // ------------------------------------------------------------------------
    // Errors
    // ------------------------------------------------------------------------

    /// @dev Reverts if the deploy manager is not set or is invalid
    error DeployManagerCannotBeZero();
    error NotDeployManager();
    error FailedToDeployManager();
    error AlreadyInitialized();

    // ------------------------------------------------------------------------
    // Functions
    // ------------------------------------------------------------------------

    /// @notice Initializes the clone with the provided data
    /// @param _initData The initialization data for the clone
    /// @return True if the initialization was successful
    /// @dev Called by DeployManager right after cloning
    function initialize(bytes memory _initData) external returns (bool);
    
}