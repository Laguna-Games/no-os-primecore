// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibContractOwner} from '../../lib/laguna-diamond-foundry/src/libraries/LibContractOwner.sol';
import {LibDN404} from '../libraries/LibDN404.sol';

contract DN404AdminFacet {
    function initializeDN404(
        string memory name_,
        string memory symbol_,
        uint96 initialTokenSupply,
        address initialSupplyOwner,
        address mirror
    ) public {
        LibContractOwner.enforceIsContractOwner();

        LibDN404._getDN404Storage().name = name_;
        LibDN404._getDN404Storage().symbol = symbol_;

        LibDN404._initializeDN404(initialTokenSupply, initialSupplyOwner, mirror);
    }

    function setPresaleContract(address presaleContract) public {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setPresaleContract(presaleContract);
    }

    function getPresaleContract() public view returns (address) {
        return LibDN404._getPresaleContract();
    }

    function setUniswapRouter(address router) public {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setUniswapRouter(router);
    }

    function getUniswapRouter() public view returns (address) {
        return LibDN404._getUniswapRouter();
    }

    function addToWhitelist(address account) public {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._addToWhitelist(account);
    }

    function removeFromWhitelist(address account) public {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._removeFromWhitelist(account);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return LibDN404._isWhitelisted(account);
    }

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return LibDN404._getWhitelistedAddresses();
    }

    /// @notice Sets the minimum amount of tokens that need to be transferred from LP to trigger a reroll
    /// @param threshold The new threshold amount in wei (18 decimals)
    function setRerollThreshold(uint256 threshold) external {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setRerollThreshold(threshold);
    }

    /// @notice Gets the current threshold amount for triggering rerolls
    /// @return The current threshold amount in wei (18 decimals)
    function getRerollThreshold() external view returns (uint256) {
        return LibDN404._getRerollThreshold();
    }

    function setTreasuryAddress(address treasury) external {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setTreasuryAddress(treasury);
    }

    function getTreasuryAddress() external view returns (address) {
        return LibDN404._getTreasuryAddress();
    }

    function setTreasuryFeePercentage(uint256 treasuryFeePercentage) external {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setTreasuryFeePercentage(treasuryFeePercentage);
    }

    function getTreasuryFeePercentage() external view returns (uint256) {
        return LibDN404._getTreasuryFeePercentage();
    }

    function mint(address to, uint256 amount) public {
        require(
            msg.sender == LibContractOwner.contractOwner() || msg.sender == LibDN404._getPresaleContract(),
            'Only DN404 contract owner or presale contract can mint'
        );
        LibDN404._mint(to, amount);
    }

    /// @notice Retrieves NFTs owned by the specified user in batches.
    /// @param user The address of the user whose NFTs are to be retrieved.
    /// @param start The starting index of the batch.
    /// @param end The ending index of the batch (exclusive).
    /// @return An array of NFT IDs owned by the user within the specified range.
    function getUserNFTsBatch(address user, uint256 start, uint256 end) external view returns (uint256[] memory) {
        return LibDN404.getUserNFTsBatch(user, start, end);
    }

    function getPrimecoreData(
        uint256 tokenId
    )
        public
        view
        returns (
            uint8 rarityTier,
            uint16 luck,
            uint8 prodType,
            uint8 elementSlot1,
            uint8 elementSlot2,
            uint8 elementSlot3
        )
    {
        return LibDN404.getPrimecoreData(tokenId);
    }

    function implementsDN404() public pure returns (bool) {
        return true;
    }

    function setPoolFeeTier(uint24 feeTier) external {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setPoolFeeTier(feeTier);
    }

    function getPoolFeeTier() external view returns (uint24) {
        return LibDN404._getPoolFeeTier();
    }

    function setPoolAddress(address poolAddress) external {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setPoolAddress(poolAddress);
    }

    function getPoolAddress() external view returns (address) {
        return LibDN404._getPoolAddress();
    }
}
