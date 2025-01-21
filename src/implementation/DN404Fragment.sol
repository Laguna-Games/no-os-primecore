// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title DN404Fragment
/// @notice DN404 implementation defining all required functions
contract DN404Fragment {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                           EVENTS                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev Emitted when `owner` sets their skipNFT flag to `status`.
    event SkipNFTSet(address indexed owner, bool status);

    /// @dev Emitted when treasury fee is paid
    event TreasuryFeePaid(address indexed treasuryAddress, uint256 amount);

    /// @dev Emitted when excess ETH is refunded to the owner
    event ExcessETHRefunded(address indexed owner, uint256 amount);

    // /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    // uint256 private constant _TRANSFER_EVENT_SIGNATURE =
    //     0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    // uint256 private constant _APPROVAL_EVENT_SIGNATURE =
    //     0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    // /// @dev `keccak256(bytes("SkipNFTSet(address,bool)"))`.
    // uint256 private constant _SKIP_NFT_SET_EVENT_SIGNATURE =
    //     0xb5a1de456fff688115a4f75380060c23c8532d14ff85f687cc871456d6420393;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                        CUSTOM ERRORS                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Thrown when attempting to double-initialize the contract.
    error DNAlreadyInitialized();

    /// @dev The function can only be called after the contract has been initialized.
    error DNNotInitialized();

    /// @dev Thrown when attempting to transfer or burn more tokens than sender's balance.
    error InsufficientBalance();

    /// @dev Thrown when a spender attempts to transfer tokens with an insufficient allowance.
    error InsufficientAllowance();

    /// @dev Thrown when minting an amount of tokens that would overflow the max tokens.
    error TotalSupplyOverflow();

    /// @dev The unit must be greater than zero and less than `2**96`.
    error InvalidUnit();

    /// @dev Thrown when the caller for a fallback NFT function is not the mirror contract.
    error SenderNotMirror();

    /// @dev Thrown when attempting to transfer tokens to the zero address.
    error TransferToZeroAddress();

    /// @dev Thrown when the mirror address provided for initialization is the zero address.
    error MirrorAddressIsZero();

    /// @dev Thrown when the link call to the mirror contract reverts.
    error LinkMirrorContractFailed();

    /// @dev Thrown when setting an NFT token approval
    /// and the caller is not the owner or an approved operator.
    error ApprovalCallerNotOwnerNorApproved();

    /// @dev Thrown when transferring an NFT
    /// and the caller is not the owner or an approved operator.
    error TransferCallerNotOwnerNorApproved();

    /// @dev Thrown when transferring an NFT and the from address is not the current owner.
    error TransferFromIncorrectOwner();

    /// @dev Thrown when checking the owner or approved address for a non-existent NFT.
    error TokenDoesNotExist();

    /// @dev The function selector is not recognized.
    error FnSelectorNotRecognized();

    /// @dev Thrown when minting more tokens than the maximum supply.
    error MaxSupplyExceeded();

    /// @dev Custom error for insufficient ETH
    error InsufficientETH();

    /// @dev Custom error for insufficient output amount
    error InsufficientOutputAmount();

    /// @dev Custom error for not being the token owner
    error NotTokenOwner();

    /// @dev Custom error for not being an EOA
    error NotEOA();

    /// @dev Custom error for swap failure
    error SwapFailed();

    /// @dev Custom error for invalid treasury address
    error InvalidTreasuryAddress();

    /// @dev Custom error for invalid fee percentage
    error InvalidFeePercentage();

    /// @dev Custom error for pool not found
    error PoolNotFound();

    /// @dev Custom error for invalid slippage
    error InvalidSlippage();

    /// @dev Custom error for slippage exceeding available ETH
    error SlippageExceedsAvailableETH();

    /// @dev Thrown when attempting to re-enter the `_reroll` function
    error ReentrancyGuard();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function totalSupply() external view returns (uint256) {}

    function balanceOf(address owner) external view returns (uint256) {}

    function allowance(address owner, address spender) external view returns (uint256) {}

    function approve(address spender, uint256 amount) external returns (bool) {}

    function transfer(address to, uint256 amount) external returns (bool) {}

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     SKIP NFT FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function getSkipNFT(address owner) external view returns (bool result) {}

    function setSkipNFT(bool skipNFT) external returns (bool) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     MIRROR OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function mirrorERC721() external view returns (address) {}

    function transferFromNFT(address from, address to, uint256 id, address msgSender) external returns (bool) {}

    function setApprovalForAllNFT(address spender, bool status, address msgSender) external returns (bool) {}

    function isApprovedForAllNFT(address owner, address operator) external view returns (bool) {}

    function ownerOfNFT(uint256 id) external view returns (address) {}

    function ownerAtNFT(uint256 id) external view returns (address) {}

    function approveNFT(address spender, uint256 id, address msgSender) external returns (address owner) {}

    function getApprovedNFT(uint256 id) external view returns (address) {}

    function balanceOfNFT(address owner) external view returns (uint256) {}

    function totalNFTSupply() external view returns (uint256) {}

    function implementsDN404() external pure returns (bool) {}

    function setPresaleContract(address presaleContract) external {}

    function getPresaleContract() external view returns (address) {}

    function tokenOfNFTOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId) {}

    function getUserNFTsBatch(address user, uint256 start, uint256 end) external view returns (uint256[] memory) {}
}
