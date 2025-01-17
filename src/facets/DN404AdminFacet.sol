// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title DN404AdminFacet
/// @notice Provides admin functions for the DN404 contract.
/// @author Shiva (shiva.shanmuganathan@laguna.games)
/// @dev Note:
/// - The DN404 contract must be initialized before any admin functions are called.

import {LibContractOwner} from '../../lib/laguna-diamond-foundry/src/libraries/LibContractOwner.sol';
import {LibDN404} from '../libraries/LibDN404.sol';

contract DN404AdminFacet {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    INITIALIZATION                         */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Initializes the DN404 contract.
    /// @param name_ The name of the NFT collection.
    /// @param symbol_ The symbol of the NFT collection.
    /// @param initialTokenSupply The initial supply of NFTs.
    /// @param initialSupplyOwner The address of the initial supply owner.
    /// @param mirror The address of the DN404Mirror contract.
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

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    PRESALE MANAGEMENT                     */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Sets the presale contract.
    /// @param presaleContract The address of the presale contract.
    function setPresaleContract(address presaleContract) public {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setPresaleContract(presaleContract);
    }

    /// @notice Returns the presale contract.
    /// @return The address of the presale contract.
    function getPresaleContract() public view returns (address) {
        return LibDN404._getPresaleContract();
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    UNISWAP CONFIGURATION                  */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Sets the Uniswap router.
    /// @param router The address of the Uniswap router.
    function setUniswapRouter(address router) public {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setUniswapRouter(router);
    }

    /// @notice Returns the Uniswap router.
    /// @return The address of the Uniswap router.
    function getUniswapRouter() public view returns (address) {
        return LibDN404._getUniswapRouter();
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

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    WHITELIST MANAGEMENT                   */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Adds an address to the whitelist.
    /// @param account The address to add to the whitelist.
    function addToWhitelist(address account) public {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._addToWhitelist(account);
    }

    /// @notice Removes an address from the whitelist.
    /// @param account The address to remove from the whitelist.
    function removeFromWhitelist(address account) public {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._removeFromWhitelist(account);
    }

    /// @notice Returns whether an address is whitelisted.
    /// @param account The address to check.
    /// @return Whether the address is whitelisted.
    function isWhitelisted(address account) public view returns (bool) {
        return LibDN404._isWhitelisted(account);
    }

    /// @notice Returns the list of whitelisted addresses.
    /// @return The list of whitelisted addresses.
    function getWhitelistedAddresses() public view returns (address[] memory) {
        return LibDN404._getWhitelistedAddresses();
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    REROLL CONFIGURATION                   */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

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

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    TREASURY MANAGEMENT                    */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Sets the treasury address.
    /// @param treasury The address of the treasury.
    function setTreasuryAddress(address treasury) external {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setTreasuryAddress(treasury);
    }

    /// @notice Returns the treasury address.
    /// @return The address of the treasury.
    function getTreasuryAddress() external view returns (address) {
        return LibDN404._getTreasuryAddress();
    }

    /// @notice Sets the treasury fee percentage.
    /// @param treasuryFeePercentage The new treasury fee percentage.
    function setTreasuryFeePercentage(uint256 treasuryFeePercentage) external {
        LibContractOwner.enforceIsContractOwner();
        LibDN404._setTreasuryFeePercentage(treasuryFeePercentage);
    }

    /// @notice Returns the treasury fee percentage.
    /// @return The treasury fee percentage.
    function getTreasuryFeePercentage() external view returns (uint256) {
        return LibDN404._getTreasuryFeePercentage();
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    TOKEN OPERATIONS                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Mints tokens to an address.
    /// @param to The address to mint the tokens to.
    /// @param amount The amount of tokens to mint.
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

    /// @notice Retrieves the primecore data for a given NFT.
    /// @param tokenId The ID of the NFT.
    /// @return rarityTier The rarity tier of the NFT.
    /// @return luck The luck value of the NFT.
    /// @return prodType The production type of the NFT.
    /// @return elementSlot1 The first element slot of the NFT.
    /// @return elementSlot2 The second element slot of the NFT.
    /// @return elementSlot3 The third element slot of the NFT.
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

    /// @notice Returns whether the contract implements the DN404 interface.
    /// @return Whether the contract implements the DN404 interface.
    function implementsDN404() public pure returns (bool) {
        return true;
    }
}
