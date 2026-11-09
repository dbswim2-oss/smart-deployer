//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IUtilityContract.sol";
import "./IDeployManager.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title DeployManager - Factory for utility contracts
/// @author Junior developer
/// @notice Allows users to deploy utility contracts by cloning registered templates.
/// @dev Uses OpenZeppelin's Clones and Ownable; assumes templates implement IUtilityContract.
contract DeployManager is IDeployManager, Ownable, ERC165 {
    constructor() Ownable(msg.sender) {

    }

    struct ContractInfo{
        uint256 fee;
        bool isActive;
        uint256 registeredAt;
    }

    mapping(address => address[]) public deployedContracts;
    mapping(address => ContractInfo) public contractsData;

    /// @inheritdoc IDeployManager
    function deploy(address _utilityContract, bytes calldata _initData) external payable returns(address){
        ContractInfo memory info = contractsData[_utilityContract];

        require(info.isActive, ContractNotActive());
        require(msg.value >= info.fee, NotEnoughFunds());
        require(info.registeredAt > 0, ContractDoesNotRegistered());

        address clone = Clones.clone(_utilityContract);

        require(IUtilityContract(clone).initialize(_initData), InitializationFailed());

        payable(owner()).transfer(msg.value);

        deployedContracts[msg.sender].push(clone);

        emit NewDeployment(clone, msg.sender, info.fee, block.timestamp);

        return clone;

    }

    function addNewContract(address _contractAddress, uint256 _fee, bool _isActive) external onlyOwner{
        contractsData[_contractAddress] = ContractInfo({
            fee: _fee,
            isActive: _isActive,
            registeredAt: block.timestamp
        });

        emit NewContractAdded(_contractAddress, _fee, _isActive, block.timestamp);
    }

    function updateFee(address _contractAddress, uint256 _newFee) external onlyOwner{
        require(contractsData[_contractAddress].registeredAt > 0, ContractDoesNotRegistered());
        uint256 _oldFee = contractsData[_contractAddress].fee;
        contractsData[_contractAddress].fee = _newFee;

        emit ContractFeeUpdated(_contractAddress, _oldFee, _newFee, block.timestamp);
    }

    function deactivateContract(address _address) external onlyOwner{
        require(contractsData[_address].registeredAt > 0, ContractDoesNotRegistered());
        contractsData[_address].isActive = false;

        emit ContractStatusUpdated(_address, false, block.timestamp);
    }

    function activateContract(address _address) external onlyOwner{
         require(contractsData[_address].registeredAt > 0, ContractDoesNotRegistered());
        contractsData[_address].isActive = true;

        emit ContractStatusUpdated(_address, true, block.timestamp);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IDeployManager).interfaceId || super.supportsInterface(interfaceId);
    }

}