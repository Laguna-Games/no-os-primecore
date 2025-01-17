// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title DN404Mirror
/// @notice DN404Mirror provides an interface for interacting with the
/// NFT tokens in a DN404 implementation.
///
/// @author Shiva (shiva.shanmuganathan@laguna.games)
///
/// @dev Note:
/// - The ERC721 data is stored in the base DN404 contract.
import {LibDN404Mirror} from '../libraries/LibDN404Mirror.sol';

contract DN404MirrorFacet {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                     ERC721 OPERATIONS                      */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns the token collection name from the base DN404 contract.
    function name() public view virtual returns (string memory) {
        return LibDN404Mirror._readString(0x06fdde03, 0); // `name()`.
    }

    /// @dev Returns the token collection symbol from the base DN404 contract.
    function symbol() public view virtual returns (string memory) {
        return LibDN404Mirror._readString(0x95d89b41, 0); // `symbol()`.
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id` from
    /// the base DN404 contract.
    function tokenURI(uint256 id) public view virtual returns (string memory) {
        ownerOf(id); // `ownerOf` reverts if the token does not exist.
        // We'll leave if optional for `_tokenURI` to revert for non-existent token
        // on the ERC20 side, since this is only recommended by the ERC721 standard.
        return LibDN404Mirror._readString(0xcb30b460, id); // `tokenURINFT(uint256)`.
    }

    /// @dev Returns the total NFT supply from the base DN404 contract.
    function totalSupply() public view virtual returns (uint256) {
        return LibDN404Mirror._readWord(0xe2c79281, 0, 0); // `totalNFTSupply()`.
    }

    /// @dev Returns the number of NFT tokens owned by `nftOwner` from the base DN404 contract.
    ///
    /// Requirements:
    /// - `nftOwner` must not be the zero address.
    function balanceOf(address nftOwner) public view virtual returns (uint256) {
        return LibDN404Mirror._readWord(0xf5b100ea, uint160(nftOwner), 0); // `balanceOfNFT(address)`.
    }

    /// @dev Returns the owner of token `id` from the base DN404 contract.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    function ownerOf(uint256 id) public view virtual returns (address) {
        return address(uint160(LibDN404Mirror._readWord(0x2d8a746e, id, 0))); // `ownerOfNFT(uint256)`.
    }

    /// @dev Returns the owner of token `id` from the base DN404 contract.
    /// Returns `address(0)` instead of reverting if the token does not exist.
    function ownerAt(uint256 id) public view virtual returns (address) {
        return address(uint160(LibDN404Mirror._readWord(0xc016aa52, id, 0))); // `ownerAtNFT(uint256)`.
    }

    /// @dev Sets `spender` as the approved account to manage token `id` in
    /// the base DN404 contract.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    /// - The caller must be the owner of the token,
    ///   or an approved operator for the token owner.
    ///
    /// Emits an {Approval} event.
    function approve(address spender, uint256 id) public payable virtual {
        LibDN404Mirror.approve(spender, id);
    }

    /// @dev Returns the account approved to manage token `id` from
    /// the base DN404 contract.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    function getApproved(uint256 id) public view virtual returns (address) {
        return address(uint160(LibDN404Mirror._readWord(0x27ef5495, id, 0))); // `getApprovedNFT(uint256)`.
    }

    /// @dev Sets whether `operator` is approved to manage the tokens of the caller in
    /// the base DN404 contract.
    ///
    /// Emits an {ApprovalForAll} event.
    function setApprovalForAll(address operator, bool approved) public virtual {
        LibDN404Mirror.setApprovalForAll(operator, approved);
    }

    /// @dev Returns whether `operator` is approved to manage the tokens of `nftOwner` from
    /// the base DN404 contract.
    function isApprovedForAll(address nftOwner, address operator) public view virtual returns (bool) {
        // `isApprovedForAllNFT(address,address)`.
        return LibDN404Mirror._readWord(0x62fb246d, uint160(nftOwner), uint160(operator)) != 0;
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - The caller must be the owner of the token, or be approved to manage the token.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 id) public payable virtual {
        LibDN404Mirror.transferFrom(from, to, id);
    }

    /// @dev Equivalent to `safeTransferFrom(from, to, id, "")`.
    function safeTransferFrom(address from, address to, uint256 id) public payable virtual {
        transferFrom(from, to, id);
        if (LibDN404Mirror._hasCode(to)) LibDN404Mirror._checkOnERC721Received(from, to, id, '');
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - The caller must be the owner of the token, or be approved to manage the token.
    /// - If `to` refers to a smart contract, it must implement
    ///   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    ///
    /// Emits a {Transfer} event.
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public payable virtual {
        transferFrom(from, to, id);
        if (LibDN404Mirror._hasCode(to)) LibDN404Mirror._checkOnERC721Received(from, to, id, data);
    }

    /// @dev Returns a token ID owned by `owner` at a given `index` of its token list.
    /// @param owner address owning the tokens
    /// @param index uint256 index of the token in owner's list
    /// @return uint256 token ID at given index
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return LibDN404Mirror._readWord(0xa463e58c, uint160(owner), index); // `tokenOfNFTOwnerByIndex(address,uint256)`
    }

    /// @notice Retrieves tokens owned by the specified user in batches.
    /// @param user The address of the user whose tokens are to be retrieved.
    /// @param start The starting index of the batch.
    /// @param end The ending index of the batch (exclusive).
    /// @return An array of token IDs owned by the user within the specified range.
    function getUserTokensBatch(address user, uint256 start, uint256 end) external view returns (uint256[] memory) {
        return LibDN404Mirror._readArray(0xaf7442b4, uint160(user), start, end); // `getUserNFTsBatch(address,uint256,uint256)`
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                  OWNER SYNCING OPERATIONS                  */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Permissionless function to pull the owner from the base DN404 contract
    /// if it implements ownable, for marketplace signaling purposes.
    function pullOwner() public virtual returns (bool) {
        return LibDN404Mirror.pullOwner();
    }

    /// @dev Returns the address of the base DN404 contract.
    function baseERC20() public view virtual returns (address base) {
        return LibDN404Mirror.baseERC20();
    }

    /// @notice Logs a transfer of NFTs.
    function logTransfer(uint256[] calldata ids) public returns (bool) {
        return LibDN404Mirror.logTransfer(ids);
    }

    /// @notice Logs a direct transfer of NFTs from `from` to `to`.
    function logDirectTransfer(address from, address to, uint256[] calldata ids) public returns (bool) {
        return LibDN404Mirror.logDirectTransfer(from, to, ids);
    }

    /// @notice Links a mirror contract to the base DN404 contract.
    function linkMirrorContract(address base) public returns (bool) {
        return LibDN404Mirror.linkMirrorContract(base);
    }
}
