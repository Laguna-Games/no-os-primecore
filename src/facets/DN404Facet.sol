// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title DN404
/// @notice DN404 is a hybrid ERC20 and ERC721 implementation that mints
/// and burns NFTs based on an account's ERC20 token balance.
///
/// @author Shiva (shiva.shanmuganathan@laguna.games)
/// @dev Note:
/// - The ERC721 data is stored in this base DN404 contract, however a
///   DN404Mirror contract ***MUST*** be deployed and linked during
///   initialization.
/// - For ERC20 transfers, the most recently acquired NFT will be burned / transferred out first.
/// - A unit worth of ERC20 tokens equates to a deed to one NFT token.
///   The skip NFT status determines if this deed is automatically exercised.
///   An account can configure their skip NFT status.
///     * If `getSkipNFT(owner) == true`, ERC20 mints / transfers to `owner`
///       will NOT trigger NFT mints / transfers to `owner` (i.e. deeds are left unexercised).
///     * If `getSkipNFT(owner) == false`, ERC20 mints / transfers to `owner`
///       will trigger NFT mints / transfers to `owner`, until the NFT balance of `owner`
///       is equal to its ERC20 balance divided by the unit (rounded down).
/// - Invariant: `mirror.balanceOf(owner) <= base.balanceOf(owner) / _unit()`.
/// - The gas costs for automatic minting / transferring / burning of NFTs is O(n).
///   This can exceed the block gas limit.
///   Applications and users may need to break up large transfers into a few transactions.
/// - This implementation does not support "safe" transfers for automatic NFT transfers.
/// - The ERC20 token allowances and ERC721 token / operator approvals are separate.
/// - For MEV safety, users should NOT have concurrently open orders for the ERC20 and ERC721.

import {LibDN404} from '../libraries/LibDN404.sol';
import {LibTokenURI} from '../libraries/LibTokenURI.sol';

contract DN404Facet {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                      ERC20 OPERATIONS                      */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() public view returns (uint256) {
        return uint256(LibDN404._getDN404Storage().totalSupply);
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) public view returns (uint256) {
        return LibDN404._balanceOf(owner);
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) public view returns (uint256) {
        return LibDN404._allowance(owner, spender);
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 amount) public returns (bool) {
        LibDN404._approve(msg.sender, spender, amount);
        return true;
    }

    /// @dev Transfer `amount` tokens from the caller to `to`.
    ///
    /// Will burn sender NFTs if balance after transfer is less than
    /// the amount required to support the current NFT balance.
    ///
    /// Will mint NFTs to `to` if the recipient's new balance supports
    /// additional NFTs ***AND*** the `to` address's skipNFT flag is
    /// set to false.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) public returns (bool) {
        LibDN404._transfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Will burn sender NFTs if balance after transfer is less than
    /// the amount required to support the current NFT balance.
    ///
    /// Will mint NFTs to `to` if the recipient's new balance supports
    /// additional NFTs ***AND*** the `to` address's skipNFT flag is
    /// set to false.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        return LibDN404._transferFrom(from, to, amount);
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                     SKIP NFT FUNCTIONS                     */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns true if minting and transferring ERC20s to `owner` will skip minting NFTs.
    /// Returns false otherwise.
    function getSkipNFT(address owner) public view returns (bool result) {
        return LibDN404.getSkipNFT(owner);
    }

    /// @dev Sets the caller's skipNFT flag to `skipNFT`. Returns true.
    ///
    /// Emits a {SkipNFTSet} event.
    function setSkipNFT(bool skipNFT) public returns (bool) {
        LibDN404._setSkipNFT(msg.sender, skipNFT);
        return true;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                     MIRROR OPERATIONS                      */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns the address of the mirror NFT contract.
    function mirrorERC721() public view returns (address) {
        return LibDN404._getDN404Storage().mirrorERC721;
    }

    function transferFromNFT(address from, address to, uint256 id, address msgSender) public returns (bool) {
        LibDN404.DN404Storage storage $ = LibDN404._getDN404Storage();
        if ($.mirrorERC721 != msg.sender) revert LibDN404.SenderNotMirror();
        LibDN404._transferFromNFT(from, to, id, msgSender);
        return true;
    }

    function setApprovalForAllNFT(address spender, bool status, address msgSender) public returns (bool) {
        LibDN404.DN404Storage storage $ = LibDN404._getDN404Storage();
        if ($.mirrorERC721 != msg.sender) revert LibDN404.SenderNotMirror();
        LibDN404._setApprovalForAll(spender, status, msgSender);
        return true;
    }

    function isApprovedForAllNFT(address owner, address operator) public view returns (bool) {
        return LibDN404._isApprovedForAll(owner, operator);
    }

    function ownerOfNFT(uint256 id) public view returns (address) {
        return LibDN404._ownerOf(id);
    }

    function ownerAtNFT(uint256 id) public view returns (address) {
        return LibDN404._ownerAt(id);
    }

    function approveNFT(address spender, uint256 id, address msgSender) public returns (address owner) {
        LibDN404.DN404Storage storage $ = LibDN404._getDN404Storage();
        if ($.mirrorERC721 != msg.sender) revert LibDN404.SenderNotMirror();
        return LibDN404._approveNFT(spender, id, msgSender);
    }

    function getApprovedNFT(uint256 id) public view returns (address) {
        return LibDN404._getApproved(id);
    }

    function balanceOfNFT(address owner) public view returns (uint256) {
        return LibDN404._balanceOfNFT(owner);
    }

    function totalNFTSupply() public view returns (uint256) {
        return LibDN404._totalNFTSupply();
    }

    function tokenOfNFTOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId) {
        uint256 balance = balanceOfNFT(owner);
        require(index < balance, 'DN404: index out of bounds');
        // Get the owned tokens for this range
        tokenId = LibDN404._ownedIds(owner, index, index + 1)[0];
        require(tokenId != 0, 'DN404: no token at index');
        return tokenId;
    }

    /// @dev Rerolls the NFT with the given tokenId and slippage tolerance.
    /// @param tokenId The ID of the NFT to reroll.
    /// @param slippageBps The slippage tolerance in basis points (e.g., 100 = 1%).
    function reroll(uint256 tokenId, uint16 slippageBps) external payable {
        LibDN404._reroll(tokenId, slippageBps);
    }
}
