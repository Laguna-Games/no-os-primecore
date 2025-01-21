// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DN404AdminFragment {
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
        string memory baseURI_,
        uint96 initialTokenSupply,
        address initialSupplyOwner,
        address mirror
    ) public {}

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    PRESALE MANAGEMENT                     */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Sets the presale contract.
    /// @param presaleContract The address of the presale contract.
    function setPresaleContract(address presaleContract) public {}

    /// @notice Returns the presale contract.
    /// @return The address of the presale contract.
    function getPresaleContract() public view returns (address) {}

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    UNISWAP CONFIGURATION                  */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Sets the Uniswap router.
    /// @param router The address of the Uniswap router.
    function setUniswapRouter(address router) public {}

    /// @notice Returns the Uniswap router.
    /// @return The address of the Uniswap router.
    function getUniswapRouter() public view returns (address) {}

    function setPoolFeeTier(uint24 feeTier) external {}

    function getPoolFeeTier() external view returns (uint24) {}

    function setPoolAddress(address poolAddress) external {}

    function getPoolAddress() external view returns (address) {}

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    WHITELIST MANAGEMENT                   */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Adds an address to the whitelist.
    /// @param account The address to add to the whitelist.
    function addToWhitelist(address account) public {}

    /// @notice Removes an address from the whitelist.
    /// @param account The address to remove from the whitelist.
    function removeFromWhitelist(address account) public {}

    /// @notice Returns whether an address is whitelisted.
    /// @param account The address to check.
    /// @return Whether the address is whitelisted.
    function isWhitelisted(address account) public view returns (bool) {}

    /// @notice Returns the list of whitelisted addresses.
    /// @return The list of whitelisted addresses.
    function getWhitelistedAddresses() public view returns (address[] memory) {}

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    REROLL FUNCTIONS                        */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Sets the minimum amount of tokens that need to be transferred from LP to trigger a reroll
    /// @param threshold The new threshold amount in wei (18 decimals)
    function setRerollThreshold(uint256 threshold) external {}

    /// @notice Gets the current threshold amount for triggering rerolls
    /// @return The current threshold amount in wei (18 decimals)
    function getRerollThreshold() external view returns (uint256) {}

    /// @notice Gets the cost of a reroll
    /// @return pcAmount The amount of PC tokens required for the reroll
    /// @return ethAmount The amount of ETH required for the reroll
    function getRerollCost() external view returns (uint256 pcAmount, uint256 ethAmount) {}

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    TREASURY MANAGEMENT                    */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Sets the treasury address.
    /// @param treasury The address of the treasury.
    function setTreasuryAddress(address treasury) external {}

    /// @notice Returns the treasury address.
    /// @return The address of the treasury.
    function getTreasuryAddress() external view returns (address) {}

    /// @notice Sets the treasury fee percentage.
    /// @param treasuryFeePercentage The new treasury fee percentage.
    function setTreasuryFeePercentage(uint256 treasuryFeePercentage) external {}

    /// @notice Returns the treasury fee percentage.
    /// @return The treasury fee percentage.
    function getTreasuryFeePercentage() external view returns (uint256) {}

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    TOKEN OPERATIONS                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Mints tokens to an address.
    /// @param to The address to mint the tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public {}

    /// @notice Retrieves NFTs owned by the specified user in batches.
    /// @param user The address of the user whose NFTs are to be retrieved.
    /// @param start The starting index of the batch.
    /// @param end The ending index of the batch (exclusive).
    /// @return An array of NFT IDs owned by the user within the specified range.
    function getUserNFTsBatch(address user, uint256 start, uint256 end) external view returns (uint256[] memory) {}

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
    {}

    /// @notice Returns whether the contract implements the DN404 interface.
    /// @return Whether the contract implements the DN404 interface.
    function implementsDN404() public pure returns (bool) {}

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                    URI FUNCTIONS                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    function setBaseURI(string memory baseURI) public {}

    function setContractURI(string memory contractURI) public {}

    function setTokenURI(string memory tokenURI) public {}
}
