// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title DN404MirrorFragment
/// @notice DN404MirrorFragment implementation defining all required functions for NFT interactions
contract DN404MirrorFragment {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                           EVENTS                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Emitted when token `id` is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /// @dev Emitted when `owner` enables `account` to manage the `id` token.
    event Approval(address indexed owner, address indexed account, uint256 indexed id);

    /// @dev Emitted when `owner` enables or disables `operator` to manage all of their tokens.
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This is for marketplace signaling purposes. This contract has a `pullOwner()`
    /// function that will sync the owner from the base contract.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    // uint256 private constant _TRANSFER_EVENT_SIGNATURE =
    //     0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    // uint256 private constant _APPROVAL_EVENT_SIGNATURE =
    //     0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    // /// @dev `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    // uint256 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
    //     0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                        CUSTOM ERRORS                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Thrown when a call for an NFT function did not originate
    /// from the base DN404 contract.
    error SenderNotBase();

    /// @dev Thrown when a call for an NFT function did not originate from the deployer.
    error SenderNotDeployer();

    /// @dev Thrown when transferring an NFT to a contract address that
    /// does not implement ERC721Receiver.
    error TransferToNonERC721ReceiverImplementer();

    /// @dev Thrown when a linkMirrorContract call is received and the
    /// NFT mirror contract has already been linked to a DN404 base contract.
    error AlreadyLinked();

    /// @dev Thrown when retrieving the base DN404 address when a link has not
    /// been established.
    error NotLinked();

    /// @dev The function selector is not recognized.
    error FnSelectorNotRecognized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC721 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function name() external view returns (string memory) {}

    function symbol() external view returns (string memory) {}

    function tokenURI(uint256 id) external view returns (string memory) {}

    function totalSupply() external view returns (uint256) {}

    function balanceOf(address nftOwner) external view returns (uint256) {}

    function ownerOf(uint256 id) external view returns (address) {}

    function ownerAt(uint256 id) external view returns (address) {}

    function approve(address spender, uint256 id) external payable {}

    function getApproved(uint256 id) external view returns (address) {}

    function setApprovalForAll(address operator, bool approved) external {}

    function isApprovedForAll(address nftOwner, address operator) external view returns (bool) {}

    function transferFrom(address from, address to, uint256 id) external payable {}

    function safeTransferFrom(address from, address to, uint256 id) external payable {}

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external payable {}

    // function supportsInterface(bytes4 interfaceId) external view returns (bool result) {}    //  shadowed by SupportsInterfaceFragment

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {}

    function getUserTokensBatch(address user, uint256 start, uint256 end) external view returns (uint256[] memory) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  OWNER SYNCING OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // function owner() external view returns (address) {}  // shadowed by DiamondOwnerFacetFragment

    function pullOwner() external returns (bool) {}

    function baseERC20() external view returns (address base) {}

    function logTransfer(uint256[] calldata ids) external returns (bool) {}

    function logDirectTransfer(address from, address to, uint256[] calldata ids) external returns (bool) {}

    function linkMirrorContract(address base) external returns (bool) {}
}
