// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title DN404MetadataFragment
/// @notice DN404Metadata implementation defining all required functions
contract DN404MetadataFragment {
    /// @dev Returns the name of the token.
    function name() public view returns (string memory) {}

    /// @dev Returns the symbol of the token.
    function symbol() public view returns (string memory) {}

    /// @dev Returns the decimals places of the token. Defaults to 18.
    function decimals() public pure returns (uint8) {}

    /// @notice Returns the tokenURI of the token.
    /// @param id The ID of the token.
    /// @return The tokenURI of the token.
    /// @dev Note:
    /// - The tokenURI is generated using the token ID.
    /// - This function is invoked by `tokenURI` in the Mirror contract.
    function tokenURINFT(uint256 id) public view returns (string memory) {}

    /// @notice Returns the baseURI of the token.
    /// @return The baseURI of the token.
    function baseURI() public view returns (string memory) {}

    /// @notice Returns the imageURI of the token.
    function getImageURI(uint256 tokenId) public view returns (string memory) {}

    /// @dev Returns the contract-level metadata URI as per ERC-7572.
    function contractURI() public view returns (string memory) {}

    /// @dev Returns the ERC20 token metadata URI as per ERC-1047.
    function tokenURI() public view returns (string memory) {}
}
